=pod

=head1 NAME

Yaffas::Auth::Type - Module for authentication types

=head1 SYNOPSIS

use Yaffas::Auth::Type qw(:standard);

=head1 DESCRIPTION

Every authentication type is defined as constant here

=cut

package Yaffas::Auth::Type;

sub BEGIN {
	use Exporter;
	our @ISA= qw(Exporter);
	our @EXPORT_OK = qw(LOCAL_LDAP REMOTE_LDAP PDC ADS FILES);
	our %EXPORT_TAGS = (standard => [qw( LOCAL_LDAP REMOTE_LDAP PDC ADS FILES)]);
}

=head1 CONSTANTS

=over

=item constants in Package Yaffas::Auth::Type

 keys: LOCAL_LDAP, REMOTE_LDAP, PDC, ADS, FILES
 values are corresponding long forms

=back

=cut

use constant {
	LOCAL_LDAP  => 'local LDAP',
	REMOTE_LDAP => 'remote LDAP',
	PDC         => 'Primary Domain Controller',
	ADS         => 'Active Directory',
	FILES       => 'local files',
};

return 1;

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
