#!/usr/bin/perl

package Changelog;

use strict;
use warnings;
use Data::Dumper;
use POSIX;

sub parse_deb_changelog ($$);
sub get_timestamp ($$);
sub check_chronological_order ($);
sub get_deb_changelog ($);
sub get_rpm_changelog ($);
sub get_latest_version ($);
sub get_latest_release ($);

sub new {
	my $pkg  = shift;
	my $file = shift;
	my @self = ();

	parse_deb_changelog( $file, \@self );
	my $index = check_chronological_order( \@self );
	if ( $index > 0 ) {
		print STDERR "chronological error in $index. entry:\n\n";
		print STDERR get_deb_changelog( [ $self[$index] ] );
		exit 1;
	}
	bless( \@self, $pkg );
}

sub parse_deb_changelog ($$) {
	my $file  = shift;
	my $self  = shift;
	my $state = 0;

	my $footer_regexp =
qr(^ -- ([^<]*)\s+<([^>]+)>  (Mon|Tue|Wed|Thu|Fri|Sat|Sun), ([ 0-9]{1,2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d+) (\d?\d:\d\d:\d\d));

	my $entry = {};

	open( FILE, '<', "$file" ) or die "cannot open $file";
	while ( my $line = <FILE> ) {
		next if $line =~ m/^\s*$/;

		if ( $state == 0 ) {
			$line =~ m/(\S+)\s+\(([\w0-9.]+)(-[\w0-9]+)?\)/
			  || die "couldn't parse $line";
			$entry->{'NAME'}    = $1;
			$entry->{'VERSION'} = $2;
			$entry->{'RELEASE'} = $3;
			$entry->{'RELEASE'} = substr( $entry->{'RELEASE'}, 1 )
			  if defined $entry->{'RELEASE'};

			$state = 1;
		}
		elsif ( $state == 1 ) {
			if ( $line =~ $footer_regexp ) {
				$state = 2;
			}
			else {
				push( @{ $entry->{'CONTENT'} }, $line );
			}
		}
		if ( $state == 2 ) {
			$line =~ $footer_regexp || die "couldn't parse $line";

			$entry->{'AUTHOR'} = $1;
			$entry->{'EMAIL'}  = $2;
			$entry->{'DOW'}    = $3;
			$entry->{'DOM'}    = $4;
			$entry->{'MONTH'}  = $5;
			$entry->{'YEAR'}   = $6;
			$entry->{'TIME'}   = $7;

			$state = 0;

			push( @$self, $entry );
			$entry = {};
		}
	}
	close(FILE);
}

sub get_timestamp ($$) {
	my ( $self, $index ) = @_;
	my $item = $$self[$index];
	my ( $hour, $minute, $second ) = split( /:/, $item->{'TIME'} );
	my %months = (
		'Jan' => 0,
		'Feb' => 1,
		'Mar' => 2,
		'Apr' => 3,
		'May' => 4,
		'Jun' => 5,
		'Jul' => 6,
		'Aug' => 7,
		'Sep' => 8,
		'Oct' => 9,
		'Nov' => 10,
		'Dec' => 11
	);
	my $time = mktime(
		$second, $minute, $hour, $item->{'DOM'},
		$months{ $item->{'MONTH'} },
		$item->{'YEAR'} - 1900
	);
	return $time;
}

sub check_chronological_order ($) {
	my $self = shift;

	my $old_time = get_timestamp( $self, 0 );
	my $new_time;
	for ( my $i = 1 ; $i < scalar @$self ; $i++ ) {
		$new_time = get_timestamp( $self, $i );
		if ( difftime( $old_time, $new_time ) < 0 ) {
			return $i;
		}
		$old_time = $new_time;
	}

	return -1;
}

sub get_deb_changelog ($) {
	my $self = shift;
	my @result;

	foreach (@$self) {
		my $entry = sprintf( "%s (%s%s) unstable; urgency=low\n\n",
			$_->{'NAME'}, $_->{'VERSION'},
			( defined $_->{'RELEASE'} ? '-' . $_->{'RELEASE'} : '' ) );
		$entry .= join( '', @{ $_->{'CONTENT'} } );
		$entry .= sprintf(
			"\n -- %s <%s>  %s, %s %s %s %s +0200\n",
			$_->{'AUTHOR'}, $_->{'EMAIL'}, $_->{'DOW'}, $_->{'DOM'},
			$_->{'MONTH'},  $_->{'YEAR'},  $_->{'TIME'}
		);
		push( @result, $entry );
	}

	return @result;
}

sub get_rpm_changelog ($) {
	my $self = shift;
	my @result;

	foreach (@$self) {
		my $entry = sprintf(
			"* %s %s %02d %s %s <%s> %s%s\n",
			$_->{'DOW'},
			$_->{'MONTH'},
			$_->{'DOM'},
			$_->{'YEAR'},
			$_->{'AUTHOR'},
			$_->{'EMAIL'},
			$_->{'VERSION'},
			( defined $_->{'RELEASE'} ? '-' . $_->{'RELEASE'} : '' )
		);
		$entry .= join(
			'',
			map {
				$_ =~ s/^\s*\*/-/;
				$_;
			  } @{ $_->{'CONTENT'} }
		);
		$entry .= "\n";
		push( @result, $entry );
	}

	return @result;
}

sub get_latest_version ($) {
	my $self   = shift;
	my $latest = $$self[0];
	return $latest->{'VERSION'};
}

sub get_latest_release ($) {
	my $self   = shift;
	my $latest = $$self[0];
	return $latest->{'RELEASE'};
}

1;
