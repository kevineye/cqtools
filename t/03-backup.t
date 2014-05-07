#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 11;
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
mkdir "$dir/offline";
mkdir "$dir/online";

is system($cqctl, 'offline-backup', "$dir/offline/crx-quickstart"), 0, 'offline-backup';
system('cp', '../license.properties', "$dir/offline");

is system($cqctl, 'start', '--dir', "$dir/offline/crx-quickstart"), 0, 'start';
is system($cqadm, 'wait-for-start'), 0, 'wait-for-start';

is system($cqadm, 'online-backup', "$dir/online", '--delay', 0), 0, 'online-backup';
is system($cqadm, 'wait-for-online-backup'), 0, 'wait-for-online-backup';

is system($cqctl, 'stop', '--dir', "$dir/offline/crx-quickstart"), 0, 'stop';
is system($cqctl, 'wait-for-stop'), 0, 'wait-for-stop';

system('chmod', '+x', "$dir/online/crx-quickstart/bin/start", "$dir/online/crx-quickstart/bin/stop", "$dir/online/crx-quickstart/bin/status", "$dir/online/crx-quickstart/bin/quickstart");

is system($cqctl, 'start', '--dir', "$dir/online/crx-quickstart"), 0, 'start';
is system($cqadm, 'wait-for-start'), 0, 'wait-for-start';
is system($cqctl, 'stop', '--dir', "$dir/online/crx-quickstart"), 0, 'stop';
is system($cqctl, 'wait-for-stop'), 0, 'wait-for-stop';
