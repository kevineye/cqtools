#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 1;

use Cwd 'cwd';
use FindBin '$Bin';

my $cqctl = "$Bin/../cqctl";
my $cqadm = "$Bin/../cqadm";

chdir $Bin;
die "please move or symlink a cq instance at $Bin/crx-quickstart\n" unless -d 'crx-quickstart' && -x 'crx-quickstart/bin/start';
chdir 'crx-quickstart';
$ENV{PWD} = cwd;

if (qx($cqadm status) =~ /ready/) {
    system($cqctl, 'stop');
    system($cqctl, 'wait-for-stop');
}

like qx($cqadm status), qr/not running/, 'stopped';
