#! /usr/bin/perl

use strict;
use warnings;

use File::Spec::Functions;
use File::Copy;
use File::Basename;
use OpenSSL::Test qw/:DEFAULT top_file/;

setup("test_rehash");

plan tests => 4;

indir "rehash.$$" => sub {
    prepare();
    ok(run(app(["openssl", "rehash", curdir()])),
       'Testing normal rehash operations');
}, create => 1, cleanup => 1;

indir "rehash.$$" => sub {
    prepare(sub { chmod 400, $_ foreach (@_); });
    ok(run(app(["openssl", "rehash", curdir()])),
       'Testing rehash operations on readonly files');
}, create => 1, cleanup => 1;

indir "rehash.$$" => sub {
    ok(run(app(["openssl", "rehash", curdir()])),
       'Testing rehash operations on empty directory');
}, create => 1, cleanup => 1;

indir "rehash.$$" => sub {
    prepare();
    chmod 0500, curdir();
    isnt(run(app(["openssl", "rehash", curdir()])), 1,
         'Testing rehash operations on readonly directory');
    chmod 0700, curdir();       # make it writable again, so cleanup works
}, create => 1, cleanup => 1;

sub prepare {
    my @sourcefiles =
        sort map { glob(top_file('certs', 'demo', "*.$_")) } ('pem',
                                                              'crt',
                                                              'cer',
                                                              'crl');
    my @destfiles = ();
    foreach (@sourcefiles) {
        copy($_, curdir());
        push @destfiles, catfile(curdir(), basename($_));
    }
    foreach (@_) {
        die "Internal error, argument is not CODE"
            unless (ref($_) eq 'CODE');
        $_->(@destfiles);
    }
}
