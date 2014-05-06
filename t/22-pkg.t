#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 6;

use Cwd 'cwd';
use FindBin '$Bin';
use JSON 'decode_json';

my $cqctl = "$Bin/../cqctl";
my $cqadm = "$Bin/../cqadm";

my $stop_when_finished = 0;
if (qx($cqadm status) !~ /ready/) {
    $stop_when_finished = 1;
    chdir $Bin;
    die "please move or symlink a cq instance at $Bin/crx-quickstart\n" unless -d 'crx-quickstart' && -x 'crx-quickstart/bin/start';
    chdir 'crx-quickstart';
    $ENV{PWD} = cwd;
    system($cqctl, 'start');
    system($cqadm, 'wait-for-start');
}

END {
    if ($stop_when_finished) {
        system($cqctl, 'stop');
        system($cqctl, 'wait-for-stop');
    }
}

my $testpkg = sprintf 'test-pkg-%05d', rand 100000;
my $pkg = qx($cqadm pkg-create $testpkg /etc/designs/blog);
is $pkg, "/etc/packages/tmp/$testpkg.zip", 'pkg-create';

is system($cqadm, 'pkg-build', $pkg), 0, 'pkg-build';

my $zip = qx($cqadm get $pkg);
like $zip, qr/^PK\003\004/, 'download - zip header';
ok length $zip > 10000, 'download - size';

$zip = qx($cqadm pkg /etc/designs/blog);
like $zip, qr/^PK\003\004/, 'pkg - zip header';
ok length $zip > 10000, 'pkg - size';
