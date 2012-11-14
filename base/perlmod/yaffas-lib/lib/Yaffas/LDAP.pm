#!/usr/bin/perl -w
package Yaffas::LDAP;
use strict;
use vars qw($Error);
use Yaffas::Constant;
use Yaffas::UGM;
use Yaffas::File;
use Yaffas::File::Config;
use Net::LDAP;
use Data::Dumper;
use MIME::Base64;

## prototypes ##
sub get_passwd ();
sub get_domain ();
sub dn_to_name ($);
sub get_host ();
sub search_entry($$;$);
sub search_attributes_entries($$;$);
sub search_anon_entry($$;$);
sub replace_entry($$$;$);
sub replace_entries($$;$);
sub add_entry($$$;$);
sub del_entry($$;$);
sub del_value($$$;$);

=head1 NAME

Yaffas::LDAP - LDAP Functions

=head1 SYNOPSIS

use Yaffas::LDAP

=head1 DESCRIPTION

Yaffas::LDAP provides functions to access LDAP

=head1 FUNCTIONS

=over

=item get_passwd ()

returns the LDAP passwd from "/etc/libnss-ldap.conf" or undef on error

=cut

sub get_passwd () {
	my $bkcf = Yaffas::File->new(Yaffas::Constant::FILE->{ldap_conf});

	my @content = $bkcf->get_content();

	my $pwd;
	foreach my $line (@content) {
		if ($line =~ /^\s*bindpw\s+(.*)$/) {
			$pwd = $1;
		}
	}
	return $pwd;
}

=item get_domain ()

returns the domain name in a LDAPish way, or undef on error.

=cut

sub get_domain () {
#	my $domain = `hostname -d`;
#	return undef if($?);
#	chomp($domain);
#	my @tmp = split(/\./, $domain);
#	my $subdomains = "ou=" . join( ",ou=", @tmp[0..$#tmp-2] );
#	my $r = "o=" . $tmp[-2] . ",c=" . $tmp[-1];
#	$r = $subdomains . "," . $r if $tmp[2];

#	can now be an remote ldap server. lets get data out of conf
	my $conf = Yaffas::File::Config->new( Yaffas::Constant::FILE()->{smbldap_conf},
										  {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*'
										  }
										 );
	my $domain = $conf->get_cfg_values()->{suffix};

	# trimm
	$domain =~ s/^"*//;
	$domain =~ s/"*$//;

	if( defined $domain) {
	    $domain =~ /(.*)/ and $domain = $1;
	}

	return (defined $domain) ? $domain : undef;
}

=item get_local_domain()

Returns the local domain like get_domain()

=cut

sub get_local_domain() {
	my $conf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{slapd_conf},
										  {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s+'
										  }
										 );

	my $domain = $conf->get_cfg_values()->{suffix};

	if ($domain =~ /^\s*"?(.*)"?\s*$/) {
		return $1;
	} else {
		return undef;
	}
}

=item dn_to_name( DN )

converts ldap BASEDN to sytem DN
e.g ou=bitbone,c=de to bitbone.de

=cut

sub dn_to_name($)
{
        my $dn = shift;
        return undef unless (defined $dn);

        my $dom = "";
        foreach ( split(/,/,$dn) )
        {
                my $dn_part = $_;
                $dn_part =~ s/^[^=]+=//;
                $dom .= "${dn_part}."
        }
        $dom =~ s/\.$//;

        return (defined ($dom)) ? $dom : undef;
}


=item get_host ()

returns the host, or undef on error.

=cut

sub get_host () 
{
	my $conf = Yaffas::File::Config->new( Yaffas::Constant::FILE()->{smbldap_conf},
										  {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*'
										  }
										 );
	my $host = $conf->get_cfg_values()->{masterLDAP};

	if( defined $host) {
		# trimm
		$host =~ s/^"*//;
		$host =~ s/"*$//;

		$host =~ /(.*)/ and $host = $1;
	}

	return (defined $host) ? $host : undef;
}

=item get_ldap_uri ()

returns an array reference of ldap uris from /etc/ldap.settings

