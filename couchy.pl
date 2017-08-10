#!/usr/bin/perl -w 

sub main {
    my $directory = "scripts";

    unless(mkdir($directory, 0755)) {
        die "Unable to create $directory\n";
    }
}

main();

my $directory = './scripts';
open my $fileHandle, ">>", "$directory/dummy.sh" or die "Can't open \n";
print $fileHandle "\#\!/bin/sh \n
echo \"Running in Docker container - \$0 not available\" \n
";

close $fileHandle;

my $directory = './scripts';
open my $fileHandle, ">>", "$directory/entrypoint.sh" or die "Can't open \n";

print $fileHandle "\#\!/bin/sh \n

set -e \n

[[ \"\$1\" == \"couchbase-server\" ]] \&\& \{ \n
    echo \"Starting Couchbase Server -- Web UI available at http://<ip>:8091 and logs available in /opt/couchbase/var/lib/couchbase/logs\" \n
    exec /usr/sbin/runsvdir-start \n
\} \n

exec \"\$\@\"
";

close $fileHandle;

my $directory = './scripts';
open my $fileHandle, ">>", "$directory/run" or die "Can't open \n";

print $fileHandle "\#\!/bin/sh

exec 2>\&1

cd /opt/couchbase
mkdir -p var/lib/couchbase \\
         var/lib/couchbase/config \\
         var/lib/couchbase/data \\
         var/lib/couchbase/stats \\
         var/lib/couchbase/logs \\
         var/lib/moxi

chown -R couchbase:couchbase var
exec chpst -ucouchbase /opt/couchbase/bin/couchbase-server -- -kernel global_enable_tracing false -noinput";

close $fileHandle;



my $filename = 'Dockerfile';
open(my $fh, '>', 'Dockerfile');

print $fh "FROM ubuntu:14.04 \n";
print $fh "RUN apt-get update && apt-get install -yq runit wget python-httplib2 chrpath lsof lshw sysstat net-tools numactl \n"; 
print $fh "RUN apt-get autoremove && apt-get clean \n";
print $fh "RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \n";

print "\n";

print $fh "ARG CB_VERSION=4.6.2\nARG CB_RELEASE_URL=http://packages.couchbase.com/releases\nARG CB_RELEASE_URL=http://packages.couchbase.com/releases\n
ARG CB_SHA256=57340f1acb55041385dc28574e20aef591a898d07163ed56a52bd412dadb8cb6 \n";

print $fh "
ENV PATH=\$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install \n

RUN groupadd -g 1000 couchbase && useradd couchbase -u 1000 -g couchbase -M \n

RUN wget -N \$CB_RELEASE_URL/\$CB_VERSION/\$CB_PACKAGE \&\& \\
    echo \"\$CB_SHA256  \$CB_PACKAGE\" | sha256sum -c - \&\& \\
    dpkg -i ./\$CB_PACKAGE \&\& rm -f ./\$CB_PACKAGE \n

COPY scripts/run /etc/service/couchbase-server/run \n

COPY scripts/dummy.sh /usr/local/bin/ \n
RUN ln -s dummy.sh /usr/local/bin/iptables-save && \\
    ln -s dummy.sh /usr/local/bin/lvdisplay && \\
    ln -s dummy.sh /usr/local/bin/vgdisplay && \\
    ln -s dummy.sh /usr/local/bin/pvdisplay \n

RUN chrpath -r \'\$ORIGIN/../lib' /opt/couchbase/bin/curl \n

COPY scripts/entrypoint.sh / \n
ENTRYPOINT [\"/entrypoint.sh\"]
CMD [\"couchbase-server\"]
";

close $fh;


system("docker run -d --name hahaa -p 8091-8094:8091-8094 -p 11210:11210 couchbase");

#############################################################################################################
# scripts based on 
# https://github.com/Satanette/docker/tree/master/enterprise/couchbase-server
#
# After running the script (supposing is run under /opt/couchbase/wildest to start couchbase container, named hahaa),
# you`ll obtain the following files/folders:
# 
#  root@tron:/opt/couchbase# tree /opt/couchbase/wildtest
#  /opt/couchbase/wildtest
#  ├── couchy.pl
#  ├── Dockerfile
#  ├── scripts
#    ├── dummy.sh
#    ├── entrypoint.sh
#    └── run
############################################################################################################
