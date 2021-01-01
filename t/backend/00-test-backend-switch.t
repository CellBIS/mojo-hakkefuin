BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;

use Test::More;
use Mojo::Hakkefuin::Test::Backend;
use Mojo::Home;

my ($btest, $db, $backend);

my $home = Mojo::Home->new();
my $path = $home->child(qw(t backend migrations));

$btest = Mojo::Hakkefuin::Test::Backend->new(via => 'sqlite', dir => $path);
unless (-d $btest->dir) { mkdir $btest->dir }

$backend = $btest->backend;
$db      = $backend->sqlite->db;

ok $db->ping, 'SQLite connected';

SKIP: {
  skip 'set TEST_ONLINE_mariadb to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb};

  $btest->via('mariadb');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'MariaDB connected';
}

SKIP: {
  skip 'set TEST_ONLINE_mariadb to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb};

  $btest->via('mysql');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Use the keyword "mysql" to connect to MariaDB';
}

SKIP: {
  skip 'set TEST_ONLINE_pg to enable this test', 1 unless $ENV{TEST_ONLINE_pg};

  $btest->via('pg');
  $btest->dsn($ENV{TEST_ONLINE_pg});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->pg->db;

  ok $db->ping, 'PostgreSQL connected';
}

SKIP: {
  skip 'set TEST_ONLINE_mariadb and TEST_ONLINE_pg to enable this test', 1
    unless $ENV{TEST_ONLINE_mariadb} && $ENV{TEST_ONLINE_pg};

  note 'Test multiple switch backend';

  $btest->via('sqlite');
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->sqlite->db;

  ok $db->ping, 'SQLite connected';

  $btest->via('mariadb');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Switch to MariaDB';

  $btest->via('mysql');
  $btest->dsn($ENV{TEST_ONLINE_mariadb});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->mariadb->db;

  ok $db->ping, 'Switch to MariaDB by "mysql" keyword';

  $btest->via('pg');
  $btest->dsn($ENV{TEST_ONLINE_pg});
  $btest->load_backend;

  $backend = $btest->backend;
  $db      = $backend->pg->db;

  ok $db->ping, 'Switch to PostgreSQL';
}

# Clean
$path->remove_tree;

done_testing();
