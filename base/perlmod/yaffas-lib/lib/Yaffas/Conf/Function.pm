#!/usr/bin/perl -w
use strict;
package Yaffas::Conf::Function;

=head1 NAME

x

=head1 SYNOPSIS

x

=head1 DESCRIPTION

x

=head1 FUNCTION

=over

=item new ( ID NAME [PARAM] )

x

=cut

sub new {
	my $package = shift;
	my $id = shift; 
	my $name = shift;
	my @params = @_;
	my $self = {
				id => $id,
				name => $name,
				params => [],
			   };

	foreach (@params) {
		my $type  = $_->{type};
		my $param = $_->{param};
		push @{$self->{params}}, {type => $type, param => $param};
	}

	bless $self, $package;
	return $self;
}

=item add_param ( PARAM )

a list of hashes. each hash contains c<type> and c<param>.

=back

=cut

sub add_param {
	my $self = shift;
	my @params = @_;

	@params = Yaffas::Conf::_encode($self, @params);

	if ($self->{convert_error}) {
		warn("encoding not successful: type not valid?!");
		return undef;
	}

	foreach (@params) {
		my $type = $_->{type};
		my $param = $_->{param};

		push @{$self->{params}}, {type => $type, param => $param};
	}
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
