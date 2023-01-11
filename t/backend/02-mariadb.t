use Mojo::Base -strict;

use Test::More;
use Mojo::Hakkefuin::Test::Backend;

plan skip_all => 'set TEST_ONLINE_mariadb to enable this test'
  unless $ENV{TEST_ONLINE_mariadb};

my $dsn = $ENV{TEST_ONLINE_mariadb};
my ($btest,        $db,          $backend,   $id);
my ($data,         $data_create, $data_read, $data_update);
my ($data_cookies, $data_csrf);
my ($result,       $r_create, $r_update, $r_delete);

$btest = Mojo::Hakkefuin::Test::Backend->new(dsn => $dsn);
$btest->via('mariadb');
$btest->load_backend;

$backend = $btest->backend;
$db      = $backend->mariadb->db;
$data    = 'data test';

note 'connection test';
ok $db->ping, 'connected';

note 'testing for table';
is $backend->check_table->{result}, undef, 'no table';
is $backend->create_table->{code},  200,   'create table';
is $backend->empty_table->{code},   200,   'empty table';
is $backend->drop_table->{code},    200,   'drop table';

note 'error condition when create data';
$data_create = $btest->example_data($data);
$result      = {result => 0, code => 500, data => $data_create->[1]};
is_deeply $backend->create($data, $data_create->[1], $data_create->[2]),
  $result, "can't create data";

note 'create data';
$backend->create_table;
$r_create = $backend->create($data, $data_create->[1], $data_create->[2]);
$result   = {result => 1, code => 200, data => $data_create->[1]};
is_deeply $r_create, $result, 'create data';

note 'read data';
is $backend->read($data, $data_create->[1])->{code}, 200, 'can read data';
is $backend->read($data, $data_create->[1])->{data}->{$backend->cookie},
  $data_create->[1], 'cookie';
is $backend->read($data, $data_create->[1])->{data}->{$backend->csrf},
  $data_create->[2], 'csrf';

note 'update data';
$data_read   = $backend->read($data, $data_create->[1])->{data};
$id          = $data_read->{$backend->id};
$data_update = $btest->example_data($data);
$r_update    = $backend->update($id, $data_update->[1], $data_update->[2]);
$result      = {
  result => 1,
  code   => 200,
  cookie => $data_update->[1],
  csrf   => $data_update->[2]
};
is_deeply $r_update, $result, 'success update data';
$data_read = $backend->read($data, $data_update->[1])->{data};
is $r_update->{cookie}, $data_read->{$backend->cookie},
  'cookie has been updated';
is $r_update->{csrf}, $data_read->{$backend->csrf}, 'csrf has been updated';

note 'update data cookie';
$data_read    = $backend->read($data, $data_update->[1])->{data};
$data_update  = $btest->example_data($data);
$data_cookies = $data_update->[1];
$r_update = $backend->update_cookie($data_read->{$backend->id}, $data_cookies);
$result   = {result => 1, code => 200, data => $data_cookies};
is_deeply $r_update, $result, 'update cookie success';

note 'update data csrf';
$data_read   = $backend->read($data, $data_update->[1])->{data};
$data_update = $btest->example_data($data);
$data_csrf   = $data_update->[2];
$r_update    = $backend->update_csrf($data_read->{$backend->id}, $data_csrf);
$result      = {result => 1, code => 200, data => $data_csrf};
is_deeply $r_update, $result, 'update csrf success';

note 'delete data';
$data_read = $backend->read($data, $data_cookies)->{data};
$r_delete  = $backend->delete($data, $data_cookies);
$result    = {result => 1, code => 200, data => $data_read->{$backend->cookie}};
is_deeply $r_delete, $result, 'try to delete data';
is $backend->read($data, $data_update->[1])->{data}, undef,
  'data has been deleted';

$backend->drop_table if $backend->check_table->{result};

done_testing();
