#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 65;

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

like qx($cqadm info), qr/^Adobe\b/, 'info';

is qx($cqadm get /content/jcr:primaryType), 'sling:OrderedFolder', 'get';

my $testfile = sprintf '/tmp/test-%05d', rand 100000;
my $testvalue = rand 100000;
is system($cqadm, 'put', $testfile, $testvalue), 0, 'put';
is qx($cqadm get $testfile), $testvalue, 'get put';

is system($cqadm, 'rm', $testfile), 0, 'rm';
is system([0,255], "$cqadm get $testfile >/dev/null 2>&1"), 255, 'get rm';

is system($cqadm, 'mkdir', $testfile), 0, 'mkdir';
is qx($cqadm exists $testfile), $testfile, 'exists - true';
is system($cqadm, 'mkdir', '-p', $testfile), 0, 'mkdir -p';
is system($cqadm, 'mkdir', '-p', "$testfile/a/b/c"), 0, 'mkdir -p deep';
is qx($cqadm exists "$testfile/a/b/c"), "$testfile/a/b/c", 'exists - true';
is system($cqadm, 'put', "$testfile/testprop", "hello world"), 0, 'put in new node';
is qx($cqadm get $testfile/jcr:primaryType), 'sling:Folder', 'get mkdir';
is qx($cqadm get $testfile/testprop), 'hello world', 'get mkdir put';
is decode_json(qx($cqadm get-json $testfile))->{testprop}, 'hello world', 'json';
like qx($cqadm ls -l $testfile), qr{^testprop: hello world$}m, 'ls';
is system($cqadm, 'mkdir', "$testfile.author"), 0, 'mkdir with dot';
is system($cqadm, 'put', "$testfile.author/testprop", "xyz"), 0, 'put with dot';
is qx($cqadm get $testfile.author/testprop), 'xyz', 'get put with dot';
is qx($cqadm get $testfile/testprop), 'hello world', 'get put without dot';
is system($cqadm, 'rm', "$testfile.author"), 0, 'rm with dot';
is system($cqadm, 'put', "$testfile/testmulti", "hello world", "hello again"), 0, 'put multi 1';
is_deeply decode_json(qx($cqadm get-json $testfile))->{testmulti}, ['hello world', 'hello again'], 'get mutli 1';
is system($cqadm, 'put', "$testfile/testmulti2", '[', "hello world", ']'), 0, 'put multi 2';
is_deeply decode_json(qx($cqadm get-json $testfile))->{testmulti2}, 'hello world', 'get mutli 2';
is system($cqadm, 'rm', $testfile), 0, 'rm mkdir';
is qx($cqadm exists $testfile), '', 'exists - false';

is system($cqadm, 'mkdir', '-t', 'nt:unstructured', $testfile), 0, 'mkdir type';
is qx($cqadm get $testfile/jcr:primaryType), 'nt:unstructured', 'get mkdir type';
is system($cqadm, 'rm', $testfile), 0, 'rm mkdir type';

is system($cqadm, 'mkdir', '-t', 'nt:unstructured', $testfile), 0, 'mkdir';
is system($cqadm, 'mkdir', '-t', 'nt:unstructured', "$testfile/a"), 0, 'mkdir';
is system($cqadm, 'mkdir', '-t', 'nt:unstructured', "$testfile/b"), 0, 'mkdir';
is system($cqadm, 'mkdir', '-t', 'nt:unstructured', "$testfile/c"), 0, 'mkdir';
is system($cqadm, 'rm', '-f', "$testfile/a", "$testfile/b", "$testfile/c", "$testfile/d"), 0, 'rm -f, multi-path';
is qx($cqadm exists "$testfile/a"), '', 'rm -f - exists';
is qx($cqadm exists "$testfile/b"), '', 'rm -f - exists';
is qx($cqadm exists "$testfile/c"), '', 'rm -f - exists';
is system($cqadm, 'rm', $testfile), 0, 'rm mkdir type';

is system($cqadm, 'put-json', $testfile, "{ 'jcr:primaryType': 'nt:unstructured', 'propOne' : 'propOneValue', 'childOne' : { 'childPropOne' : true } }"), 0, 'put-json';
is qx($cqadm get $testfile/jcr:primaryType), 'nt:unstructured', 'get put-json';
is qx($cqadm get $testfile/propOne), 'propOneValue', 'get put-json';
is system($cqadm, 'rm', $testfile), 0, 'rm put-json';

is system(qq{echo "{ 'jcr:primaryType': 'nt:unstructured', 'propOne' : 'propOneValue', 'childOne' : { 'childPropOne' : true } }" | $cqadm put-json $testfile}), 0, 'put-json stdin';
is qx($cqadm get $testfile/jcr:primaryType), 'nt:unstructured', 'get put-json';
is qx($cqadm get $testfile/propOne), 'propOneValue', 'get put-json';
is system($cqadm, 'rm', $testfile), 0, 'rm put-json';

is system($cqadm, 'put-json', $testfile, "{ 'a': { 'jcr:primaryType': 'nt:unstructured', 'propOne' : 'propOneValue', 'childOne' : { 'childPropOne' : 1 } } }"), 0, 'cp-mv put-json';
is_deeply decode_json(qx($cqadm get-json $testfile/a -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json';
is system($cqadm, 'cp', "$testfile/a", "$testfile/b"), 0, 'cp-mv cp 1';
is_deeply decode_json(qx($cqadm get-json $testfile/b -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json 1';
is qx($cqadm exists "$testfile/a"), "$testfile/a", 'cm-mv exists 1';
is system($cqadm, 'mv', "$testfile/b", "$testfile/c"), 0, 'cp-mv mv 1';
is_deeply decode_json(qx($cqadm get-json $testfile/c -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json 1';
is qx($cqadm exists "$testfile/b"), '', 'rm -f - exists';
is system($cqadm, 'mkdir', "$testfile/e"), 0, 'cp-mv mkdir';
is system($cqadm, 'cp', "$testfile/a", "$testfile/e"), 0, 'cp-mv cp 2';
is_deeply decode_json(qx($cqadm get-json $testfile/e/a -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json 1';
is system($cqadm, 'mkdir', "$testfile/f"), 0, 'cp-mv mkdir 2';
is system($cqadm, 'mv', "$testfile/a", "$testfile/c", "$testfile/f"), 0, 'cp-mv mv 2';
is qx($cqadm exists "$testfile/a"), '', 'rm -f - exists';
is qx($cqadm exists "$testfile/c"), '', 'rm -f - exists';
is_deeply decode_json(qx($cqadm get-json $testfile/f/a -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json 1';
is_deeply decode_json(qx($cqadm get-json $testfile/f/c -d 10)),
    { 'jcr:primaryType' => 'nt:unstructured', propOne => 'propOneValue', childOne => { 'jcr:primaryType' => 'nt:unstructured', childPropOne => 1 }}, 'cp-mv get-json 1';
is system($cqadm, 'rm', "$testfile"), 0, 'cp-mv cleanup';
