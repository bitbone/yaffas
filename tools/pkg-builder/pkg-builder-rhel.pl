#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy;
use File::Find;
use Cwd qw(abs_path);
use Data::Dumper;
use Config::General;
use Getopt::Std;

require 'Changelog.pm';

#if you get problems with these just change them to your needs
#but keep them to english!
#$ENV{'LANG'}="en_GB.UTF-8";
#$ENV{'LANGUAGE'}="en_GB:en";

$ENV{'LANG'}     = "C";
$ENV{'LANGUAGE'} = "C";

our $GPG_PASSWD = 'm@rt1nLustr';

sub build_package($);
sub sign_package($);
sub copy_package($$);
sub rm_package($$);
sub check_debian_status($$$);
sub find_package_files($$);
sub clean_source($);
sub usage();

#my $sel_base    = pop(@ARGV);
#my $dest_base   = pop(@ARGV);
#my $source_base = pop(@ARGV);

my %packages = ();
my %opts;

my @todo;

getopts( "chrf:", \%opts );

if ( defined $opts{h} ) {
	usage();
	exit(0);
}

my $file;
if ( defined( $opts{f} ) ) {
	$file = $opts{f};
}
else {
	$file = $ENV{HOME} . "/.svnbuild";
}

unless ( -r $file ) {
	print "Packagefile >$file< not available!\n";
	exit 1;
}

print "Using $file as package list.\n";

%packages = Config::General->new($file)->getall();

my $source_base = $packages{source_base};
my $dest_base   = $packages{dest_base};

delete $packages{source_base};
delete $packages{dest_base};

@todo = keys %packages;

if (@todo) {
	print "Checking config ... \n";
	my $error = 0;
	foreach (@todo) {
		unless ( defined( $packages{$_} ) ) {
			print "No config found for package $_.\n";
		}
		else {
			$packages{$_}->{source} =~ s/BASE/$source_base/g;
			$packages{$_}->{dest}   =~ s/BASE/$dest_base/g;
			$packages{$_}->{source} =~ s/PACKAGE_NAME/$_/g;

			unless ( -d $packages{$_}->{source} ) {
				print "Source directory for package $_ don't exist!\n";
				$error = 1;
			}
			unless ( -d $packages{$_}->{dest} ) {
				print "Dest directory for package $_ don't exist!\n";
				$error = 1;
			}
		}
	}

	if ($error) {
		exit 1;
	}
}
else {
	print "No package specified\n";
	exit 0;
}

if ( defined( $opts{c} ) ) {
	print "Checking only - done!\n";
	exit 0;
}

my @failed_packages = ();

foreach my $name (@todo) {
	my %pkg = %{ $packages{$name} };

	if (   ( check_debian_status( $name, $pkg{source}, $pkg{dest} ) )
		|| ( "$name" eq "bbsvn-version" ) )
	{
		chdir( $pkg{source} );

		print "Adding changelog to $pkg{source}...\n";
		my $dch     = Changelog->new("debian/changelog");
		my $version = $dch->get_latest_version();
		my $release = $dch->get_latest_release();
		open( SPEC_IN, '<', "$pkg{source}/redhat/$name.spec" )
		  || warn "$pkg{source}/redhat/$name.spec not found for $name" && push (@failed_packages, $name) && next;
		my @specfile = <SPEC_IN>;
		close(SPEC_IN);
		open( SPEC_OUT, '>', "$pkg{source}/redhat/$name.spec" );

		foreach (@specfile) {
			last if /^%changelog$/;
			$_ =~ s/^Version:\s+.*$/Version: $version/;
			if ( defined $release ) {
				$_ =~ s/^Release:\s+.*$/Release: $release/;
			}
			else {
				$_ =~ s/^Release:\s+.*$/Release: 1/;
			}
			print SPEC_OUT $_;
		}
		@specfile = $dch->get_rpm_changelog();
		print SPEC_OUT "%changelog\n";
		foreach (@specfile) {
			print SPEC_OUT $_;
		}
		close(SPEC_OUT);

		print "Building $pkg{source}...\n";
		my @package_file = build_package( $pkg{source} );
		unless (scalar @package_file) {
			print "\n\nfailed\n\n";
			push (@failed_packages, $name);
			next;
		}

		system( "git", "checkout", "$pkg{source}/redhat/$name.spec" );

		rm_package( $name, $pkg{dest} );
		foreach my $pfile (@package_file) {
			print "Signing $pfile...\n";
# 			sign_package($pfile);
			print "Copying $pfile to $pkg{dest}\n";
			copy_package( $pfile, $pkg{dest} );
		}
		rm_package( $name, $pkg{source} );

#		opendir( SEL, $sel_base );
#		my @selections = grep { -f "$sel_base/$_" } readdir(SEL);
#		closedir(SEL);
#		foreach (@selections) {
#			my $addpkg = 0;
#			open( SELFILE, "<", "$sel_base/$_" );
#			my @content = <SELFILE>;
#			foreach (@content) {
#				if (/^$name/) {
#					$_      = '';
#					$addpkg = 1;
#					last;
#				}
#			}
#			close(SELFILE);
#			open( SELFILE, ">", "$sel_base/$_" );
#			print SELFILE grep { $_ ne '' } @content;
#			print SELFILE map { `basename $_` } @package_file if $addpkg;
#			close(SELFILE);
#		}
	}
}

