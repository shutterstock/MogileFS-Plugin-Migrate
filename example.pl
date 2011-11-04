use strict;
use warnings;

use MogileFS::Client;

my $mogilefs = MogileFS::Client->new(domain => 'src',
                                     hosts  => ['127.0.0.1:7001']);

my $res = $mogilefs->{backend}->do_request('plugin_migrate', {
	src_domain => $mogilefs->{domain},
	src_key    => '/src-key',
	dst_domain => 'dst',
	dst_class  => 'dst_class',
	dst_key    => '/dst-key',
});

unless (defined $res) {
	print "Error: $mogilefs->{backend}->{lasterr}\n";
} else {
	print "OK\n";
}
