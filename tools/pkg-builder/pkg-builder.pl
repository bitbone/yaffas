#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy;
use File::Find;
use Cwd qw(abs_path);
use Data::Dumper;
use Config::General;
use Getopt::Std;

#if you get problems with these just change them to your needs
#but keep them to english!
#$ENV{'LANG'}="en_GB.UTF-8";
#$ENV{'LANGUAGE'}="en_GB:en";

$ENV{'LANG'}="C";
$ENV{'LANGUAGE'}="C";

sub build_package($);
sub copy_package($$);
sub rm_package($$);
sub check_debian_status($$$);
sub find_package_files($$);
sub clean_source($);
sub usage();

my $source_base = "/home/christof/";
my $dest_base = "/daten/devel/bitkit/enterprise/packages/";

my %packages = ();
my %opts;

my @todo;

getopts("chrf:", \%opts);

if ( defined $opts{h} ){
	usage();
	exit(0);
}

my $file;
if (defined($opts{f})) {
	$file = $opts{f};
} else {
	$file = $ENV{HOME}."/.svnbuild";
}

unless (-r $file) {
	print "Packagefile not available!";
	exit 1;
}

print "Using $file as package list.\n";

%packages = Config::General->new($file)->getall();

$source_base = $packages{source_base} if (defined($packages{source_base}));
$dest_base = $packages{dest_base} if (defined($packages{dest_base}));

delete $packages{source_base};
delete $packages{dest_base};

#if (defined $ARGV[0] && $ARGV[0] eq "all") {
	@todo = keys %packages;
#} else {
#	@todo = @ARGV;
#}

if (@todo) {
	print "Checking config ... \n";
	my $error = 0;
	foreach (@todo) {
		unless (defined($packages{$_})) {
			print "No config found for package $_.\n";
		} else {
			$packages{$_}->{source} =~ s/BASE/$source_base/g;
			$packages{$_}->{dest} =~ s/BASE/$dest_base/g;
			$packages{$_}->{source} =~ s/PACKAGE_NAME/$_/g;

			unless (-d $packages{$_}->{source}) {
				print "Source directory for package $_ don't exist!\n";
				$error = 1;
			}
			unless (-d $packages{$_}->{dest}) {
				print "Dest directory for package $_ don't exist!\n";
				$error = 1;
			}
		}
	}

	if ($error) {
		exit 1;
	}
} else {
	print "No package specified\n";
	exit 0;
}

if (defined($opts{c})) {
	print "Checking only - done!\n";
	exit 0;
}

foreach my $name (@todo) {
	my %pkg = %{$packages{$name}};

	if ((check_debian_status($name, $pkg{source}, $pkg{dest}))||("$name" eq "bbsvn-version")) {
		chdir($pkg{source});

		print "Building $pkg{source} ... ";
		my @package_file = build_package($pkg{source});

		print "done\n" if (@package_file);
		print "failed\n" unless (@package_file);

		foreach my $pfile (@package_file) {
			rm_package($name, $pkg{dest});
			print "Copying $pfile to $pkg{dest}\n";
			copy_package($pfile, $pkg{dest});
			clean_source($pkg{source});
			print "\n-----------------------------------\n\n";
		}
	}
}

sub build_package($) {
	my $dir = shift;
	chdir $dir;
	my @ret = `dpkg-buildpackage -rfakeroot -us -uc 2>&1`;

	if ($? == 0) {
		my @package_line = grep (/dpkg-deb: building package.*deb/, @ret);

		my @packages;
		foreach (@package_line) {
			if (/^.*(\.\.\/.*\.deb).*$/) {
				push @packages, abs_path($1);
			}
		}

		return @packages;
	} else {
		print @ret;
		exit 1;
	}
	return undef;
}

sub copy_package($$) {
	my $pkg = shift;
	my $dest = shift;

	mkdir $dest unless(-d $dest);

	unless(copy ($pkg, $dest)) {
		die("Can't copy $pkg: $!");
	}
}

sub clean_source($)
{
	my $dir = shift;
	chdir $dir;
	`fakeroot debian/rules clean`
}

sub rm_package($$) {
	my $pkg = shift;
	my $dest = shift;
	chdir $dest;

	foreach my $file (find_package_files($pkg, $dest)) {
		print "Removing $file\n";
		unlink $file;
	}
}

sub check_debian_status($$$) {
	my $pkg = shift;
	my $src = shift;
	my $dest = shift;

	if(exists($opts{r})){
		return 1;
	}
		
	open FILE, "< $src/debian/changelog" or die("Can't open changelog: $! $src");
	my @lines = <FILE>;
	close FILE;

	if ($lines[0] =~ /.*\((.*)\).*/) {
		my $version = $1;
		my @files = find_package_files($pkg, $dest);
		if (grep (/^${pkg}_${version}_.*\.deb$/, @files)) {
			print "Package $pkg already build!\n";
			return 0;
		} else {
			return 1;
		}

	} else {
		die("Wrong changelog format! at $pkg");
	}
}

sub find_package_files($$) {
	my $pkg = shift;
	my $dest = shift;

	opendir DIR, $dest;
	my @dir = readdir DIR;
	closedir DIR;

	@dir = grep (/^${pkg}_.*\.deb$/, @dir);

	return @dir;
}

sub usage() {
	print "-f file\n";
	print "\t\t" . 'the svnbuild config file. If this is omitted $HOME/.svnbuild will be used.';
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
