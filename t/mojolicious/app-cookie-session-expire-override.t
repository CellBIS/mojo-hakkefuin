use Mojo::Base -strict;

BEGIN {
  $ENV{PLACK_ENV}    = undef;
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Test::Mojo;
use Mojo::Date;
use Mojo::File 'curfile';
use Mojo::SQLite;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use lib curfile->sibling('lib')->to_string;

# Prefer unix socket to avoid network restrictions
my $sock = curfile->dirname->child('tmp', 'mojo-sqlite-expire.sock');
$sock->dirname->make_path;
my $check = IO::Socket::UNIX->new(
  Type   => SOCK_STREAM(),
  Local  => $sock->to_string,
  Listen => 1
);
plan skip_all => 'listen not permitted in this environment' unless $check;
$check->close;
unlink $sock->to_string if -S $sock->to_string;

local $ENV{MOJO_LISTEN} = 'http+unix:' . $sock->to_string
  unless $ENV{MOJO_LISTEN};

my $t;
eval { $t = Test::Mojo->new('HakkefuinTestSQLite'); 1 }
  or plan skip_all => "listen not permitted: $@";
$t->ua->max_redirects(1);

my $migrations = $t->app->home->child('migrations', 'full-sqlite');

my $auth_ttl    = '2h';
my $session_ttl = '30m';
$t->post_ok(
  '/login-custom' => form => {
    user   => 'yusrideb',
    pass   => 's3cr3t1',
    c_time => $auth_ttl,
    s_time => $session_ttl,
  }
  )
  ->status_is(200)
  ->content_is('login success', 'login success with controller override');

my $now              = time;
my @cookies          = @{$t->tx->res->cookies};
my ($auth_cookie)    = grep { $_->name eq 'clg' } @cookies;
my ($session_cookie) = grep { $_->name eq '_mhf' } @cookies;

ok($auth_cookie,    'auth cookie issued');
ok($session_cookie, 'session cookie issued');

if ($auth_cookie) {
  cmp_ok($auth_cookie->max_age, '>=', 7180,
    'auth cookie max-age respects override (lower)');
  cmp_ok($auth_cookie->max_age, '<=', 7220,
    'auth cookie max-age respects override (upper)');
}

if ($session_cookie) {
  cmp_ok($session_cookie->max_age, '>=', 1780,
    'session cookie max-age respects override (lower)');
  cmp_ok($session_cookie->max_age, '<=', 1820,
    'session cookie max-age respects override (upper)');
}

my $sqlite_path = $migrations->child('mhf_sqlite.db');
if (-f $sqlite_path) {
  my $sqlite = Mojo::SQLite->new('sqlite:' . $sqlite_path);
  my $row    = $sqlite->db->query(
    'select expire_date from mojo_hakkefuin where identify=? order by id_auth desc limit 1',
    'yusrideb'
  )->hash;
  ok($row, 'backend row exists for login');
  if ($row && $row->{expire_date}) {
    my $delta    = Mojo::Date->new($row->{expire_date})->epoch - $now;
    my $expected = 2 * 60 * 60;                                          # 2h
    cmp_ok(
      $delta, '>=',
      $expected - 120,
      'backend expire_date respects override (lower)'
    );
    cmp_ok(
      $delta, '<=',
      $expected + 120,
      'backend expire_date respects override (upper)'
    );
  }
}
else {
  fail('sqlite db created');
}

done_testing();

# Clear
$t->app->mhf_backend->drop_table;
$migrations->remove_tree if -d $migrations;
unlink $sock->to_string  if -S $sock->to_string;
