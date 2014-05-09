#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 6;
use Cwd 'cwd';
use FindBin '$Bin';

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

is system($cqctl, 'set-port', '5502'), 0, 'set-runmode';

is system($cqctl, 'start'), 0, 'start';
is system($cqadm, 'wait-for-start', '--url', 'http://localhost:5502'), 0, 'wait-for-start';

is system($cqctl, 'stop'), 0, 'stop';
is system($cqctl, 'wait-for-stop'), 0, 'wait-for-stop';

is system($cqctl, 'set-port', '4502'), 0, 'set-runmode';
