#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'MogileFS::Plugin::Migrate',
	AUTHOR        => 'Silas Sewell <silas@shutterstock.com>',
	VERSION_FROM  => 'lib/MogileFS/Plugin/Migrate.pm',
	ABSTRACT      => 'Plugin for MogileFS that allows cross-domain moves.',
	PREREQ_PM     => {
		'MogileFS::Server'  => '2.46',
	},
	dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean         => { FILES => 'MogileFS-Plugin-Migrate-*' },
);
