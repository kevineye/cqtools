#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More;
use Cwd 'cwd';
use FindBin '$Bin';
use File::Temp 'tempdir';

if ($> == 0) {
    plan tests => 6;
} else {
    plan skip_all => 'must run as root to test start-user';
}

chdir $Bin;
die "please move or symlink a cq instance at $Bin/crx-quickstart\n" unless -d 'crx-quickstart' && -x 'crx-quickstart/bin/start';
chdir 'crx-quickstart';
$ENV{PWD} = cwd;

my $cqctl = "$Bin/../cqctl";
my $cqadm = "$Bin/../cqadm";

if (qx($cqadm status) =~ /ready/) {
    system($cqctl, 'stop');
    system($cqctl, 'wait-for-stop');
}

is system($cqctl, 'start', '--user', 'daemon'), 0, 'start';
is system($cqadm, 'wait-for-start'), 0, 'wait-for-start';

my $pid = qx($cqctl get-pid --user daemon);
cmp_ok($pid, '>', 0, 'get-pid');
like(qx{ps -p $pid -o user}, qr{\bdaemon\b}, 'correct pid');

is system($cqctl, 'stop', '--user', 'daemon'), 0, 'stop';
is system($cqctl, 'wait-for-stop', '--user', 'daemon'), 0, 'wait-for-stop';
