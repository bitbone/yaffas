#!/usr/bin/perl -w

package Yaffas::Check;

use Yaffas::Constant;
use strict;

# prototyes
sub username($);
sub groupname(@);
sub gecos($);
sub email($);
sub domainname($);
sub hostname ($);
sub password($);
sub alpha_num($);
sub ip($;$$);
sub filename($);
sub file_permissions($);
sub msn($);
sub ldap_msn($);
sub long_msn($);
sub dn($);
sub faxtype();
sub workgroup($);


=head1 NAME

Yaffas::Check - Functions for checking values

=head1 SYNOPSIS

use Yaffas::Check

=head1 DESCRIPTION

Yaffas::Check provides fuctions for checking values.

=head1 FUNCTIONS

=over

=item pathetic_username ( USERNAME )

does a simple check if the username contains only non harmfull chars.

=cut

sub pathetic_username ($) {
	my $username = shift;
	return undef if (length($username) > 1024);

	foreach (split(//, $username)) {
		my $ord = ord;
		return undef if($ord < 0x21 or $ord > 0x7d); # normaler buchstaben (druckbarer) bereich
		return undef if($ord == 0x22); # "
		return undef if($ord == 0x23); # #
		return undef if($ord == 0x27); # '
		return undef if($ord == 0x60); # `
	}
	1;
}

=item faxtype ( )

Check if which faxtype is installed.
Returns CAPI or EICON

=cut

sub faxtype()
{
	return ( -d Yaffas::Constant::DIR->{'divasdir'}) ? "EICON" : "CAPI";
}

=item username ( USERNAME )

Check if USERNAME contains only valid characters

=cut

sub username($) {
	my $login = $_[0];
	return undef if (length($login) > 1024);
	#this can be used, once uppercase letters are allowed again
	#if ( (length($login) > 0) && $login =~ m/^[a-zA-Z][a-zA-Z0-9\-\.]*[a-zA-Z0-9]+$/) {
	if ( (length($login) > 0) &&
			$login =~ m/^[a-z]($|[a-z0-9\-\.]*[a-z0-9]+)$/) {
		return 1;
	} else {
		return 0;
	}
}

=item groupname ( GROUPS )

Checks if all groups or groupids in array GROUPS are valid.

=cut

sub groupname(@) {
	foreach my $group (@_) {
		return 1 if grep {$group eq $_} @{Yaffas::Constant::MISC->{admin_groups}};
		if ($group !~ /^[a-zA-Z][a-zA-Z0-9\._-]*$/g ||length($group) <= 0 || length($group) > 1024) {
			return 0;
		}
	}
	return 1;
}

=item gecos( GECOS )

=cut

sub gecos($) {
        my $geco = shift;
        if ( defined($geco) ) {
                return undef if (length($geco) > 1024);
                if($geco =~ m/^[^\x00-\x1f\x7f!"#\$%&'\*\/\\:]+$/) {
                        return 1;
                } else {
                        return 0;
                }
        } else {
                return 0;
        }
}

=item email ( EMAILADRESS )

It simply checks the EMAILADRESS. It returns 1 if EMAILADRESS is valid, else 0.

=cut

sub email($) {
        my $mail = shift;
        my $domain;
        return 0 unless defined $mail;
        return undef if (length($mail) > 1024);

        if ($mail =~ m/^[a-zA-Z0-9\.\-\_]+\@([a-zA-Z0-9\.\-\_]+)$/) {
                $domain = $1;
                if ($domain eq "localhost" or $domain =~ /\./) {
                        return 1;
                }
                return 0;
        } else {
                return 0;
        }
}

=item domainname ( DOMAINNAME  )

Checks if the DOMAINNAME is valid. undef is returned on non valid names, 1 if the name is valid.
Domains are defined in RFC1035 section "2.3.1 Preferred name syntax"

=cut

sub domainname ($){
        my $domainname = shift;
        return undef unless defined $domainname;
        return undef if (length($domainname) > 1024);
        return undef unless $domainname =~ m/^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$/;
        return 1;
}

=item hostname ( HOSTNAME )

Check if HOSTNAME is valid. Returns 1 on a valid HOSTNAME, else undef.

=cut

sub hostname ($) {
        my $hostname = shift;
        return undef unless defined($hostname);

        return undef unless $hostname =~ m/^[a-zA-Z0-9][-a-zA-Z0-9]*[a-zA-Z0-9]$/;
        return undef if (length($hostname) > 1024);
		return undef if ($hostname !~ m/[a-zA-Z]+/);
        return 1;
}

=item smarthost ( HOSTNAME )

Check if the given string is a valid smarthost for usage in Postfix.
Returns 1 on a valid value, else undef.

=cut

sub smarthost($) {
	my $value = shift;

	# strip off any valid port definition at the end (just for the check)
	$value =~ s/:\d+\Z//;

	# strip off any sorrounding [...]s (just for the check)
	$value =~ s/^\[(.*)\]\Z/$1/;

	# now check if the left-over is a valid ip or hostname
	return 1 if ip($value);
	return 1 if domainname($value);
	return undef;
}


=item password ( PASSWORD )

Checks if a passwordstring is valid. Returns 1 if password is valid else undef.

=cut

sub password ($) {
        my $pass = shift;
        return undef if (length($pass) > 1024);
        return undef if $pass =~ m/\n/;
        return undef if $pass =~ m/#/;
        return 1 if (defined($pass) && length($pass) > 0);
        return undef;
}

=item  is_localhost (LOCALHOST )

Checks if a given string is localost.  Returns 1 if the string is localhost else undef.

=cut

sub is_localhost($){
        if (($_[0] eq 'localhost') or ($_[0] eq '127.0.0.1')){
                return 1;
        }
        return undef;
}


=item alpha_num ( VALUE )

Checks if value is alpha numeric (a-zA-Z0-9)

=cut

sub alpha_num($) {
        my $value = shift;
        return ($value =~ /^[a-zA-Z0-9]+$/ ? 1 : undef);
}

=item port ( PORT )

Checks if the PORT is a valid port for TCP or UDP;

=cut

sub port ($){
	my $port = shift;
	return undef unless $port =~ /^\d+$/;
	return undef if $port < 1;
	return undef if $port >= 65536;
	1;
}

=item ip ( IP [NETMASK [TYPE]] )

If NETMASK is omitted it does just a simple check if the IP is in the correct
range. If you suply the NETMASK it checks if the IP is in the Subnet specified
by the NETMASK. The NETMASK can be in short form ( e.g. "24" ) or in the long
form ( e.g. "255.255.255.0" ).

TYPE can be:

=over

=item "netaddr"

for netadresses like 192.168.5.0

=item "broadcast"

for broadcast ips like 255.255.255.0

=item "multicast"

for muticast adresses. Also known as Class D adresses. 224.0.0.0 - 239.255.255.255

=item "classe"

for class E adresses. 240.0.0.0 to 247.255.255.255

=item "others"

for all classes behind Class E: 248.0.0.0 - 255.255.255.255

=item "loopback"

for ip between 127.0.0.0 and 127.255.255.255

=back

There is a simple test suite in the SVN, B<PLEASE> run all the tests if
you change the check_ip subroutine since the subroutine is not that easy

=cut

sub ip($;$$) {
    ## viel code der sub ips_in_same_netz() geliehen, sollten fehler auftreten bitte die andere funktion auch überprüfen.
    my $ip = shift;
    my $mask = shift;
    my $type = shift;
    return 0 if (! defined $ip);

    if ($ip =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
        ( $1 >= 0 && $1 <= 255 ) && ( $2 >= 0 && $2 <= 255 ) &&
        ( $3 >= 0 && $3 <= 255 ) && ( $4 >= 0 && $4 <= 255 )
       ) {
        if (defined $mask) {
            my $ipstring = sprintf("%08b", $1) . sprintf("%08b", $2) . sprintf("%08b", $3) . sprintf("%08b", $4);

            if ($mask =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
                ( $1 >= 0 && $1 <= 255 ) && ( $2 >= 0 && $2 <= 255 ) &&
                ( $3 >= 0 && $3 <= 255 ) && ( $4 >= 0 && $4 <= 255 )
               ) {
                ## long mask mode
                my $maskstring = sprintf("%08b", $1) . sprintf("%08b", $2) . sprintf("%08b", $3) . sprintf("%08b", $4);
                if ($maskstring =~ m/^(1+)0+$/ ) {
                    $mask = length($1);
                } else {
                    return 0;   ## maks nicht okee
                }
            }

            if ($mask == 0 or $mask == 32) {
                return 0; # 0.0.0.0 und 255.255.255.255 sind nicht erlaubt als masken.
            }

            #           print $ipstring;
            #           print " - ", $mask;

            my $end = 32 - $mask;
            if ($ipstring =~ /(\d{$mask})(\d{$end})/ ) {
                my $ipend = $2;
                my $netzanteil = $1;

                if ($netzanteil =~ /^1+$/) {
                    ## netzanteil darf nicht aus nur 1 bestehn
                    return 0;
                }


                if (defined($type) and ($type eq "netaddr") ) {
                    if ($ipend =~ /^0+$/) {
                        return 1; ## netzadresse erkannt
                    } else {
                        return 0;
                    }
                } elsif (defined($type) and ($type eq "broadcast")) {
                    if ($ipend =~/^1+$/) {
                        return 1 ## boardcast erkannt;
                    } else {
                        return 0;
                    }
                } elsif (defined($type) and ($type eq "loopback")) {
                                        # loopback sind alle 127.x.x.x adressen.
                    if ($ipstring =~/^01111111/) {
                                                return 1;
                    } else {
                        return 0;
                    }
                } else {        ## ip
                    if ($ipend =~ /^0+$/ or $ipend =~ /^1+$/) {
                        return 0; ## netzadresse oder broadcast erkannt
                    } else {
                        if ($ip =~ /^(\d+)\./ ) {
                            my $okt1 = $1;

                            if ($okt1 == 0) {
                                return 0; # reseviertes netz!
                            }

                            if ($okt1 == 127) {
                                return 0; # loopback adressen
                            }

                            if ( $okt1 <= 223) {
                                return 1 unless defined $type;
                                return 0;
                            }

                            # 224.0.0.0 - 239.255.255.255
                            if (224 <= $okt1 and $okt1 <= 239) {
                                return 1 if ( defined( $type ) and $type eq "multicast");
                                return 0;
                            }

                            # 240.0.0.0 bis 247.255.255.255
                            if (240 <= $okt1 and $okt1 <= 247) {
                                return 1 if (defined( $type ) and $type eq "classe");
                                return 0;
                            }

                            # 248.0.0.0 bis 255.255.255.255
                            # so ganz richitg is das nicht...
                            if ($okt1 >= 248) {
                                return 1 if (defined( $type ) and $type eq "others");
                                return 0;
                            }
                        }
                        return 1;
                    }
                }
            } else {
                return 0; ## ka wann dasss erreicht wrid, aber wenn regex nicht trifft, ip falsch.
            }
        } else {
            return 1;
        }
    } else {
        return 0;
    }
    return 0;
}

=item ips_in_same_net( IP1 IP2 NETMASK)

checks if the IP1 and IP2 are in the same network subnet.

=cut

sub ips_in_same_net($$$) {
    ## viel code von der sub ip() geklaut, sollten fehler auftreten bitte die andere funktion auch überprüfen.

    my $ip1  = shift;
    my $ip2  = shift;
    my $mask = shift;

    my $ip1_str;
    my $ip2_str;
    my $netz1_anteil;
    my $netz2_anteil;

    if ($ip1 =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
        ( $1 >= 0 && $1 <= 255 ) && ( $2 >= 0 && $2 <= 255 ) &&
        ( $3 >= 0 && $3 <= 255 ) && ( $4 >= 0 && $4 <= 255 )
       ) {
            $ip1_str = sprintf("%08b", $1) . sprintf("%08b", $2) . sprintf("%08b", $3) . sprintf("%08b", $4);
	}else{
	    return 0;
	}


    if ($ip2 =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
        ( $1 >= 0 && $1 <= 255 ) && ( $2 >= 0 && $2 <= 255 ) &&
        ( $3 >= 0 && $3 <= 255 ) && ( $4 >= 0 && $4 <= 255 )
       ) {
            $ip2_str = sprintf("%08b", $1) . sprintf("%08b", $2) . sprintf("%08b", $3) . sprintf("%08b", $4);
	}else{
	    return 0;
	}

    if ($mask =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
	( $1 >= 0 && $1 <= 255 ) && ( $2 >= 0 && $2 <= 255 ) &&
	( $3 >= 0 && $3 <= 255 ) && ( $4 >= 0 && $4 <= 255 )
       ) {
	## long mask mode
	my $maskstring = sprintf("%08b", $1) . sprintf("%08b", $2) . sprintf("%08b", $3) . sprintf("%08b", $4);
	if ($maskstring =~ m/^(1+)0+$/ ) {
	    $mask = length($1);
	} else {
	    return 0;   ## mask nicht okee
	}
    }

    my $end = 32 - $mask;

    if ($ip1_str =~ /(\d{$mask})\d{$end}/ ) {
	$netz1_anteil = $1;
    }

    if ($ip2_str =~ /(\d{$mask})\d{$end}/ ) {
	$netz2_anteil = $1;
    }

    return 1 if($netz1_anteil eq $netz2_anteil);
    return 0;
}


=item filename ( FILENAME )

filename tests if the FILENAME is valid or not.

=cut

sub filename ($){
        my $file = shift;

        # erlaubt sollen sein alle buchstaben, ziffern, - _ .
        # nicht erlaubt sein sollen ins besondere sonderzeichen der bash. ? * ~ #
        # nicht erlaubt sein sollten datein, die mit einem . beginnen.
        # nicht erlaubt ist inbesondere .. und . als filename

        if($file =~ m/\/\./) {
            return 0;
        }
        if($file !~ m/^[\/\w][\/\w\.-]*[\w\.-]$/) {
            return 0;
        }
        return 1;
}

=item mailbox ( MAILBOX )

checks if MAILBOX is valid

=cut

sub mailbox($) {
	my $mailbox = shift;
	return undef if (length($mailbox) > 1024);
	return undef if ($mailbox =~ /\/\//);
	return undef if ($mailbox =~ /\/$/);
	return $mailbox =~ /^[a-zA-Z0-9-][a-zA-Z0-9-\/]+$/;
}

=item alias ( ALIAS )

checks if given ALIAS is valid

=cut

*alias = \*email;

=item file_permissions ( PERMISSIONS )

checks if the permissions are valid

=cut

sub file_permissions($){
        my $permissions = shift;
        return( ($permissions =~ m/^[0-7]{3,4}$/) );
}

=item msn ( MSN )

checks if given MSN is valid

=cut

sub msn($)
{
	my $msn = shift;
	return $msn =~ m/^\d+$/;
}

=item ldap_msn ( LDAP_MSN )

DEPRECATED! Use long_msn($)!

=cut

sub ldap_msn($)
{
	long_msn(shift);
}

=item long_msn ( LONG_MSN )

checks if given LONG_MSN is valid
LONG_MSN is like MSN_CTRL_(BC)?

=cut

sub long_msn($)
{
	my $long_msn = shift;

	if (Yaffas::Check::faxtype() eq "CAPI")
	{
		return $long_msn =~ m/^\d+_\d+_\d$/;
	}
	else
	{
		return $long_msn =~ m/^\d+_\d+$/;
	}
}

=item ldap_msn ( LDAP_MSN )

see http://www.ietf.org/rfc/rfc2253.txt (3. Parsing a String back to a Distinguished Name)
for details.
checks if given LDAP_MSN is valid

=cut

sub dn($)
{
	my $dn = shift;

	my $special = ",=+<>#;";
	my $hex = "A-Fa-f0-9";

	foreach my $minidn (split(/,/, $dn))
	{
		if ($minidn =~ m/^(([a-zA-Z0-9]+[a-zA-Z0-9\-]*)|([0-9]{1}(\.[0-9])*))=(([^${special}\\"]+|(\\([${special}]{1}|\\|\"|[${hex}]{2}))+)|(#([${hex}]{2})+)|(\"([^\"\\]|(\\([${special}]{1}|\\|\"|[${hex}]{2})))+\"))$/)
		{
			#print "$minidn - okay\n";
		}
		else
		{
			return undef;
		}
	}
	return 1;
}

=item B<workgroup( WORKGROUP )>

This routine checks if the given workgroup name is valid. It will return 1
on success, otherwise undef.

=cut

sub workgroup($) {
	my $wg = shift;

	return undef unless $wg;
	return undef unless $wg =~ m/^[a-zA-Z0-9._\-]+$/;

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
