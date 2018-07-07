# NAME

Config::Pkg - Definition of configration based package, like Config::ENV

# SYNOPSIS

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

# DESCRIPTION

Config::Pkg provides configuration switching by environment variable.
This module uses package and its ihneritance for configuration definition.

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
