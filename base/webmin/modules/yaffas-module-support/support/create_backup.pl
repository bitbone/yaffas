#!/usr/bin/perl -w
# save_support_infos.cgi
# download support infos to client
use strict;
use warnings;
use lib qw#/opt/yaffas/lib/perl5/#;

use File::Temp qw/ tempdir /;
use File::Path qw/ mkpath /;
use File::Copy qw/ cp /;
use File::Find;

use Yaffas;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Module::Backup;
use Yaffas::Product;
use Yaffas::Exception qw(:try);

### protos
sub backup($$);
sub cleanup($);

### globals
my $destdir		= tempdir();
my $filename	= "yaffas_support_files.tar.gz";
my $tarfile		= $destdir . "/" . $filename;

# try to create an up to date yaffas.xml file
try {
	Yaffas::Module::Backup::create_config(1);
	my $bk_bu = Yaffas::Module::Backup->new();
	my $bk_xml = $bk_bu->dump();
	if ( $bk_xml =~ m/^<\?xml/ )
	{
		unlink Yaffas::Constant::FILE->{'yaffas_config'} if -f Yaffas::Constant::FILE->{'yaffas_config'};
		my $bkfile = Yaffas::File->new(Yaffas::Constant::FILE->{'yaffas_config'}, $bk_xml);
		$bkfile->write();
	}
} catch Yaffas::Exception with {
	# delete the possibly existing but incomplete yaffas.xml
	unlink Yaffas::Constant::FILE->{'yaffas_config'} if -f Yaffas::Constant::FILE->{'yaffas_config'};
};

### Create list of Licencekeys
my $products = Yaffas::Product::get_all_installed_products();
my @keyfiles;
foreach my $product ( Yaffas::Product::get_all_installed_products() ){
	push( @keyfiles, "/usr/local/lib/libkeybb" . $product . ".so.1.0" );
	`echo $product >> /tmp/keyfiles`;
}

### define here what files/directories we need to fetch
my $jobs = 
{
	execute => {
		# add commands you want to be executed here as an arrayref
		lshw    => [ Yaffas::Constant::APPLICATION->{'lshw'} ],
		dmesg	=> [ Yaffas::Constant::APPLICATION->{'dmesg'} ],
		lspci	=> [ Yaffas::Constant::APPLICATION->{'lspci'} ],
		lspci_n	=> [ Yaffas::Constant::APPLICATION->{'lspci'}, "-n" ],
		df	=> [ Yaffas::Constant::APPLICATION->{'df'}, "-h" ],
		free	=> [ Yaffas::Constant::APPLICATION->{'free'} ],
		slapcat	=> [ Yaffas::Constant::APPLICATION->{'slapcat'} ],
		ps	=> [ Yaffas::Constant::APPLICATION->{'ps'}, "aux"],
		faxstat	=> [ Yaffas::Constant::APPLICATION->{'faxstat'}, ],
		top 	=> [ Yaffas::Constant::APPLICATION->{'top'}, "-b -n1" ],
		getent 	=> [ Yaffas::Constant::APPLICATION->{'getent'}, "passwd" ],
		route 	=> [ Yaffas::Constant::APPLICATION->{'route'}, "-n" ],
		mailq	=> [ Yaffas::Constant::APPLICATION->{'mailq'},],
		wbinfo_u => [ Yaffas::Constant::APPLICATION->{'wbinfo'}, "-u" ],
		wbinfo_g => [ Yaffas::Constant::APPLICATION->{'wbinfo'}, "-g" ],
		wbinfo_t => [ Yaffas::Constant::APPLICATION->{'wbinfo'}, "-t" ],
		wbinfo_p => [ Yaffas::Constant::APPLICATION->{'wbinfo'}, "-p" ],
		uname_a => [ Yaffas::Constant::APPLICATION->{'uname'}, "-a" ],
		ifconfig_a => [ Yaffas::Constant::APPLICATION->{'ifconfig'}, "-a" ],
		uptime  => [ Yaffas::Constant::APPLICATION->{'uptime'}, ],
		lsmod   => [ Yaffas::Constant::APPLICATION->{'lsmod'}, ],
		mount   => [ Yaffas::Constant::APPLICATION->{'mount'}, ],
		lsof_ni => [ Yaffas::Constant::APPLICATION->{'lsof'}, "-ni" ],
		'last'  => [ Yaffas::Constant::APPLICATION->{'last'}, ],
		'zarafa-users' => [ Yaffas::Constant::APPLICATION->{zarafa_admin}, "-l" ],
		'zarafa-groups' => [ Yaffas::Constant::APPLICATION->{zarafa_admin}, "-L" ],
	},
	# add files and directories you want to have included here as an arrayref
	files => [ 
		Yaffas::Constant::DIR->{'zarafa_log'},
		Yaffas::Constant::DIR->{'hylafax_log'}, 
		Yaffas::Constant::DIR->{'logdir'}, 
		Yaffas::Constant::DIR->{'selections'},
		Yaffas::Constant::FILE->{'yaffas_debug'},
		Yaffas::Constant::FILE->{'yaffas_config'}, 
		Yaffas::Constant::FILE->{'bash_history'}, 
		Yaffas::Constant::FILE->{'license_module_file'},
		Yaffas::Constant::FILE->{'resolv_conf'},
		Yaffas::Constant::FILE->{'divas_cfg'},
		Yaffas::Constant::FILE->{'proc_dma'},
		Yaffas::Constant::FILE->{'proc_swaps'},
		Yaffas::Constant::FILE->{'bootlog'},
		@keyfiles,
	],
	methods => [
		"Yaffas::Auth::auth_type"
	]
};
# files and directories to be excluded from directories defined above
my $filesexclude = [
	Yaffas::Constant::DIR->{'logdir'} . '/mysql/mysql-bin\.\d+',
];
# Specific jobs
if( Yaffas::Constant::OS eq 'Ubuntu' ) {
	$jobs->{execute}->{dpkg} = [ Yaffas::Constant::APPLICATION->{'dpkg'}, "-l" ];
	push( @{$jobs->{files}}, Yaffas::Constant::FILE->{'network_interfaces'});
} elsif( Yaffas::Constant::OS eq 'RHEL5' ) {
	$jobs->{execute}->{rpm} = [ Yaffas::Constant::APPLICATION->{'rpm'}, "-qa" ];
	push( @{$jobs->{files}}, Yaffas::Constant::DIR->{'rhel5_devices'} );
}