if (scalar @failed_packages) {
	print "\nBuilding the following packages failed:\n";
	print "$_\n" foreach @failed_packages;
	exit 1;
}
else {
	# create repository information files in pool dir
	# so yum can use the pool dir as repository
	unless(build_repository($dest_base)) {
		print "\nbuilding of repository failed\n";
		exit 1;
	}
	exit 0;
}

sub build_package($) {
	my $dir = shift;
	$dir =~ m/\/([^\/]+)\/?$/;
	my $pkg_name = $1;

	return unless ( -r "$dir/redhat/$pkg_name.spec" );
	chdir($dir);
	my @out = `LANG="C" rpmbuild -bb redhat/$pkg_name.spec 2>&1`;

	if ( $? == 0 ) {
		my @packages = ();
		foreach (@out) {
			if (/^Wrote:\s*(.*\.rpm)$/) {
				push( @packages, $1 );
			}
		}
		return @packages;
	}
	else {
		return ();
	}
}

sub sign_package($) {
	my $pkg = shift;

	open( SIGN, "| expect >/dev/null 2>&1" );
	print SIGN "spawn rpm --addsign $pkg\n";
	print SIGN "expect *:\n";
	print SIGN "send \"$GPG_PASSWD\\r\"\n";
	print SIGN "expect eof\n";
	print SIGN "exit\n";
	close(SIGN);
}

sub copy_package($$) {
	my $pkg  = shift;
	my $dest = shift;

	mkdir $dest unless ( -d $dest );

	unless ( copy( $pkg, $dest ) ) {
		die("Can't copy $pkg: $!");
	}
}

sub rm_package($$) {
	my $pkg  = shift;
	my $dest = shift;
	chdir $dest;

	foreach my $file ( find_package_files( $pkg, $dest ) ) {
		print "Removing $file\n";
		unlink $file;
	}
}

sub check_debian_status($$$) {
	my $pkg  = shift;
	my $src  = shift;
	my $dest = shift;

	if ( exists( $opts{r} ) ) {
		return 1;
	}

	open FILE, "< $src/debian/changelog"
	  or die("Can't open changelog: $! $src");
	my $line = <FILE>;
	close FILE;

	if ( $line =~ /.*\((.*)\).*/ ) {
		my $version = $1;
		my @tmp = `rpm -q --qf '%{VERSION}-%{RELEASE}\n' -p "$dest/$pkg*.rpm"`;
		return 1 unless @tmp;
		my $rpmversion = shift(@tmp);
		chomp($rpmversion);

		if ( $rpmversion =~ m/$version(-\d+)?/ ) {
			print "Package $pkg already build!\n";
			return 0;
		}
		else {
			return 1;
		}
	}
	else {
		die("Wrong changelog format! at $pkg");
	}
}

sub find_package_files($$) {
	my $pkg  = shift;
	my $dest = shift;

	opendir DIR, $dest;
	my @dir = readdir DIR;
	closedir DIR;

	@dir = grep ( /^${pkg}-\d.*\.rpm$/, @dir );

	return @dir;
}

sub build_repository {
	my $repodir = shift;
	defined $repodir or return;
	print "\nBuilding repository: $repodir\n";
	system("/usr/bin/createrepo", $repodir);
	unless($? == 0) {
		print "failed\n";
		return 0;
	}
	return 1;
}

sub usage() {
	print "syntax: svnbuild.rh.pl [options] <source-base> <destination-base>\n";
	print "options:\n";
	print "-f file\n";
	print "\t\t"
	  . 'the svnbuild config file. If this is omitted $HOME/.svnbuild will be used.';
	print "\n";
	print "-h\n";
	print "\t\tThis help.";
	print "\n";
	print "-c\n";
	print "\t\tchecks if the source and destinations files exists correctly.";
	print "\n";
	print "-r\n";
	print "\t\trebuild all packages. This takes some time!";
	print "\n";
	print "\n";
}

