#!/usr/bin/perl -w
use strict;
package Yaffas::File;
use Yaffas::Check;
use Yaffas::UGM;
use Yaffas::Exception;
use Error qw(:try);
use Fcntl qw (:flock);

# needed for Yaffas::Test
our $TESTDIR = "";

## prototypes ##
sub _read_file($\@);
sub _write_file($@);

=pod

=head1 NAME

Yaffas::File - File Manipulations

=head1 SYNOPSIS

 use Yaffas::File;
 my $bkfile = Yaffas::File->new();
 $bkfile->splice_line();
 $bkfile->add_line();
 $bkfile->write();

=head1 DESCRIPTION

Yaffas::File is an easy Module for File Manipulations.
B<Achtung> do not use it in oneliners with perl -l

=head1 METHODS

=over

=item new ( FILE, [CONTENT] )

Creates a new Yaffas::File object and fills the Yaffas::File object with CONTENT.
If CONTENT is omittet C<new> will trys to read the FILE and get its content
from the FILE. CONTENT can be a Scalar or an Array.

Retunrs undef on error. Errorcases would be file exists and isnt readable or File dosnt exist
but the filename is not valid C<Yaffas::check::file()>.

It will return undef, if you call new not in OO context or if you do not pass a filename.

=cut

sub new($$;\[$@]) {
    my $package = shift;
    my $file = shift;
    my $content = shift;
    my $self = {};

	return undef unless $package;
	return undef unless $file;

	$file = $TESTDIR.$file;

    $self->{UID} = undef;
    $self->{GID} = undef;
    $self->{PERMS} = undef;
	$self->{NEWLINE} = "\n";

    if (defined $content) {
        if (ref $content eq "ARRAY") {
            $self->{CONTENT} = $content;
        }else {
            $self->{CONTENT} = [$content];
        }
    }else {
        my @content;
		# does file exists
		if (-e $file) {
			if (-r $file) {
				_read_file($file, @content);
			}else {
				return undef;
			}
		}else {
			my $filename = (split(/\//, $file))[-1];
			return undef unless Yaffas::Check::filename($filename);
		}

        $self->{CONTENT} = \@content;
    }
    $self->{FILE} = $file;
    bless $self, $package;
    return $self;
}

sub set_content($$){
        my $self = shift;
        my $content_ref=shift;
        $self->{CONTENT} = $content_ref;
}


=item search_line ( REGEX, [BEGIN, END])

It searches for a line that matches given REGEX. Please use the L<perlop/qr>
operator. It returns the linenumber of the first matching line in scalar context,
all linenumbers in array context and returns C<undef> if nothing could be found.

=cut

sub search_line($$;$$){
	return 0 unless defined wantarray; #void context
	my $self = shift;
	my $regex = shift;
	my $begin = shift;
	my $end = shift;

	# perldoc perlvar
	$begin = $[ unless defined $begin;
	$end = $#{$self->{CONTENT}} unless defined $end;

	my @found_lines;

	for (my $i = $begin; $i <= $end; $i++) {
		if (${$self->{CONTENT}}[$i] =~ /$regex/) {
			push @found_lines, $i;
			return $i unless wantarray;
		}
	}

	return undef if not wantarray and scalar @found_lines == 0; #in scalar context
	return @found_lines; #in array context
}


=item splice_line ( [OFFSET [LENGTH [LIST]]] )

It behaves like splice, so have a look at L<perlfunc/splice> and L<perlvar>
especially if you have a modivied $[. Like splice, it returns the removed
Lines in array context, else the last removed line or undef if nothing was
removed.

=cut

sub splice_line {
    my $self = shift;
    my $offset = shift;
    my $length = shift;
    my @replace_list = @_;
    my @return;

    if (not defined $offset) {
        @return = splice @{$self->{CONTENT}};
    }elsif (not defined $length) {
        @return = splice @{$self->{CONTENT}}, $offset;
    }elsif (not @replace_list) {
        @return = splice @{$self->{CONTENT}}, $offset, $length;
    }else {
        @return = splice @{$self->{CONTENT}}, $offset, $length, @replace_list;
    }

    return wantarray ? @return : $return[-1];
}

=item get_content_singleline ()

returns the whole file in one line.

=cut

sub get_content_singleline($) {
	my $self = shift;
	return join "\n", @{$self->{CONTENT}};
}


=item get_content ( [LINES] )

In array context, it returns linenr LINES of the file. If LINES are omitted it returns the whole File.
In scalar context, it returns the first line of your LINES, or the first line of the file, if LINES are omitted.

=cut

sub get_content($;@){
    my $self = shift;
    my @return;
    foreach (@_) {
        push @return, ${$self->{CONTENT}}[$_] if (defined $_);
    }
	if (wantarray()) {
		return @return ? @return : @{$self->{CONTENT}};
	}else {
		return @return ? $return[0] : @{$self->{CONTENT}}[0];	}
}

=item add_line ( LINES )

Adds a line or more at the end of file.

=cut

sub add_line ($@) {
	my $self = shift;
	my @lines = map { split /\n/, $_ } @_;

	splice @{$self->{CONTENT}}, @{$self->{CONTENT}}, 0, @lines;

	return 1;
}

=item set_newline_char()

Sets the char which is set between two lines.

=cut

sub set_newline_char($$) {
	my $self = shift;
	$self->{NEWLINE} = shift;
}

=item write ()

=item save()

It writes the back the Yaffas::File object to its $file. On Success returns 1,
otherwise 0.

=cut

sub write($){
    my $self = shift;
    return undef unless _write_file($self->{FILE}, $self->{NEWLINE}, @{$self->{CONTENT}} );
    $self->_apply_permissions();
    return 1;
}

*save = *write; ## alias

=item wipe_content

removes all content from the Yaffas::File object.

=cut

sub wipe_content {
	my $self = shift;
	$self->{CONTENT} = [];

	return 1;
}



=item get_safe_filename (FILENAME)

returns harmless filename (e.g. contains no '..' or '/') or undef if length < 1

=cut

sub get_safe_filename($) {
	my $infilename = shift;
	my $returnfilename = undef;
	$infilename =~ s/((\.\.)|(\/)|(\\)|(\?)|(\*))//g;
	if ( length($infilename)>0) {
		 $returnfilename = $infilename;
		}
	return $returnfilename;
}

=item set_permissions ( [OWNER, GROUP, PERMISSIONS ] )

 does chown and chmod in one :)
 owner and group must be names
 permissions must be in octal (leading zero), e.g. 0640, 02400

=back

=cut

sub set_permissions($;$$$) {
	my $self = shift;
	my $user = shift;
	my $group = shift;
	my $perms = shift;
	return undef unless $self;
	$self->{UID} = Yaffas::UGM::get_uid_by_username($user);
	$self->{GID} = Yaffas::UGM::get_gid_by_groupname($group);
	$self->{PERMS} = $perms;
}

=item name()

returns the name of the opened file

=cut

sub name() {
	my $self = shift;
	return $self->{FILE};
}

# returns 0 on error
sub _read_file($\@){
    my $file = shift;
    my $array = shift;
    open FILE, "<", $file or return 0;
	flock(FILE, LOCK_EX);
    chomp (@{$array} = <FILE>);
    close FILE;
    return 1;
}

# returns 0 on error
sub _write_file($@){
	my $file = shift;
	my $newline = shift;
	local $\; # ensure to work with "perl -l"
	open FILE, ">", $file or return 0;
	flock(FILE, LOCK_EX);
	foreach (@_) {
		print FILE $_, $newline;
	}
	close FILE;
}

#write file owner,group and permissions to filesystem
sub _apply_permissions() {
	my $self = shift;
	my $rv = 1;
	$rv = chmod($self->{PERMS}, $self->{FILE}) if defined $self->{PERMS};
	throw Yaffas::Exception("err_chmod",$self->{FILE}) if ($rv < 1);

	# chmod interprets -1 as do not change
	$self->{UID} = -1 unless defined $self->{UID};
	$self->{GID} = -1 unless defined $self->{GID};
	$rv = chown($self->{UID},$self->{GID},$self->{FILE}) if (($self->{UID} + $self->{GID}) != -2);
	throw Yaffas::Exception("err_chown",$self->{FILE}) if ($rv < 1);
	return 1;
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
