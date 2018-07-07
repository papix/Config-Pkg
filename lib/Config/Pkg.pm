package Config::Pkg;
use strict;
use warnings;
use utf8;

use version;
our $VERSION = version->declare("v0.0.1");

use Carp;
use Module::Find;
use Module::Load;
use String::CamelCase;

sub import {
    my $class = shift;
    my $package = caller(0);

	no strict 'refs';
    if ($class eq __PACKAGE__) {
        my $name = shift;
        my %opts = @_;

        push @{"$package\::ISA"}, __PACKAGE__;

        for my $method (qw/ base /) {
            *{"$package\::$method"} = \&{__PACKAGE__ . "::" . $method};
        }

		no warnings 'once';
        ${"$package\::data"} = +{
            root    => $package,
            base    => {},
            config  => {},
            order   => {},
            name    => $name,
            default => $opts{default} || 'default',
            local   => [],
        };
    } else {
        my %opts = @_;
        my $data = _data($class);
        if (my $export = $opts{export} || $data->{export}) {
            *{"$package\::$export"} = sub { $class };
        }
    }
}

sub _data {
    my $package = shift || caller(1);

	no strict 'refs';
	no warnings 'once';
	return ${"$package\::data"};
}

sub base {
    my ($hash) = @_;
    _data->{base} = $hash;
}

sub env {
    my ($package) = @_;
	my $data = _data($package);
    my $name = $data->{name};

    return $name && $ENV{$name} ? $ENV{$name} : $data->{default};
}

sub current {
    my ($package) = @_;
    my $data = _data($package);
    my $env  = $package->env;

    my $vals = $data->{merged}->{$env};
    return $vals if $vals;

    if (! $data->{order}->{$env}) {
	    no strict 'refs';
        for my $child (Module::Find::findsubmod($package)) {
            *{"$child\::config"} = sub {
                my $class = caller(0);
                push @{ $data->{order}->{$env} }, $class;
                $data->{config}->{$class} = $_[0];
            };
        }
        Module::Load::load sprintf('%s::%s', $data->{root}, String::CamelCase::camelize($env));
    }

    $data->{merged}->{$env} = +{
        %{ $data->{base} },
        (map { %{ $data->{config}->{$_} } } @{ $data->{order}->{$env} }),
		(map { %{ $_ } } @{ $data->{local} }),
    };
    return $data->{merged}->{$env};
}

sub param {
    my ($package, $name) = @_;
    return $package->current->{$name};
}

sub local {
    my ($package, %hash) = @_;
    croak "returns guard object; Can't use in void context." if not defined wantarray;

    my $data = _data($package);
    push @{ $data->{local} }, \%hash;
    undef $data->{merged};

    bless sub {
        @{ $data->{local} } = grep { $_ != \%hash } @{ $data->{local} };
        undef $data->{merged};
    }, 'Config::Pkg::Local';
}

{
    package
        Config::Pkg::Local;

    sub DESTROY {
        my $self = shift;
        $self->();
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Config::Pkg - Definition of configration based package, like Config::ENV

=head1 SYNOPSIS

    package MyConfig;
    use Config::Pkg 'ENV';

    base {
        name => 'example',
        bot => 0,
    };

    package MyConfig::Development;
    use parent 'MyConfig';

    config {
        env => 'development',
    };

    package MyConfig::DevelopmentForBot;
    use parent 'MyConfig::Development';

    config {
        bot => 1,
    };

    # Usage

    use MyConfig;
    MyConfig->param('bot');
    # When the environment variable 'ENV' is...
    #   'development', returns 0
    #   'development_for_bot', returns 1

=head1 DESCRIPTION

Config::Pkg provides configuration switching by environment variable.
This module uses package and its ihneritance for configuration definition.

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

