package MogileFS::Plugin::Migrate;

use strict;
use warnings;

use MogileFS::Class;
use MogileFS::FID;
use MogileFS::Worker::Query;

our $VERSION = '0.01';

sub load {

	MogileFS::register_worker_command('migrate', sub {
		my MogileFS::Worker::Query $self = shift;
		my $args = shift;

		my $src_dmid = $self->check_domain({ domain => delete $args->{src_domain} })
			or return $self->err_line('domain_not_found');

		my $dst_dmid = $self->check_domain({ domain => delete $args->{dst_domain} })
			or return $self->err_line('domain_not_found');

		my $dst_classid = MogileFS::Class->class_id($dst_dmid, $args->{dst_class})
			or return $self->err_line('class_not_found');

		my ($src_key, $dst_key) = ($args->{src_key}, $args->{dst_key});

		return $self->err_line('no_key') unless $src_key && $dst_key;

		my $src_fid = MogileFS::FID->new_from_dmid_and_key($src_dmid, $src_key)
			or return $self->err_line('unknown_key');

		my $fidid = $src_fid->id;

		my $store = Mgd::get_store;
		my $dbh = $store->dbh;

		eval {
			$dbh->do('UPDATE file SET dmid=?, classid=?, dkey=? WHERE fid=?',
				undef, $dst_dmid, $dst_classid, $dst_key, $fidid);
		};
		if ($@ || $dbh->err) {
			if ($store->was_duplicate_error) {
				return $self->err_line('key_exists');
			}
		}
		$store->condthrow;

		$store->enqueue_for_replication($fidid);

		return $self->ok_line;
	});

	return 1;
}
