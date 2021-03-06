package Serializer;

sub from_db {
    my ($pkg, $dbstring, $dbtype) = @_;
    return 4 unless $dbtype;
    return $dbtype;
}

package main;

use Test::More tests => 15;
use PGObject::Type::Registry;
use Test::Exception;

lives_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'Serializer') },
        "Basic type registration";
lives_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'Serializer') },
        "Repeat type registration";

throws_ok { PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'main') }
    qr/different target/,
    "Repeat type registration, different type, fails";

throws_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo2', apptype => 'Foobar') }
    qr/not yet loaded/,
    "Cannot register undefined type";


throws_ok{PGObject::Type::Registry->register_type(
        registry => 'foo', dbtype => 'foo', apptype => 'PGObject') }
 qr/Registry.*exist/, 
'Correction exception thrown, reregistering in nonexistent registry.';

lives_ok { PGObject::Type::Registry->new_registry('foo') }, 'Created registry';

my $deserializer;

lives_ok { $deserializer =
               PGObject::Type::Registry->deserializer(registry => 'foo',
                                                      'dbtype' => 'test') },
    'allocating deserializer of unregistered type';

is (PGObject::Type::Registry->deserialize(
        registry => 'foo', 'dbtype' => 'test', 'dbstring' => '10000'), 10000,
    'Deserialization of unregisterd type returns input straight');
is ($deserializer->('10001'), 10001,
    'Deserialization of unregistered type returns input straight from allocated deserializer');
lives_ok { PGObject::Type::Registry->register_type(
        registry => 'foo', dbtype => 'test', apptype => 'Serializer') },
        'registering serializer';

lives_ok { $deserializer =
               PGObject::Type::Registry->deserializer(registry => 'foo',
                                                      'dbtype' => 'test') },
    'allocating deserializer of registered type';

is (PGObject::Type::Registry->deserialize(
        registry => 'foo', 'dbtype' => 'test', 'dbstring' => '10000'), 'test',
        'Deserialization of registerd type returns from_db');
is ($deserializer->('10001'), 'test',
    'Deserialization of registered type returns from_db from allocated deserializer');

is_deeply([sort {$a cmp $b} qw(foo default)], [sort {$a cmp $b} PGObject::Type::Registry->list()], 'Registry as expected');

is(PGObject::Type::Registry->inspect('foo')->{test}, 'Serializer', "Correct inspection behavior");
