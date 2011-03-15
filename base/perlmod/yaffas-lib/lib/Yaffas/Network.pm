#!/usr/bin/perl -w
use strict;
package Yaffas::Network;

use IO::Socket::INET;
use Yaffas::File;

## prototypes ##Service.pm
sub check_ip($;$$);
sub get_ip($);
sub get_interfaces();
sub scan_port($$;$);

=pod

=head1 NAME

Yaffas::Network - Module for non basic network functions

=head1 SYNOPSIS

use Yaffas::Network

=head1 DESCRIPTION

Yaffas::Network provides a bit more complex networkish functions

=head1 FUNCTIONS

=over

=item get_interfaces ()

this routine returns an array of all available interfaces

=cut

sub get_interfaces () {
	my $dev = '/proc/net/dev';
	my @ret = ();

	my $file = Yaffas::File->new($dev);

	foreach my $line ($file->get_content()) {
		if($line =~ m/^\s*([A-Za-z0-9]+):/) {
			push @ret, $1;
		}
	}

	return @ret;
}

=item get_ip ( INTERFACE )

returns the ip-address of the provided INTERFACE or 0 on error.

=cut

sub get_ip($) {
	my $interface = shift;
	return 0 unless( defined($interface) or $interface =~ // );
	if ( open(IFCONFIG, "-|" , "/sbin/ifconfig $interface") ) {
		my @lines = grep /inet addr:/, <IFCONFIG>;
		if (scalar @lines > 0) {
			$lines[0] =~ m/^.*addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*$/;
			close IFCONFIG;
			return $1;
		} else {
			print STDERR "No IP address found for $interface";
			return 0;
		}
	} else {
		print STDERR "Can't get info from ifconfig: $!";
		return 0;
	}
}

=item scan_port (IP, PORT, [TIMEOUT])

This routine connects to the given ip and port via IO::Socket::INET.
1 will be returned if we could establish the connection, otherwise you will
get a bloody undef.

=cut

sub scan_port($$;$) {
	my ($ip, $port, $timeout) = @_;
	$timeout = 5 unless $timeout;
	IO::Socket::INET->new(
			PeerAddr	=> $ip,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout		=> $timeout
			) || return undef;

	return 1;
}

=back

=cut

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
