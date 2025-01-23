package Mojo::Hakkefuin::Backend::pg;
use Mojo::Base 'Mojo::Hakkefuin::Backend';

use Mojo::Loader 'load_class';
use CellBIS::SQL::Abstract;

has 'pg';
has 'file_migration';
has abstract => sub { CellBIS::SQL::Abstract->new };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->file_migration($self->dir . '/mhf_pg.sql');
  my $class = 'Mojo::Pg';
  load_class $class;
  $self->pg($class->new($self->dsn()));

  return $self;
}

sub check_table {
  my $self = shift;

  my $result = {result => 0, code => 400};
  my $q      = $self->abstract->select(
    'information_schema.tables',
    ['table_name'],
    {
      where =>
        'table_type=\'BASE TABLE\' AND table_schema=\'public\' AND table_name=\''
        . $self->table_name . '\''
    }
  );
  if (my $dbh = $self->pg->db->query($q)) {
    $result->{result} = $dbh->hash;
    $result->{code}   = 200;
  }

  return $result;
}

sub create_table {
  my $self        = shift;
  my $table_query = $self->table_query;

  my $result = {result => 0, code => 400};

  if (my $dbh = $self->pg->db->query($table_query)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub table_query {
  my $self = shift;

  $self->abstract->new(db_type => 'pg')->create_table(
    $self->table_name,
    [
      $self->id,          $self->identify,    $self->cookie,
      $self->csrf,        $self->create_date, $self->expire_date,
      $self->cookie_lock, $self->lock
    ],
    {
      $self->id          => {type => {name => 'bigserial'}, is_primarykey => 1},
      $self->identify    => {type => {name => 'text'}},
      $self->cookie      => {type => {name => 'text'}},
      $self->csrf        => {type => {name => 'text'}},
      $self->create_date => {type => {name => 'TIMESTAMP'}},
      $self->expire_date => {type => {name => 'TIMESTAMP'}},
      $self->cookie_lock =>
        {type => {name => 'text'}, 'default' => '\'no_lock\'', is_null => 1},
      $self->lock => {type => {name => 'int'}}
    }
  );
}

sub create {
  my ($self, $identify, $cookie, $csrf, $expires) = @_;

  return {result => 0, code => 500, data => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $cookie};

  my $mhf_utils   = $self->mhf_util->new;
  my $now_time    = $mhf_utils->sql_datetime(0);
  my $expire_time = $mhf_utils->sql_datetime($expires);

  my @q = (
    $self->table_name,
    {
      $self->identify    => $identify,
      $self->cookie      => $cookie,
      $self->csrf        => $csrf,
      $self->create_date => $now_time,
      $self->expire_date => $expire_time,
      $self->cookie_lock => 'no_lock',
      $self->lock        => 0
    }
  );
  if (my $dbh = $self->pg->db->insert(@q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub read {
  my ($self, $identify, $cookie) = @_;

  $identify //= 'null';
  $cookie   //= 'null';

  return {result => 0, code => 500, data => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $cookie};
  my @q      = (
    $self->table_name, '*',
    {$self->identify => $identify, $self->cookie => $cookie}
  );
  if (my $dbh = $self->pg->db->select(@q)) {
    $result->{result} = 1;
    $result->{code}   = 200;
    $result->{data}   = $dbh->hash;
  }
  return $result;
}

sub update {
  my ($self, $id, $cookie, $csrf) = @_;

  my $mhf_utils = $self->mhf_util->new;
  my $now_time  = $mhf_utils->sql_datetime(0);

  return {result => 0, code => 500, csrf => $csrf, cookie => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, csrf => $csrf, cookie => $cookie};
  return $result unless $id && $csrf;

  my @q = (
    $self->table_name,
    {$self->cookie, => $cookie, $self->csrf        => $csrf},
    {$self->id      => $id,     $self->expire_date => {'>=', $now_time}}
  );
  if (my $dbh = $self->pg->db->update(@q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub update_csrf {
  my ($self, $id, $csrf) = @_;

  my $mhf_utils = $self->mhf_util->new;
  my $now_time  = $mhf_utils->sql_datetime(0);

  return {result => 0, code => 500, data => $csrf}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $csrf};
  return $result unless $id && $csrf;

  my @q = (
    $self->table_name,
    {$self->csrf => $csrf},
    {$self->id   => $id, $self->expire_date => {'>=', $now_time}}
  );
  if (my $dbh = $self->pg->db->update(@q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub update_cookie {
  my ($self, $id, $cookie) = @_;

  my $mhf_utils = $self->mhf_util->new;
  my $now_time  = $mhf_utils->sql_datetime(0);

  return {result => 0, code => 500, data => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $cookie};
  return $result unless $id && $cookie;

  my @q = (
    $self->table_name,
    {$self->cookie => $cookie},
    {$self->id     => $id, $self->expire_date => {'>=', $now_time}}
  );
  if (my $dbh = $self->pg->db->update(@q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub delete {
  my ($self, $identify, $cookie) = @_;

  return {result => 0, code => 500, data => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $cookie};
  return $result unless $identify && $cookie;

  my @q = (
    $self->table_name, {$self->identify => $identify, $self->cookie => $cookie}
  );
  if (my $dbh = $self->pg->db->delete(@q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub check {
  my ($self, $identify, $cookie) = @_;

  my $mhf_utils = $self->mhf_util->new;
  my $now_time  = $mhf_utils->sql_datetime(0);

  return {result => 0, code => 500, data => $cookie}
    unless $self->check_table->{result};

  my $result = {result => 0, code => 400, data => $cookie};
  return $result unless $identify && $cookie;

  my @q = (
    $self->table_name,
    '*',
    {
      -or => {$self->identify => $identify, $self->cookie => $cookie},
      $self->expire_date => {'>', '\'NOW()'}
    }
  );
  if (my $rv = $self->pg->db->select(@q)) {
    my $r_data = $rv->hash;
    $result = {
      result => 1,
      code   => 200,
      data   => {
        cookie      => $cookie,
        id          => $r_data->{$self->id},
        csrf        => $r_data->{$self->csrf},
        identify    => $r_data->{$self->identify},
        cookie_lock => $r_data->{$self->cookie_lock},
        lock        => $r_data->{$self->lock}
      }
    };
  }
  return $result;
}

sub empty_table {
  my $self   = shift;
  my $result = {result => 0, code => 500, data => 'can\'t delete table'};

  if (my $dbh = $self->pg->db->query('DELETE FROM ' . $self->table_name)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
    $result->{data}   = '';
  }
  return $result;
}

sub drop_table {
  my $self   = shift;
  my $result = {result => 0, code => 500, data => 'can\'t drop table'};

  if (my $dbh
    = $self->pg->db->query('DROP TABLE IF EXISTS ' . $self->table_name))
  {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
    $result->{data}   = '';
  }
  return $result;
}

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Backend::pg - PostgreSQL Backend.

=head1 SYNOPSIS

  use Mojo::Hakkefuin::Backend::pg;
  
  my $backend = Mojo::Hakkefuin::Backend::pg->new(
    dir => 'path/your/dir/migrations',
    dsn => 'postgresql://username:password@hostname/database'
  );
  
  # use as a method
  my $backend = $backend->dsn;
  $backend->dsn('postgresql://username:password@hostname:port/database');

=head1 DESCRIPTION

L<Mojo::Hakkefuin::Backend::pg> is a backend for L<Mojolicious::Plugin::Hakkefuin>
based on L<Mojo::Hakkefuin::Backend>. All necessary tables will be created automatically.

=head1 ATTRIBUTES

L<Mojo::Hakkefuin::Backend::pg> inherits all attributes from L<Mojolicious::Plugin::Hakkefuin>
and implements the following new ones.

=head2 dsn
  
  # Example use as a config
  my $backend = Mojo::Hakkefuin::Backend::pg->new(
    ...
    dsn => 'postgresql://username:password@hostname:port/database',
    ...
  );
  
  # use as a method
  my $backend = $backend->dsn;
  $backend->dsn('postgresql://username:password@hostname:port/database');

=head2 dir

  # Example use as a config
  my $backend = Mojo::Hakkefuin::Backend::pg->new(
    ...
    dir => 'path/your/dir/migrations',
    ...
  );
  
  # use as a method
  my $backend = $backend->dir;
  $backend->dir('path/your/dir/migrations');

This attribute for specify path (directory address) of directory migrations configuration file.

=head1 METHODS

L<Mojo::Hakkefuin::Backend::pg> inherits all methods
from L<Mojo::Hakkefuin::Backend> and implements the following new ones.
In this module contains 2 section methods that is B<Table Interaction> and B<Data Interaction>.

=head2 Table Interaction

A section for all activities related to interaction data in a database table.

=head3 table_query

  my $table_query = $backend->table_query;
  $backend->table_query;

This method used by the C<create_table> method to generate
a query that will be used to create a database table.

=head3 check_table

  $backend->check_table();
  my $check_table = $backend->check_table;
  
This method is used to check whether a table in the DBMS exists or not

=head3 create_table

  $backend->create_table();
  my $create_table = $backend->create_table;

This method is used to create database table.

=head3 empty_table

  $backend->empty_table;
  my $empty_table = $backend->empty_table;
  
This method is used to delete all database table
(It means to delete all data in a table).

=head3 drop_table

  $backend->drop_table;
  my $drop_table = $backend->drop_table;

This method is used to drop database table
(It means to delete all data in a table and its contents).

=head2 Data Interaction

A section for all activities related to data interaction in a database table.
These options are currently available:

=over 2

=item $id

A variable containing a unique id that is generated when inserting data
into a table.

=item $identify

The variables that contain important information for data login
but not crucial information.

=item $cookie

The variable that contains the cookie hash, which hash is used
in the HTTP header.

=item $csrf

The variable that contains the csrf token hash, which hash is used
in the HTTP header.

=item $expires

The variable that contains timestamp format. e.g. C<2023-03-23 12:01:53>.
For more information see L<Mojo::Hakkefuin::Utils>.

=back

=head3 create($identify, $cookie, $csrf, $expires)

  $backend->create($identify, $cookie, $csrf, $expires)
  
Method for insert data login.

=head3 read($identify, $cookie)

  $backend->read($identify, $cookie);

Method for read data login.

=head3 update()

  $backend->update($id, $cookie, $csrf);

Method for update data login.

=head3 update_csrf()

  $backend->update_csrf($id, $csrf);

Method for update CSRF token login.

=head3 update_cookie()

  $backend->update_cookie($id, $cookie);

Method for update cookie login.

=head3 upd_coolock()

  $backend->upd_coolock();

Method for update cookie lock session.

=head3 upd_lckstate()

  $backend->upd_lckstate();

Method for update lock state condition.

=head3 delete($identify, $cookie)

  $backend->delete($identify, $cookie);

Method for delete data login.

=head3 check($identify, $cookie)

  $backend->check($identify, $cookie);
  
Method for check data login.

=head2 new()

  use Mojo::Hakkefuin::Backend::pg;
  
  my $backend = Mojo::Hakkefuin::Backend::pg->new(
    dir => 'path/your/dir/migrations',
    dsn => 'postgresql://username:password@hostname:port/database'
  );

Construct a new L<Mojo::Hakkefuin::Backend::pg> object.

=head1 SEE ALSO

=over 2

=item * L<Mojo::Hakkefuin>

=item * L<Mojo::Hakkefuin::Backend>

=item * L<Mojolicious::Plugin::Hakkefuin>

=item * L<Mojo::Pg>

=back

=cut
