#!/usr/bin/perl
package Yaffas;

use warnings;
use strict;
use encoding "utf8";

BEGIN {
	use Exporter ();
	our(@ISA, @EXPORT_OK);

	@ISA = qw(Exporter);
	@EXPORT_OK = qw(do_back_quote
					do_back_quote_2
					do_back_quote_12
					system_silent);
}

use Archive::Tar; # libarchive-tar-perl libcompress-zlib-perl libio-string-perl libio-zlib-perl
use Carp qw(cluck);
use File::Find;
use Yaffas::Product;
use Yaffas::File::Config;
use Yaffas::Constant;
use Yaffas::UI::Webmin;
use Yaffas::UI;
use IPC::Open3;
use Symbol qw(gensym);
use POSIX ":sys_wait_h";

### prototypes ###
sub do_back_quote (@);

=pod

=head1 NAME

Yaffas --todo --

=head1 SYNOPSIS

use Yaffas;

=head1 DESCRIPTION

Yaffas --todo --

=head1 FUNCTIONS

=over

=item do_back_quote (CMD, [PARAMETERS])

executes a CMD with its PARAMETERS, in a save way.  STDERR goes to nirvana.

=cut

sub do_back_quote(@) {

	warn "call do_back_quote with more than one param."	if (scalar @_ <= 1);
	warn "Use absolute path!\n" unless($_[0] =~ m#^/#);

	throw Yaffas::Exception("Yaffas.pm: do_back_quote; caller: ".( caller(1) )[3]." (line: ".( caller(1) )[2].")") unless -x $_[0];

	my $pid;
	unless (defined($pid = open(KID, "-|"))) {
		print "Can't fork: $!";
		die;
	}
	if ($pid) {                     # parent
		my @output = ();
		local $_;
		while (<KID>) {
			push @output, $_;
		}
		close KID;
		return wantarray ? @output : join("", @output);
	} else {
		local $ENV{'PATH'} = "/usr/sbin/:/sbin/:/bin:/usr/bin";
		# Minimal PATH.
		# Consider sanitizing the environment even more.
		close(STDERR);
		open(STDERR, "/dev/null");
		exec @_ or (print "can't exec $_[0]: $!" and die);
	}
}

sub do_back_quote_2(@) {
	warn "call do_back_quote_2 with more than one param."	if (scalar @_ <= 1);
	warn "Use absolute path!\n" unless($_[0] =~ m#^/#);

	open NULL , ">", "/dev/null";

	local $ENV{'PATH'} = "/usr/sbin/:/sbin/:/bin:/usr/bin";

	open3(gensym, ">&NULL", \*KID , @_) or die "Can't fork $!";

	my @output = ();
	local $_;
	while (<KID>) { # gibt ein kind eine zeile aus ohne zeilenumbruch, blockt die io hier.
		push @output, $_;
	}
	close KID;
	return wantarray ? @output : join("", @output);
}

sub do_back_quote_12 (@){
	warn "call do_back_quote_2 with more than one param."	if (scalar @_ <= 1);
	warn "Use absolute path!\n" unless($_[0] =~ m#^/#);


	my $pid;
	open NULL , ">", "/dev/null";
	# siehe doku do_back_quote_2

	# this segfaults!
#	my $sig_chld = $SIG{CHLD};
#	$SIG{CHLD} = sub {close KID;};
	unless (defined($pid = open3(gensym, \*KID, \*KID , "-"))) {
		print "Can't fork: $!";
		die;
	}
	if ($pid) {                     # parent
		my @output = ();
		local $_;
		while (<KID>) {
			push @output, $_;
		}
		waitpid $pid, POSIX::WNOHANG;
	#	$SIG{CHLD} = $sig_chld;
		close KID;
		return wantarray ? @output : join("", @output);
	} else {
		local $ENV{'PATH'} = "/usr/sbin/:/sbin/:/bin:/usr/bin";
		# Minimal PATH.
		# Consider sanitizing the environment even more.
		exec @_ or (print "can't exec $_[0]: $!" and die);
	}
}

=item backquote_out_err( CMD )

This subroutine takes an array as its argument and executes it.
It returns two array references (stdout/stderr).

Example: my ($out, $err) = backquote_out_err("/bin/cat", "/irgendwo");

=cut

sub backquote_out_err(@)
{
	warn("Please use the absolute path!") if $_[0] !~ m#^/#;

	unless(-e $_[0])
	{
		print "No such file: ", $_[0];
		exit;
	}

	use IPC::Open3;
	use IO::File;
	use Symbol qw(gensym);
	local *CATCHERR = IO::File->new_tmpfile;

	my $pid = open3(gensym, \*CATCHOUT, ">&CATCHERR", @_);

	my @stdout = <CATCHOUT>;
	waitpid($pid, 0);
	seek CATCHERR, 0, 0;
	my @stderr = <CATCHERR>;

	return(\@stdout, \@stderr);
}


=item system_silent ( ARGS )

Like C<system>, but don't output anything on STDOUT or STDERR.

=cut

sub system_silent(@) {

	warn "call system_slient with more than one param."	if (scalar @_ <= 1);
	warn "Use absolute path!\n" unless($_[0] =~ m#^/#);

	my $pid = fork();

	return undef unless(defined($pid));

	$SIG{CHLD} = "IGNORE";
	if ($pid == 0) {
		## child
		close STDIN;
		close STDOUT;
		close STDERR;
		exec @_ or (print "can't exec $_[0]: $!" and die);
	}
}

=item init_webmin ()

=item init_usermin ()

Loads web-lib.pl and inits Webmin config.

=cut

sub init_webmin() {
	package main;
	my $web_lib = Yaffas::Constant::APPLICATION->{'webmin_web_lib'};
	do "$web_lib";
	init_config();
	package Yaffas;
	my $lang = Yaffas::UI::Webmin::get_lang_name();
	$main::text{BBCATEGORY} = $main::text{"category_$main::module_info{category}"};
	$main::text{BBMODULEDESC} = $main::module_info{"desc_".$lang};
	Yaffas::UI::Webmin::load_modules_lang();
}

sub init_usermin() {
	package main;
	my $web_lib = Yaffas::Constant::APPLICATION->{'usermin_web_lib'};
	do "$web_lib";
	init_config();
	package Yaffas;
	my $lang = Yaffas::UI::Webmin::get_lang_name();
	$main::text{BBCATEGORY} = $main::text{"category_$main::module_info{category}"};
	$main::text{BBMODULEDESC} = $main::module_info{"desc_".$lang};
	Yaffas::UI::Webmin::load_modules_lang();
}

=item check_license ( PRODUCT )

B<DEPRECATED!> This will be done if you use init_webmin / init_usermin.

Checks if license of PRODUCT is valid.

=cut

sub check_license($){
	cluck "check_license is DEPRECATED";
	die;
	1;
}

=item decode_error ( ERRORCODE ) 

Decodes an error value and return an array with all values

=cut

sub decode_error ($) {
	my $error = shift;
	my @codes;
	for my $i (0..31) {
		if ( (($error >> $i) & 1) == 1 ) {
			push @codes, (2**$i);
		}
	}
	return @codes;
}

=item create_compressed_archive ( FILENAME FILEARRAYREFERENCE )

Create the archive FILENAME, which includes all Files referenced by FILEARRAYREFERENCE.
FILEARRAYREFERENCE can consist of single files or directories.

=cut

sub create_compressed_archive ($@)
{
	my $file = shift;
	my @content;
	
	foreach ( @_ )
	{
		if ( -d $_ )
		{
			File::Find::find(sub { push @content, $File::Find::name if ( ! -d $_) }, $_);
		}
		else
		{
			push @content, $_;
		}
	}

	( Archive::Tar->create_archive($file, 9, @content) ) ? return 1 : return undef;
}

=item json_header ()

Prints out a HTTP header for JSON requests, which also disables browser caches.

=cut

sub json_header() {
	print "pragma: no-cache\n";
	print "Expires: Thu, 1 Jan 1970 00:00:00 GMT\n";
	print "Cache-Control: no-store, no-cache, must-revalidate\n";
	print "Cache-Control: post-check=0, pre-check=0\n";
	print "Content-type: application/jsonrequest\n\n";
}

1;

=back

=head1 COPYRIGHT

This file is part of yaffas.

yaffas is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

yaffas is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
License for more details.

You should have received a copy of the GNU Affero General Public
License along with yaffas.  If not, see
<http://www.gnu.org/licenses/>.

