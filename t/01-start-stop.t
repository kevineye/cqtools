#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 18;
use Cwd 'cwd';
use FindBin '$Bin';

chdir $Bin;
die "please move or symlink a cq instance at $Bin/crx-quickstart\n" unless -d 'crx-quickstart' && -x 'crx-quickstart/bin/start';
chdir 'crx-quickstart';
$ENV{PWD} = cwd;

my $cqctl = "$Bin/../cqctl";
my $cqadm = "$Bin/../cqadm";

like qx($cqctl help 2>&1), qr/usage: /, 'cqctl help';
like qx($cqadm help 2>&1), qr/usage: /, 'cqadm help';

like qx($cqctl status), qr/not running/, 'cqctl status stopped';
is system([0,3], "$cqctl status >/dev/null 2>&1"), 3, 'cqctl status stopped exit';
like qx($cqadm status), qr/not running/, 'cqadm status stopped';
is system([0,3], "$cqadm status >/dev/null 2>&1"), 3, 'cqadm status stopped exit';

is system($cqctl, 'start'), 0, 'cqctl start';

is system($cqadm, 'wait-for-start'), 0, 'cqadm wait-for-start';

like qx($cqctl status), qr/is running/, 'cqctl status running';
is system([0,3], "$cqctl status >/dev/null 2>&1"), 0, 'cqctl status running exit';
like qx($cqadm status), qr/ready/, 'cqadm status ready';
is system([0,3], "$cqadm status >/dev/null 2>&1"), 0, 'cqadm status ready exit';

is system($cqctl, 'stop'), 0, 'cqctl stop';
is system($cqctl, 'wait-for-stop'), 0, 'cqctl wait-for-stop';

like qx($cqctl status), qr/not running/, 'cqctl status stopped';
is system([0,3], "$cqctl status >/dev/null 2>&1"), 3, 'cqctl status stopped exit';
like qx($cqadm status), qr/not running/, 'cqadm status stopped';
is system([0,3], "$cqadm status >/dev/null 2>&1"), 3, 'cqadm status stopped exit';