=cut

sub get_ldap_uri ()
{
	my $ls_file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'ldap_settings'},
                        {
                                        -SplitPolicy => 'custom',
                                        -SplitDelimiter => '\s*=\s*',
                                        -StoreDelimiter => '=',
                        }) or die "could not open " . Yaffas::Constant::FILE->{'ldap_settings'} . " $!";
    my $ls_ref = $ls_file->get_cfg_values();
    my $ldapuri = $ls_ref->{'LDAPURI'};
    my @uris = split(/ /, $ldapuri);
    return \@uris;
}

=item search_entry (FILTER, ATTRIB, [ORG_UNIT])

searches in LDAP-Tree.
FILTER (e.g. uid = mueller).
ATTRIB (e.g. eMail).
ORG_UNIT (e.g. Group) default "People".
returns array of values...

e.g. Yaffas::LDAP::search_entry("uid=mbarth", "sn");

=cut

sub search_entry($$;$)
{
        my $filter = shift;
        my $attribut = shift;
        my $ou = shift;

        my ($domain, $passwd, $ldap, @values);

        $ou = "People" unless $ou;
        _init(\$domain, \$passwd, \$ldap);

        my $result = $ldap->search(
                        base =>  "ou=$ou,$domain" ,
                        filter => $filter,
                        attrs => [$attribut]
                        );

        $result->code && warn "failed to search entry: ", $result->error;

        for my $i(0..$result->count()-1 ) {
                my $entry = $result->entry($i);
                push @values, map{$entry->get_value($_)} $entry->attributes;
        }

        $ldap->unbind;
        return @values;
}

sub search_entry_dn($$;$)
{
        my $base = shift;
        my $attribut = shift;
        my $filter = shift;

        my ($domain, $passwd, $ldap, @values);

        $filter = "(mail=*)" unless $filter;
        _init(\$domain, \$passwd, \$ldap);

        my $result = $ldap->search(
                        base => $base,
                        filter => $filter,
                        attrs => [$attribut]
                        );

        $result->code && warn "failed to search entry: ", $result->error;

        for my $i(0..$result->count()-1 ) {
                my $entry = $result->entry($i);
                push @values, map{$entry->get_value($_)} $entry->attributes;
        }

        $ldap->unbind;
        return @values;
}

