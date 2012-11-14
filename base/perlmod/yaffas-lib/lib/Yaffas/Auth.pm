#!/usr/bin/perl -w
use strict;
package Yaffas::Auth;

use Yaffas::File;
use Yaffas::File::Config;
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::Product;
use Yaffas::Auth::Type qw(:standard);
use File::Samba;


=pod

=head1 NAME

Yaffas::Auth - Module for informations on the Authication Mechanismn

=head1 SYNOPSIS

use Yaffas::Auth

=head1 DESCRIPTION

useful things to get information on the Authantication Mechanismn.
This incluces remote LDAP and ADS.

=head1 FUNCTIONS

=over

=item get_auth_type()

=item auth_type() B<(DEPRECATED)>

returns a value (long form) from Yaffas::Auth::Type (see above)

e.g. C<if (Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::ADS)>

=back

=cut

*get_auth_type = \&auth_type;
sub auth_type() {
	return NOT_SET if is_local_files_only_auth ();
	my $dc_info = get_pdc_info();
	if ((scalar keys %{$dc_info}) > 0) {
		return ADS if (defined $dc_info->{'type'} && $dc_info->{'type'} eq 'win');
		return PDC if (defined $dc_info->{'type'} && $dc_info->{'type'} eq 'samba');
		return FILES if ($dc_info->{'backend'} eq 'smbpasswd');
	} else {
		my $ldap_info = get_bk_ldap_auth();
		if(defined $ldap_info) {
			return LOCAL_LDAP if( $ldap_info->{host} eq '127.0.0.1' || $ldap_info->{host} eq 'localhost' );
			return REMOTE_LDAP;
		}
	}

	# should never get here
	return undef;
}

=over

=item get_local_root_passwd()

Returns the currently set root password

Throws: throw Yaffas::Exception('err_read_file')

=back

=cut

sub get_local_root_passwd() {
	my $pass = "";

# If ldap.secret.local exists (while remote Authentication is active) read the Password from there
	if( -f Yaffas::Constant::FILE->{ldap_secret_local} ){
		open( SECRET, Yaffas::Constant::FILE->{ldap_secret_local} )
			or throw Yaffas::Exception('err_read_file', Yaffas::Constant::FILE->{ldap_secret_local});
	}
	else{
		open( SECRET, Yaffas::Constant::FILE->{ldap_secret} )
			or throw Yaffas::Exception('err_read_file', Yaffas::Constant::FILE->{ldap_secret});
	}
	$pass = <SECRET>;
	chomp( $pass );
	close( SECRET );
	return $pass;
}

=over

=item get_bk_ldap_auth()

Returns a hash ref structure with with the auth information. The following keys are used:

 host
 base
 binddn
 bindpw

=back

=cut

sub get_bk_ldap_auth() {
	return undef unless -f Yaffas::Constant::FILE->{libnss_ldap_conf};
	my $file = Yaffas::File::Config->new( Yaffas::Constant::FILE->{libnss_ldap_conf},
											{
												-SplitPolicy => 'custom',
												-SplitDelimiter => '\s+'
											}
										);

	my %ret;
	my $cfg_v = $file->get_cfg_values();
    $ret{uri} = $cfg_v->{uri};
    if ($ret{uri}) {
        # make sure if we have localhost in uri that we get local authentication
        if ($ret{uri} =~ /(localhost|127\.0\.0\.1)/) {
            $ret{host} = "127.0.0.1";
        }
        else {
            if ($ret{uri} =~ m#^ldaps?://(.*)(:\d+)?\s+.*#) {
                $ret{host} = $1;
            }
        }
    }
    else {
        $ret{host} = $cfg_v->{base};
    }
	$ret{base} = $cfg_v->{base};
	$ret{binddn} = $cfg_v->{binddn};
	$ret{bindpw} = $cfg_v->{bindpw};

	$ret{userdn} = $cfg_v->{nss_base_passwd};
	$ret{userdn} =~ s/(.*),$/$1/;

	$ret{groupdn} = $cfg_v->{nss_base_group};
	$ret{groupdn} =~ s/(.*),$/$1/;
	
	my @hosts = split(/\s{0,}[;,\s\0]\s{0,}/, $ret{uri});
	foreach(@hosts) { $_ =~ s/ldaps?:\/\/// };
	
	$ret{hostlist} = \@hosts;

	$file = Yaffas::File::Config->new( Yaffas::Constant::FILE->{ldap_settings},
									   {
									   -SplitPolicy => 'custom',
									   -SplitDelimiter => '\s*=\s*'
									   }
									 );
	$cfg_v = $file->get_cfg_values();

	$ret{usersearch} = $cfg_v->{USERSEARCH};
	$ret{email} = $cfg_v->{EMAIL};
	$ret{uri} = $cfg_v->{LDAPURI};

	return \%ret;
}

=over

=item get_pdc_info()

If PDC authentication is configured, a hash, containing the options is returned. 
Otherwise you will get an emtpy hash.

Items of the hash:
host:	Name or IP of the domaincontroller
type: win or samba
domain:	domain

=back

=cut

sub get_pdc_info(){
	my $smb = File::Samba->new( Yaffas::Constant::FILE->{'smb_includes_global'} ) || return undef;
	$smb->version(3);

	my %info;
	if( lc($smb->globalParameter('security')) eq 'ads' || $smb->globalParameter('security') eq 'DOMAIN' ){
		$info{host} = $smb->globalParameter('password server');
		# filter the '*' entry (included in config file as recommended by samba docu)
		$info{host} =~ s/\s*,\s*\*//;
		$info{domain} = lc $smb->globalParameter('realm');
		$info{type} = (lc($smb->globalParameter('security')) eq 'ads') ? "win" : "samba";
	}
	if (lc($smb->globalParameter('passdb backend')) eq 'smbpasswd') {
		$info{backend} = 'smbpasswd';
	}
	return \%info;
}

=over

=item is_auth_srv()

Checks if Yaffas is configured to work as a authentication server.
Returns '1' if true, otherwise '0'

=back

=cut

sub is_auth_srv(){
	if( Yaffas::Product::check_product('auth') ) {
		return 1;
	}
	else {
		return 0;
	}
}

=over

=item get_ads_basedn( DCNAME, ATTRIBUTE )

returns BASEDN of ADS LDAP of the given ATTRIBUTE or undef on failure
  DCNAME is the hostname (must be known by DNS) of the domain controller
  ATTRIBUTE is the name of an ldapsearch attribute, if nothing is given "defaultNamingContext"

=back

=cut

sub get_ads_basedn($;$){
	my $uri = shift;
	my $attribute = shift;

	my $basedn = undef;

	$attribute = "defaultNamingContext" unless (defined($attribute));

	my @rv = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{ldapsearch},"-x","-b", '',"-s", "base", "-H", $uri);
	foreach (@rv) {
		if ( m/$attribute/) {
			$basedn = (split(/\s*:\s*/))[1];
			chomp($basedn);
			last;
		}
	}
	return $basedn;
}

