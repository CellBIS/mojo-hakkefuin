# 🔒 Mojo::Hakkefuin ![linux](https://github.com/CellBIS/mojo-hakkefuin/workflows/linux/badge.svg)
The Mojolicious plugin for web authentication with simple methods 
but uses additional cookies that are saved to the database 
to identify cookie expiration periods.

The plug-in is temporary released on GitHub

In Mojolicious Lite :
```perl
use Mojolicious::Lite;
plugin 'Hakkefuin' => {
  'helper.prefix' => 'your_prefix_here_',
  'stash.prefix' => 'your_stash_prefix_here',
  via => 'mariadb',
  dsn => 'mysql://root:password@mysql:3306/mhf_test',
};

```

In Mojolicious non-Lite :
```perl
# Mojolicious
$self->plugin('Hakkefuin' => {
  'helper.prefix' => 'your_prefix_here',
  'stash.prefix' => 'your_stash_prefix_here',
  via => 'mariadb',
  dsn => 'mysql://root:password@mysql:3306/mhf_test',
});

```

## Installation

All you need is a one-liner, it takes less than a minute.

    $ curl -L https://cpanmin.us | perl - -M -n https://github.com/CellBIS/mojo-hakkefuin.git

We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.