=item search_attributes_entries (FILTER, ATTRIBUTES, [ORG_UNIT]=

searches in LDAP-Tree
FILTER (e.g. uid = mueller).
ATTRIBUTES array ref  (e.g. ["eMail", "sn", "uidNumber"]).
ORG_UNIT (e.g. Group) default "People".

returns an array of hash references

=cut

sub search_attributes_entries($$;$) {
        my $filter = shift;
        my $attribut = shift;
        my $ou = shift;

        unless(ref($attribut) eq "ARRAY") {
            $attribut = [$attribut];
        }

        my ($domain, $passwd, $ldap, @values);

        $ou = "People" unless $ou;
        _init(\$domain, \$passwd, \$ldap);

        my $result = $ldap->search(
                        base =>  "ou=$ou,$domain" ,
                        filter => $filter,
                        attrs => $attribut
                        );

        $result->code && warn "failed to search entry: ", $result->error;

        for my $i(0..$result->count()-1 ) {
                my $entry = $result->entry($i);
                my $attrs = {};
                foreach my $attr($entry->attributes) {
                    $attrs->{$attr} = $entry->get_value($attr, asref => 1);
                }
                push @values, $attrs;
        }

        $ldap->unbind;
        return @values;
}

=item search_anon_entry (FILTER, ATTRIBUTES, [ORG_UNIT])

searches in LDAP-Tree. Dont bind as ldapadmin user. Do an anon search.
FILTER (e.g. uid = mueller).
ATTRIB (e.g. eMail).
ORG_UNIT (e.g. Group) default "People".
returns array of values...

e.g. Yaffas::LDAP::search_entry("uid=mbarth", "sn");

=cut

sub search_anon_entry($$;$)
{
        my $filter = shift;
        my $attribut = shift;
        my $ou = shift;

        my ($domain, $ldap, @values);

        $ou = "People" unless $ou;
        unless(_anon_init(\$domain, \$ldap)) {
            return ();
        }

        my $result = $ldap->search(
                        base =>  "ou=$ou,$domain" ,
                        filter => $filter,
                        attrs => [$attribut]
                        );

        $result->code && warn "failed to search entry: ", $result->error;

        for my $i(0..$result->count()-1 ) {
                my $entry = $result->entry($i);
                push @values, map{$entry->get_value($_)} $entry->attributes;
        }

        $ldap->unbind;
        return @values;
}

=item replace_entry ( LOGIN, ATTRIB, VALUE, [ORG_UNIT] )

Replaces a VALUE in ATTRIB at ORG_UNIT=LOGIN in the LDAP tree. Returns resultcode which are described in L<Net::LDAP::Constant>.
If ORG_UNIT is omitted "People" is used.

e.g. Yaffas::LDAP::replace_entry("mbarth", "sn", "asdf");

=cut

sub replace_entry($$$;$) {
	my $login = shift;
	my $attribut = shift;
	my $value = shift;
	my $ou = shift;

	my ($domain, $passwd, $ldap, $uid);

	($uid, $ou) = (defined $ou) ? ("cn", $ou) : ("uid", "People");
	_init(\$domain, \$passwd, \$ldap);

	my $result = $ldap->modify("$uid=$login,ou=$ou,$domain", changes=> [
			replace=> [ $attribut => $value ]
			]);
	

	my $r = $result->code;
	warn "failed to replace entry: " . $result->error if ($r);
	$ldap->unbind;
	return $r;
}

=item replace_entries ( LOGIN, CHANGES, [ORG_UNIT] )

Works neaerly the same way like replace_entry(), but you'll have to pass the array reference CHANGES.
Have a look at Net::LDAP::modify for examples of the CHANGES structure.

Example: Yaffas::LDAP::replace_entries("sepp", [add => [faxNumber=>42], delete => [mail=>[]]])

=cut

sub replace_entries($$;$)
{
    my $login = shift;
    my $changes = shift;
    my $ou = shift;

    my ($domain, $passwd, $ldap, $uid);

    ($uid, $ou) = (defined $ou) ? ("cn", $ou) : ("uid", "People");
    _init(\$domain, \$passwd, \$ldap);

    my $result = $ldap->modify("$uid=$login,ou=$ou,$domain", changes=>$changes);

    my $r = $result->code;
    warn "failed to replace entry: " . $result->error if ($r);
    $ldap->unbind;
    return $r;
}

=item add_entry ( LOGIN, ATTRIB, VALUE, [ORG_UNIT] )

Adds an entry with ATTRIB and VALUE at ORG_UNIT=LOGIN. If ORG_UNIT is omitted "People" is used.
Returns resultcode which are described in L<Net::LDAP::Constant>.

e.g. Yaffas::LDAP::add_entry("mbarth", "email", "barth@bitbone.de");

=cut

sub add_entry($$$;$) {
	my $login = shift;
	my $attribut = shift;
	my $value = shift;
	my $ou = shift;

	my ($domain, $passwd, $ldap, $uid);

	($ou, $uid) = (defined $ou) ? ("Group", "cn") : ("People", "uid");
	_init(\$domain, \$passwd, \$ldap);

	my $result = $ldap->modify("$uid=$login,ou=$ou,$domain", changes=> [
			add=> [ $attribut => $value ]
			]);

	my $r = $result->code;
	warn "failed to add entry:" . $result->error if $r;
	$ldap->unbind;
	return $r;

}

=item del_entry ( LOGIN, ATTRIB, ORG_UNIT )

Removes entry with ATTRIB at ORG_UNIT=LOGIN. If ORG_UNIT is omitted, "People" is used.
Returns resultcode which are described in L<Net::LDAP::Constant>.

e.g. Yaffas::LDAP::del_entry("mbarth", "email");

=cut

sub del_entry ($$;$) {
    my $login = shift;
    my $attribut = shift;
    my $ou = shift;

    my ($domain, $passwd, $ldap, $uid);

    ($uid, $ou) = (defined $ou) ? ("cn", $ou) : ("uid", "People");
    _init(\$domain, \$passwd, \$ldap);

    my $result = $ldap->modify("$uid=$login,ou=$ou,$domain", changes=> [
                                                                        delete=> [ $attribut => [] ]
                                                                       ]);

    my $r = $result->code;
    print "failed to delete entry:" . $result->error if $r;
    $ldap->unbind;

    return $r;
}

=item search_user_by_attribute (ATTRIBUTE, AVALUE )

returns users that match the given attribute

	ATTRIBUTE - attribute to search
	ATTRIBUTE VALUE - value to match

=cut

sub search_user_by_attribute($$) {
	my ($attribute, $avalue) = @_;
	my @return_users = ();

	my $ls_file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'ldap_settings'},
						{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => '=',
						}) or die "could not open " . Yaffas::Constant::FILE->{'ldap_settings'} . " $!";
	my $ls_ref = $ls_file->get_cfg_values();
	my $ldapuri = $ls_ref->{'LDAPURI'};
	my $binddn = $ls_ref->{'BINDDN'};
	my $searchbase = $ls_ref->{'USER_SEARCHBASE'};
	$searchbase = $ls_ref->{'BASEDN'} if (!defined $searchbase || (length $searchbase) < 1);
	my $namefilter = $ls_ref->{'USERSEARCH'};
	my $ldapsecret = $ls_ref->{'LDAPSECRET'};

	unless (defined $ldapuri && defined $binddn && defined $searchbase && defined $namefilter && defined $ldapsecret) {
		return;
	}

	$ldapuri = $1 if ($ldapuri =~ /^(ldaps?:\/\/.*)$/);
	$binddn = $1 if ($binddn =~ /^(.*)$/);
	$searchbase = $1 if ($searchbase =~ /^(.*)$/);
	$namefilter = $1 if ($namefilter =~ /^(\w*)$/);
	$ldapsecret = $1 if ($ldapsecret =~ /^(.*)$/);
	if ($attribute =~ m/e?mail/i) {
		$attribute = $ls_ref->{'EMAIL'};
	}
	$attribute = $1 if ($attribute =~ /^(\w*)$/);

	@return_users = Yaffas::do_back_quote(
		Yaffas::Constant::APPLICATION->{'ldapsearch'},
		"-H", $ldapuri, "-x", "-D", $binddn, "-b", $searchbase,
		"($attribute=$avalue)", $namefilter, "-w", $ldapsecret, "-LLL"
		);
	return (map {s/$namefilter:\s*//i;chomp; $_} grep(/$namefilter:\s*/i,@return_users));
}

=item search_attribute ( TYPE, NAME,[ ATTRIBUTE ] )

returns attribute for given user, group or for all users in group

It does I<not> return group attributes!

	TYPE - must be user, group, grouponly
	NAME - user's or group's name
	ATTRIBUTE - attribute to search (mail, if omitted; mail also is special, see /etc/ldap.settings)

=cut

sub search_attribute($$;$) {
	my ($type,$name,$attribute) = @_;
	my @return_attribs = ();

	my $ls_file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'ldap_settings'},
						{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => '=',
						}) or die "could not open " . Yaffas::Constant::FILE->{'ldap_settings'} . " $!";
	my $ls_ref = $ls_file->get_cfg_values();
	my $ldapuri = $ls_ref->{'LDAPURI'};
	my $binddn = $ls_ref->{'BINDDN'};
	my $user_searchbase = $ls_ref->{'USER_SEARCHBASE'};
	my $group_searchbase = $ls_ref->{'GROUP_SEARCHBASE'};
	$user_searchbase = $ls_ref->{'BASEDN'} if ((length $user_searchbase) < 1);
	$group_searchbase = $ls_ref->{'BASEDN'} if ((length $group_searchbase) < 1);
	my $namefilter = $ls_ref->{'USERSEARCH'};
	my $ldapsecret = $ls_ref->{'LDAPSECRET'};

	$ldapuri = $1 if ($ldapuri =~ /^(ldaps?:\/\/.*)$/);
	$binddn = $1 if ($binddn =~ /^(.*)$/);
	$user_searchbase = $1 if ($user_searchbase =~ /^(.*)$/);
	$namefilter = $1 if ($namefilter =~ /^(\w*)$/);
	$ldapsecret = $1 if ($ldapsecret =~ /^(.*)$/);
	$name = $1 if ($name =~ /^(.*)$/);
	if ((!defined $attribute) || ($attribute =~ m/e?mail/i)) {
		$attribute = $ls_ref->{'EMAIL'};
	}
	$attribute = $1 if ($attribute =~ /^(\w*)$/);

	if ($type eq "user") {
		@return_attribs = Yaffas::do_back_quote(
			Yaffas::Constant::APPLICATION->{'ldapsearch'},
			"-H", $ldapuri, "-x", "-D", $binddn, "-b", $user_searchbase,
			"($namefilter=$name)", $attribute, "-w", $ldapsecret, "-LLL"
			);
	} elsif ($type eq "group") {
		my @users = Yaffas::UGM::get_users($name);
		foreach my $user (@users) {
			push @return_attribs, Yaffas::do_back_quote(
				Yaffas::Constant::APPLICATION->{'ldapsearch'},
				"-H", $ldapuri, "-x", "-D", $binddn, "-b", $user_searchbase,
				"($namefilter=$user)", $attribute, "-w", $ldapsecret, "-LLL"
				);
		}
	} elsif ($type eq "grouponly") {
		@return_attribs = Yaffas::do_back_quote(
			Yaffas::Constant::APPLICATION->{'ldapsearch'},
			"-H", $ldapuri, "-x", "-D", $binddn, "-b", $group_searchbase,
			"(cn=$name)", $attribute, "-w", $ldapsecret, "-LLL"
			);
    } else {
		die "unsupported value $type";
	}
	return (map {s/$attribute:\s*//i; if (/^: /) { s/^: (.*)/$1/; $_ = decode_base64($_) }; chomp; $_} grep(/$attribute:\s*/i,@return_attribs));
}

=item del_value ( LOGIN, ATTRIB, VALUE, ORG_UNIT )

Removes VALUE from ATTRIB at ORG_UNIT=LOGIN. If ORG_UNIT is omitted "People" is used.
Returns resultcode which are described in L<Net::LDAP::Constant>.

e.g. Yaffas::LDAP::del_value("mbarth", "email", "barth@bitbone.de");

=cut

sub del_value ($$$;$) {
    my $login = shift;
    my $attribut = shift;
    my $value = shift;
    my $ou = shift;

    my ($domain, $passwd, $ldap, $uid);

    ($uid, $ou) = (defined $ou) ? ("cn", $ou) : ("uid", "People");
    _init(\$domain, \$passwd, \$ldap);

    my $result = $ldap->modify("$uid=$login,ou=$ou,$domain", changes=> [
                                                                        delete=> [ $attribut => ["$value"] ]
                                                                       ]);

    my $r = $result->code;
    print "failed to delete entry:" . $result->error if $r;
    $ldap->unbind;
    return $r;
}

sub _init($$$) {
        my $domain = shift;
        my $passwd = shift;
        my $ldap = shift;

        $$domain = get_domain();
        $$passwd = &get_passwd();
        #$$ldap = Net::LDAP->new(get_host(), port => 389);
        $$ldap = Net::LDAP->new(get_ldap_uri());
        $$ldap->bind("cn=ldapadmin,ou=People," . $$domain , password => $$passwd);
}

sub _anon_init($$) {
        my $domain = shift;
        my $ldap = shift;

        $$domain = get_domain();
        #$$ldap = Net::LDAP->new(get_host());
        $$ldap = Net::LDAP->new(get_ldap_uri());
        if(defined $$ldap) {
            $$ldap->bind();
            return 1;
        }
        else {
            return 0;
        }
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
