#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 23;
use Cwd 'cwd';
use FindBin '$Bin';
use File::Temp 'tempdir';

use Cwd 'cwd';
use FindBin '$Bin';
use JSON 'decode_json';

my $cqctl = "$Bin/../cqctl";
my $cqadm = "$Bin/../cqadm";

if (qx($cqadm status) !~ /ready/) {
    chdir $Bin;
    die "please move or symlink a cq instance at $Bin/crx-quickstart\n" unless -d 'crx-quickstart' && -x 'crx-quickstart/bin/start';
    chdir 'crx-quickstart';
    $ENV{PWD} = cwd;
    system($cqctl, 'start');
    system($cqadm, 'wait-for-start');
}

my $dir = tempdir( CLEANUP => 1 );
my $testpkg = sprintf 'test-pkg-%05d', rand 100000;
my $testfile = sprintf '/tmp/test-%05d', rand 100000;
is system($cqadm, 'mkdir', $testfile), 0, 'mkdir';
is system($cqadm, 'put', "$testfile/prop", 'abc'), 0, 'put';
my $pkg = qx($cqadm pkg-create $testpkg $testfile);
is system($cqadm, 'pkg-build', $pkg), 0, 'pkg-build';
is system($cqadm, 'get', $pkg, '-o', "$dir/package.zip" ), 0, 'download';
is system($cqadm, 'rm', $testfile), 0, 'cleanup';
is system($cqadm, 'rm', $pkg), 0, 'cleanup';

is system($cqctl, 'stop'), 0, 'cqctl stop';
is system($cqctl, 'wait-for-stop'), 0, 'cqctl wait-for-stop';

is system($cqctl, 'install-on-start', "$dir/package.zip"), 0, 'cqctl install-on-start';

is system($cqctl, 'start'), 0, 'cqctl start';
is system($cqadm, 'wait-for-start'), 0, 'cqadm wait-for-start';

is qx($cqadm get "$testfile/prop"), 'abc', 'get first value';
is system($cqadm, 'put', "$testfile/prop", 'def'), 0, 'put second value';
is system($cqadm, 'pkg-build', $pkg), 0, 'pkg-build 2';
unlink "$dir/package.zip";
is system($cqadm, 'get', $pkg, '-o', "$dir/package.zip" ), 0, 'download 2';
is system($cqadm, 'rm', $testfile), 0, 'cleanup 2';
is system($cqadm, 'rm', $pkg), 0, 'cleanup 2';

is system($cqctl, 'stop'), 0, 'cqctl stop';
is system($cqctl, 'wait-for-stop'), 0, 'cqctl wait-for-stop';

is system($cqctl, 'install-on-start', "$dir/package.zip"), 0, 'cqctl install-on-start 2';

is system($cqctl, 'start'), 0, 'cqctl start';
is system($cqadm, 'wait-for-start'), 0, 'cqadm wait-for-start';

is qx($cqadm get "$testfile/prop"), 'def', 'get second value';