### we need a backup of stdout here..
open(my $out, ">&STDOUT");
my $tar = backup($jobs, $destdir);

open(STDOUT, ">&", $out);
print $tar;

unless(cleanup($destdir))
{
	exit 1;
}

sub backup($$)
{
	my ($jobs, $destdir) = @_;


	mkpath("$destdir/executed/");
	mkpath("$destdir/files/");

	while(my($job, $what) = each %{ $jobs->{'execute'} })
	{
		{
			close(STDOUT);
			close(STDERR);
			open(STDOUT, ">", "$destdir/executed/$job-stdout");
			open(STDERR, ">", "$destdir/executed/$job-stderr");

			system(@$what);
			if($? != 0)
			{
				my $why = $!;
				open(DEBUG, ">>", "$destdir/executed/FAILED");
				print DEBUG "Job $job returned exit code: $?!!!\n";
				print DEBUG "Reason: $why\n\n";
				close(DEBUG);
			}
		};

	}

	foreach my $job (@{ $jobs->{'files'} })
	{
		unless(-e $job)
		{
			my $why = $!;
			open(DEBUG, ">>", "$destdir/files/FAILED");
			print DEBUG "Cant access $job: $why\n\n";
			close(DEBUG);

			next;
		}

		if(-f $job)
		{
			my ($subpath) = ($job =~ m/^(.+)\/.*$/);
			$subpath = $destdir . "/files" . $subpath;

			mkpath($subpath) unless -d $subpath;
			cp $job, $subpath;
		}
		else
		{
			my @files;
			File::Find::find(sub {my ($dev, $ino, $mode, $nlink, $uid, $gid) = lstat($_); push @files, $File::Find::name if (-e $_ && int(-M _) < 30) }, $job);

			@files = grep { defined $_ } map {
				my $dir = $_;
				foreach my $ex (@$filesexclude) {
					if ( $dir =~ m/^$ex/ ) {
						$dir = undef;
						last;
					}
				}
				$dir;
			} @files;

			foreach my $file (@files)
			{
				my ($subpath) = ($file =~ m/^(.+)\/.*$/);
				$subpath = $destdir . "/files" . $subpath;

				mkpath($subpath) unless -d $subpath;
				cp $file, $subpath;
			}
		}
	}

	foreach my $method ( @{ $jobs->{'methods'} } ) {
		my $m_file = $method;
		$m_file =~ s/^.*:://;

		my $m_package = $method;
		$m_package =~ s/::[^:]+$//;

		my $m_path = $m_package;
		$m_path =~ s/::/\//g;
		mkpath("$destdir/executed/$m_path");

		open( OUT, ">", "$destdir/executed/$m_path/$m_file" );
		eval "use $m_package";
		print OUT eval "$method";
		close OUT;
	}

	my @save	= ("./executed", "./files");
	my $fh		= File::Temp->new(UNLINK => 0);
	my $fn		= $fh->filename();

	chdir $destdir;
	unless(Yaffas::create_compressed_archive($fn, @save))
	{
		print "cant create compressed file ($fn): $!\n";
	}

	return $fn;
}

sub cleanup($)
{
	my ($destdir) = @_;
	my (@directories, @files);

	File::Find::finddepth(sub { push @files, $File::Find::name if -f $_ }, $destdir);
	File::Find::finddepth(sub { push @directories, $File::Find::name if -d $_ }, $destdir);

	foreach my $file (@files)
	{
		unlink $file || return undef;
	}

	foreach my $directory (@directories)
	{
		rmdir $directory || return undef;
	}

	return 1;
}
