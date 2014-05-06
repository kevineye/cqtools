#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 8;
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

is system($cqctl, 'set-runmode', 'author,cqtools_test'), 0, 'set-runmode';

is system($cqctl, 'start'), 0, 'start';
is system($cqadm, 'wait-for-start'), 0, 'wait-for-start';

like qx($cqadm get-runmode), qr/\bauthor\b/, 'get-runmode';
like qx($cqadm get-runmode), qr/\bcqtools_test\b/, 'get-runmode';

is system($cqctl, 'stop'), 0, 'stop';
is system($cqctl, 'wait-for-stop'), 0, 'wait-for-stop';

is system($cqctl, 'set-runmode', 'author'), 0, 'set-runmode';