=over

=item get_ads_userdn( DCNAME, DOMAINADMIN, ADMINPASS, USERNAME )

returns DN of an ADS user of which only the name is known or undef on failure
  DCNAME - Name or IP address of domain controller
  DOMAINADMIN - name of domain admin (I<not> the DN)
  ADMINPASS - password
  USERNAME - name of user

=back

=cut

sub get_ads_userdn($$$$){
	my ($uri, $admin, $pass, $user) = @_;
	my $userdn = undef;

	my $exception = Yaffas::Exception->new();
	$exception->add("err_admin_wrong", $admin) unless Yaffas::Check::pathetic_username($admin);
	$exception->add("err_user_wrong", $user) unless Yaffas::Check::pathetic_username($user);
	$exception->add("err_pass_wrong", $pass) unless Yaffas::Check::password($pass);
	throw $exception if( $exception );
	my $basedn = get_ads_basedn($uri);
	return undef unless defined $basedn;
	my $admindn = "cn=$admin,cn=Users,$basedn";
	my @rv = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{ldapsearch},"-D",$admindn,"-x","-b",$basedn,"-H", $uri,"-w",$pass,"(sAMAccountName=$user)");
	if ($? == 0) {
		foreach (@rv) {
			if ( m/dn/) {
				$userdn = (split /\s*:\s*/)[1];
				chomp($userdn);
				last;
			}
		}
	} else {
		my @re = Yaffas::do_back_quote_2(Yaffas::Constant::APPLICATION->{ldapsearch},"-D",$admindn,"-x","-b",$basedn,"-H", $uri,"-w",$pass,"(sAMAccountName=$user)");
		my $errorcode = undef;
		foreach (@re) {
			if (m/AcceptSecurityContext/) {
				m/data\s*([a-f0-9]+)/;
				$errorcode = $1;
				last;
			}
		}
		#back to DOS ;-)
		if ($errorcode eq "52e") {
			$exception->add("err_ads_pass",[$admindn, join("\n",@re)]);
		} elsif ($errorcode eq "525") {
			$exception->add("err_ads_dn",[$admindn, join("\n",@re)]);
		} else {
			$exception->add(join("\n",@re));
		}
	}
	throw $exception if $exception;
	return $userdn;
}

=over

=item is_local_files_only_auth()

returns 1 if the only Authentificationmethod is against local files, otherwise 0.

Note: this method only works on RedHat at the moment. On other systems it will always return 0.

=back

=cut

sub is_local_files_only_auth() {
	my $nsswitch_conf = Yaffas::File->new (Yaffas::Constant::FILE->{'nsswitch'});
	my $passwd_line = $nsswitch_conf->search_line ("^\\s*passwd:");
	my $passwd = $nsswitch_conf->get_content ($passwd_line);

	$passwd =~ m/^\s*passwd:\s*(.*)\s*$/;
	my @ns = split /\s+/, $1;
	return 1 unless grep { $_ ne 'files' && $_ ne 'compat' } @ns;
	return 0;
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
