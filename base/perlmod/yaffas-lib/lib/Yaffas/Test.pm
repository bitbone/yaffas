package Yaffas::Test;

use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Basename;
use File::Path;
use File::Copy;

use Test::Exception;
use Yaffas::File;
use Yaffas::Conf;

my $testdir = tempdir();

$Yaffas::File::TESTDIR = $testdir;
$Yaffas::Conf::TESTDIR = $testdir;

=pod

=head1 NAME

Yaffas::Test - Testing bitkit modules

=head1 SYNOPSIS

 use Test::More tests => 1;
 use Yaffas::Test;

 is(1, 1, "test truth");

=head1 DESCRIPTION

Yaffas::Test is an module which helps you with testing bitkit modules.
It changes the root directory of Yaffas::File, so that you can safely apply changes to any file.

=head1 METHODS

=over

=item create_file ( FILE, [ CONTENT ] )

Creates a file in the temp root directory. If CONTENT is specified, a file with this content is created.

E.g. create_file ( "/etc/exim4/bbexim.conf" )

=cut

sub create_file {
	my $file = shift;
	my @content = @_;
	mkpath($testdir.dirname($file));
	Yaffas::File->new($file, @content)->write();
}

=item create_dir ( DIR )

Creates a dir in the temp root directory.

E.g. create_dir ( "/etc/exim4/bbexim.conf" )

=cut

sub create_dir {
	my $dir = shift;
	mkpath($testdir.$dir);
}

=item setup_file ( TEST_FILE, FILENAME )

Sets up the TEST_FILE in the temp directory root. FILENAME is the normal default destination of this file.

E.g. setup_file("file", "/etc/exim4/bbexim.conf")

=cut

sub setup_file {
	my $filename = shift;
	my $dir = shift;

	$dir = $testdir.$dir;

	$filename = dirname((caller())[1])."/".$filename; # prepends the current dir to the file

	mkpath(dirname($dir));
	copy($filename, $dir);
}

=item setup_file_from_system ( FILENAME )

Sets up the FILENAME from the system into the testdir. 

E.g. setup_file_from_system("/etc/exim4/bbexim.conf")

=cut

sub setup_file_from_system {
	my $file = shift;

	mkpath($testdir.dirname($file));
	copy($file, $testdir.$file);
}

=item testdir ( )

Returns the testdir in which all file-related changes are made.

=cut

sub testdir {
	return $testdir;
}

=item delete_file ( FILE )

Removes FILE from filesystem. If FILE couldn't be deleted a warning is returned.

=cut

sub delete_file {
	my $filename = shift;
	unlink $testdir.$filename or warn "Couldn't unlink $testdir$filename: $!";
}

1;
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
