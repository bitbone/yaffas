#!/usr/bin/perl -w
package Yaffas::Conf::Comment;
use strict;
use warnings;
use MIME::Base64;


=head1 NAME

x

=head1 SYNOPSIS

x

=head1 DESCRIPTION

x

=head1 FUNCTION

=over

=item new ( KEY VALUE )
x
=cut

# MIME::Base64 works like this:
#        $encoded = encode_base64('Aladdin:open sesame');
#        $decoded = decode_base64($encoded);


sub new {
	my $package = shift;
	my $key = shift;
	my $value = shift;


	my $self = {
				key => encode_base64($key),
				value => encode_base64($value),
			   };


	bless $self, $package;
	return $self;
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
