package MogileFS::Plugin::Migrate;

use strict;
use warnings;

use MogileFS::FID;
use MogileFS::Worker::Query;

our $VERSION = '0.04';

sub load {

	MogileFS::register_worker_command('migrate', sub {
		my MogileFS::Worker::Query $self = shift;
		my $args = shift;

		my $src_dmid = $self->check_domain({ domain => $args->{src_domain} })
			or return $self->err_line('domain_not_found');

		my $dst_dmid = $self->check_domain({ domain => $args->{dst_domain} })
			or return $self->err_line('domain_not_found');

		my $dst_classid = Mgd::class_factory()->get_by_name($dst_dmid, $args->{dst_class})->{classid} || 0;

		# only return error if class was defined, otherwise use "default"
		return $self->err_line('class_not_found')
			if $dst_classid == 0 && defined $args->{dst_class};

		my ($src_key, $dst_key) = ($args->{src_key}, $args->{dst_key});

		return $self->err_line('no_key')
			unless $src_key && $dst_key;

		my $src_fid = MogileFS::FID->new_from_dmid_and_key($src_dmid, $src_key)
			or return $self->err_line('unknown_key');

		my $fidid = $src_fid->id;

		my $store = Mgd::get_store;
		my $dbh = $store->dbh;

		eval {
			$dbh->do('UPDATE file SET dmid = ?, classid = ?, dkey = ? WHERE fid = ?',
				undef, $dst_dmid, $dst_classid, $dst_key, $fidid);

			# ignore plugin errors
			MogileFS::run_global_hook('plugin_file_migrated', {
				fid         => $fidid,
				src_dmid    => $src_dmid,
				dst_classid => $dst_classid,
				dst_dmid    => $dst_dmid,
				%$args
			});
		};
		if ($@ || $dbh->err) {
			if ($store->was_duplicate_error) {
				return $self->err_line('key_exists');
			} else {
				my $err = $@ || $dbh->err;
				Mgd::log('err', __PACKAGE__ . ": $err");
			}
		}
		$store->condthrow;

		$store->enqueue_for_replication($fidid, undef, 1);

		return $self->ok_line;
	});

	return 1;
}

1;
