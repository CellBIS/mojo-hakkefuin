requires "Carp"                                   => "0";
requires "CellBIS::Random"                        => "0";
requires "CellBIS::SQL::Abstract"                 => "1.2";
requires "File::Spec::Functions"                  => "0";
requires "Mojo::SQLite"                           => "0";
requires "Mojolicious"                            => "0";
requires "Scalar::Util"                           => "0";
requires "String::Random"                         => "0";
requires 'Dist::Zilla::Plugin::CPANFile'          => '0';
requires 'Dist::Zilla::Plugin::Clean'             => '0';
requires 'Dist::Zilla::Plugin::GitHub::Meta'      => '0';
requires 'Dist::Zilla::Plugin::License'           => '0';
requires 'Dist::Zilla::Plugin::MakeMaker'         => '0';
requires 'Dist::Zilla::Plugin::Manifest'          => '0';
requires 'Dist::Zilla::Plugin::ModuleBuild'       => '0';
requires 'Dist::Zilla::Plugin::PodCoverageTests'  => '0';
requires 'Dist::Zilla::Plugin::PodSyntaxTests'    => '0';
requires 'Dist::Zilla::Plugin::VersionFromModule' => '0';
requires 'Dist::Zilla::PluginBundle::Git'         => '0';

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Mojolicious::Lite" => "0";
  requires "Test::Mojo"        => "0";
  requires "Test::More"        => "0";
  requires "strict"            => "0";
  requires "warnings"          => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build"       => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::More"              => "0";
  requires "Test::Pod"               => "1.41";
  requires "Test::Pod::Coverage"     => "1.08";
  requires "strict"                  => "0";
  requires "warnings"                => "0";
};
