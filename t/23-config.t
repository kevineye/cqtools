#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 14;

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

is qx{$cqadm get-config com.day.cq.wcm.undo.UndoConfig service.pid}, 'com.day.cq.wcm.undo.UndoConfig', 'get-config';
is qx{$cqadm get-config com.day.cq.wcm.undo.UndoConfig service.pid --json}, '"com.day.cq.wcm.undo.UndoConfig"', 'get-config';
isa_ok decode_json(qx{$cqadm get-config com.day.cq.wcm.undo.UndoConfig cq.wcm.undo.whitelist --json}), 'ARRAY', 'get-config';
like qx{$cqadm get-config com.day.cq.wcm.undo.UndoConfig}, qr{^service.pid = }, 'get-config';
is decode_json(qx{$cqadm get-config com.day.cq.wcm.undo.UndoConfig --json})->{'service.pid'}, 'com.day.cq.wcm.undo.UndoConfig', 'get-config';

is_deeply [ split /\n/, qx{$cqadm find-config com.day.cq.commons.servlets.RootMappingServlet} ],
    [ qw(/libs/cq/core/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config/com.day.cq.commons.servlets.RootMappingServlet
         /libs/cq/core/config.publish/com.day.cq.commons.servlets.RootMappingServlet) ],
    'find-config';

is system($cqadm, 'set-config', 'com.day.cq.commons.servlets.RootMappingServlet', 'rootmapping.target', '/siteadmin'), 0, 'set-config';
sleep 5;
is qx{$cqadm get-config com.day.cq.commons.servlets.RootMappingServlet rootmapping.target}, '/siteadmin', 'get-config';
is_deeply [ split /\n/, qx{$cqadm find-config com.day.cq.commons.servlets.RootMappingServlet} ],
    [ qw(/apps/system/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/cq/core/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config/com.day.cq.commons.servlets.RootMappingServlet
         /libs/cq/core/config.publish/com.day.cq.commons.servlets.RootMappingServlet) ],
    'find-config';

is system($cqadm, 'rm', '/apps/system/config.author/com.day.cq.commons.servlets.RootMappingServlet'), 0, 'rm config';

is_deeply [ split /\n/, qx{$cqadm find-config com.day.cq.commons.servlets.RootMappingServlet} ],
    [ qw(/libs/cq/core/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config.author/com.day.cq.commons.servlets.RootMappingServlet
         /libs/system/config/com.day.cq.commons.servlets.RootMappingServlet
         /libs/cq/core/config.publish/com.day.cq.commons.servlets.RootMappingServlet) ],
    'find-config';

is system($cqadm, 'set-config', 'com.day.cq.replication.impl.ReverseReplicator',
    'frequency', '60000', 'root-paths', '[', '/etc', '/content', ']'), 0, 'set-config multi';
sleep 5;
is_deeply decode_json(qx{$cqadm get-config com.day.cq.replication.impl.ReverseReplicator --json}),
    {
        BundleLocation => 'launchpad:resources/install/0/com.adobe.granite.replication.core-5.5.14.jar',
        'service.pid' => 'com.day.cq.replication.impl.ReverseReplicator',
        'frequency' => 60000,
        'root-paths' => [ '/etc', '/content' ],
    },
    'get-config multi';
is system($cqadm, 'rm', '/apps/system/config.author/com.day.cq.replication.impl.ReverseReplicator'), 0, 'rm config';
