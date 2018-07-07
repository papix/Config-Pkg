requires 'perl', '5.008001';

requires 'Carp';
requires 'Module::Find';
requires 'Module::Load';
requires 'String::CamelCase';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

