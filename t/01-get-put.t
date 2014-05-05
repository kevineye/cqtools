#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 15;

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

is qx($cqadm get /content/jcr:primaryType), 'sling:OrderedFolder', 'get';

my $testfile = sprintf '/tmp/test-%05d', rand 100000;
my $testvalue = rand 100000;
is system($cqadm, 'put', $testfile, $testvalue), 0, 'put';
is qx($cqadm get $testfile), $testvalue, 'get put';

is system($cqadm, 'rm', $testfile), 0, 'rm';
is system([0,255], $cqadm, 'get', $testfile), 255, 'get rm';

is system($cqadm, 'mkdir', $testfile), 0, 'mkdir';
is system($cqadm, 'put', "$testfile/testprop", "hello world"), 0, 'put in new node';
is qx($cqadm get $testfile/jcr:primaryType), 'sling:Folder', 'get mkdir';
is qx($cqadm get $testfile/testprop), 'hello world', 'get mkdir put';
is decode_json(qx($cqadm get-json $testfile))->{testprop}, 'hello world', 'json';
like qx($cqadm ls -l $testfile), qr{^testprop: hello world$}m, 'ls';
is system($cqadm, 'rm', $testfile), 0, 'rm mkdir';

is system($cqadm, 'mkdir', '-t', 'nt:unstructured', $testfile), 0, 'mkdir type';
is qx($cqadm get $testfile/jcr:primaryType), 'nt:unstructured', 'get mkdir type';
is system($cqadm, 'rm', $testfile), 0, 'rm mkdir type';
