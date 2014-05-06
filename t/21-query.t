#!/usr/bin/env perl
use strict;
use autodie qw(:all);
use Test::More tests => 4;

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

TODO: {
    todo_skip 'query not working in CQ 5.6', 4 if qx($cqadm info =~ /Version 5\.6/);

    like qx($cqadm query-sql "select * from nt:base where jcr:path like '/content/geometrixx/%' and contains(*, 'shapes')"),
        qr{^/content/geometrixx/en/products/circle\tcq:Page$}m, 'sql query';

    like qx($cqadm query-sql "select * from nt:base where jcr:path like '/content/geometrixx/%' and contains(*, 'shapes')" jcr:path),
        qr{^/content/geometrixx/en/products/circle$}m, 'sql query with fields';

    ok @{decode_json(qx($cqadm query-sql "select * from nt:base where jcr:path like '/content/geometrixx/%' and contains(*, 'shapes')" --json))} > 2,
        'sql query with json';

    like qx($cqadm query-xpath "/jcr:root/content/geometrixx//*[jcr:contains(., 'shapes')]"),
        qr{^/content/geometrixx/en/products/circle\tcq:Page$}m, 'xpath query';

}
