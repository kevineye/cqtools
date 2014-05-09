#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 20;
use Cwd 'cwd';
use FindBin '$Bin';
use File::Temp 'tempdir';

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

my $dir = tempdir( CLEANUP => 1 );
mkdir "$dir/slave";

is system($cqctl, 'offline-backup', "$dir/slave/crx-quickstart"), 0, 'offline-backup';
system('cp', '../license.properties', "$dir/slave");
is system($cqctl, 'set-port', '5502', '--dir', "$dir/slave/crx-quickstart"), 0, 'set-port';
is system($cqctl, 'join-cluster', '127.0.0.1', '--dir', "$dir/slave/crx-quickstart"), 0, 'join-cluster';

is system($cqctl, 'start'), 0, 'start master';
is system($cqadm, 'wait-for-start'), 0, 'wait-for-start master';
is system($cqctl, 'start', '--dir', "$dir/slave/crx-quickstart"), 0, 'start slave';
is system($cqadm, 'wait-for-start', '--url', 'http://localhost:5502'), 0, 'wait-for-start slave';

my $testfile = sprintf '/tmp/test-%05d', rand 100000;
my $testvalue = rand 100000;
is system($cqadm, 'put', $testfile, $testvalue), 0, 'put';
sleep 5;
is qx($cqadm get $testfile --url http://localhost:5502), $testvalue, 'get';

is system($cqctl, 'stop', '--dir', "$dir/slave/crx-quickstart"), 0, 'stop slave';
is system($cqctl, 'wait-for-stop', '--dir', "$dir/slave/crx-quickstart"), 0, 'wait-for-stop slave';

is system($cqctl, 'leave-cluster', '--dir', "$dir/slave/crx-quickstart"), 0, 'leave-cluster';

is system($cqctl, 'start', '--dir', "$dir/slave/crx-quickstart"), 0, 'start slave';
is system($cqadm, 'wait-for-start', '--url', 'http://localhost:5502'), 0, 'wait-for-start slave';

my $testvalue2 = rand 100000;
is system($cqadm, 'put', $testfile, $testvalue2), 0, 'put';
sleep 5;
is qx($cqadm get $testfile --url http://localhost:5502), $testvalue, 'get';

is system($cqctl, 'stop'), 0, 'stop master';
is system($cqctl, 'stop', '--dir', "$dir/slave/crx-quickstart"), 0, 'stop slave';
is system($cqctl, 'wait-for-stop'), 0, 'wait-for-stop master';
is system($cqctl, 'wait-for-stop', '--dir', "$dir/slave/crx-quickstart"), 0, 'wait-for-stop slave';
