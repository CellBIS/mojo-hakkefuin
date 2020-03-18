package Mojo::Hakkefuin::Backend;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::Hakkefuin::Utils;

has 'dir';
has 'app';
has mhf_util => 'Mojo::Hakkefuin::Utils';

# table structure
has table_name  => 'mojo_simple_auth';
has id          => 'id_auth';
has identify    => 'identify';
has cookie      => 'cookie';
has csrf        => 'csrf';
has create_date => 'create_date';
has expire_date => 'expire_date';
has cookie_lock => 'cookie_lock';
has lock        => 'lock';

sub check_table { croak 'Method "check_table" not implemented by subclass' }
sub create_table { croak 'Method "create_table" not implemented by subclass' }
sub table_query { croak 'Method "table_query" not implemented by subclass' }

sub create { croak 'Method "create" not implemented by subclass' }
sub read { croak 'Method "read" not implemented by subclass' }
sub update { croak 'Method "update" not implemented by subclass' }
sub update_csrf { croak 'Method "update_csrf" not implemented by subclass' }
sub update_cookie { croak 'Method "update_cookie" not implemented by subclass' }
sub delete { croak 'Method "delete" not implemented by subclass' }
sub check { croak 'Method "check" not implemented by subclass' }

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Backend - Backend base class

=head1 SYNOPSIS

  package Mojo::Hakkefuin::Backend::MyBackend;
  use Mojo::Base 'Mojo::Hakkefuin::Backend';
  
  sub check_table { ... }
  sub create_table { ... }
  sub table_query { ... }
  sub create { ... }
  sub read { ... }
  sub update { ... }
  sub update_csrf { ... }
  sub update_cookie { ... }
  sub delete { ... }
  sub check { ... }

=head1 DESCRIPTION

L<Mojo::Hakkefuin::Backend> is an abstract base class for L<Mojo::Hakkefuin> backends, like
L<Mojo::Hakkefuin::Backend::sqlite>.

=head1 SEE ALSO

=over 2

=item * L<Mojolicious::Plugin::Hakkefuin>

=item * L<Mojo::Hakkefuin>

=item * L<Mojo::mysql>

=item * L<Mojo::Pg>

=item * L<Mojo::SQLite>

=item * L<Mojolicious::Guides>

=item * L<https://mojolicious.org>

=back

=cut
