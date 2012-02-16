#!/usr/bin/perl -w

use lib '/opt/yaffas/lib/perl5';
use Yaffas::Constant;
use Yaffas::Service qw(control LDAP NSCD NSLCD STOP START RESTART);

my @ldap_conffiles = (
	"/etc/pam_ldap.conf",
	"/etc/libnss-ldap.conf",
	"/etc/ldap/slapd.conf",
	"/etc/openldap/slapd.conf",
	"/etc/ldap/ldap.conf",
	"/etc/smbldap-tools/smbldap.conf",
	"/etc/samba/smb.conf",
	"/etc/smbldap-tools/smbldap_bind.conf",
	"/var/lib/opengroupware.org/.libFoundation/Defaults/NSGlobalDomain.plist",
	"/etc/zarafa/ldap.cfg",
	"/etc/zarafa/ldap.yaffas.cfg",
	"/etc/ldap.settings",
	"/etc/ldap.conf",
	"/etc/nslcd.conf",
	"/etc/postfix/ldap-users.cf",
	"/etc/postfix/ldap-aliases.cf",
);
my @other_conffiles = ("/etc/hosts", "/etc/defaultdomain");
my $old_domain;
my $old_org;
my $new_domain;
my $new_org;
my $ldif_file = "";
my $upgrade;

sub usage() {
	print "Usage: domrename.pl <old domain> <new domain> [<ldif file>] [upgrade]\n";
	print "Note: if <ldif file> is specified only /tmp/slapcat.ldif will be changed\n";
	exit(-1);
}

if (defined($ARGV[0]) && ! defined($ARGV[1])) {
	usage();
} elsif (defined($ARGV[0]) && defined($ARGV[1]) && ! defined($ARGV[2])) {
	$old_domain = $ARGV[0];
	$new_domain = $ARGV[1];
} elsif (defined($ARGV[0]) && defined($ARGV[1]) && defined($ARGV[2]) && ! defined($ARGV[3])) {
	$old_domain = $ARGV[0];
	$new_domain = $ARGV[1];
	if(lc $ARGV[2] eq "upgrade") {
		$upgrade = $ARGV[2];
	} else {
		$ldif_file = $ARGV[2];
	}
} elsif (defined($ARGV[0]) && defined($ARGV[1]) && defined($ARGV[2]) && defined($ARGV[3])) {
	$old_domain = $ARGV[0];
	$new_domain = $ARGV[1];
	$ldif_file = $ARGV[2];
	$upgrade = $ARGV[3];
} else {
	usage();
}

if(defined $upgrade && lc $upgrade eq "upgrade") {
	$ldap_old_domain = getOLDLDAPDomain($old_domain);
	$ldap_new_domain = getLDAPDomain($new_domain);
} else {
	$ldap_old_domain = getLDAPDomain($old_domain);
	$ldap_new_domain = getLDAPDomain($new_domain);
}

my @file;
if ($ldif_file eq "") {
	# LDAP config files
	foreach $_ (@ldap_conffiles) {
		if (-r $_) {
			open FILE, $_ or die "Couldn't open file $_";
			@file = <FILE>;
			print "Processing $_ ...\n";
			@file = replaceString($ldap_old_domain, $ldap_new_domain, @file);
			close FILE;

			open OUTFILE, "> $_" or die "Couldn't open file /tmp/$_";
			print OUTFILE @file;
		} else {
			print "Couldn't read $_\n";
		}
	}
	
	# Other config files
	foreach $_ (@other_conffiles) {
		if (-r $_) {
			open FILE, $_ or die "Couldn't open file $_";
			@file = <FILE>;
			print "Processing $_ ...\n";
			@file = replaceString($old_domain, $new_domain, @file);
			close FILE;

			open OUTFILE, "> $_" or die "Couldn't open file /tmp/$_";
			print OUTFILE @file;
		} else {
			print "Couldn't read $_\n";
		}
	}
}

if ($ldif_file eq "") {
	print "Processing slapcat ...\n";
	my $cmd = "slapcat -f ".Yaffas::Constant::FILE->{slapd_conf};
	@ldif = `$cmd`;
} else {
	print "Opening file $ldif_file ...\n";
	open LDIF, "< $ldif_file" or die "Couldn't open file $ldif_file";
	@ldif = <LDIF>;
	close LDIF;
}

@ldif = replaceString($ldap_old_domain, $ldap_new_domain, @ldif);
@ldif = correctLDIF($ldap_new_domain, @ldif);

open OUTFILE, "> /tmp/slapcat.ldif";
print OUTFILE @ldif;
close OUTFILE;

if (Yaffas::Constant::get_os() =~ m/RHEL\d/ ) {
	`chcon -u system_u -t slapd_db_t /tmp/slapcat.ldif`;
}

if ($ldif_file eq "") {
	print "Stopping slapd ...\n";
	control(LDAP(), STOP());
	`rm -rf /var/lib/ldap/*`;

	print "Executing slapadd ...\n";
	my $cmd = Yaffas::Constant::APPLICATION->{slapadd}." -vl /tmp/slapcat.ldif -f ".Yaffas::Constant::FILE->{slapd_conf};
	print `$cmd`;

	if (Yaffas::Constant::get_os() =~ m/RHEL\d/ ) {
		`chown -R ldap:ldap /var/lib/ldap/`;
	}
	else {
		`chown -R openldap:openldap /var/lib/ldap/`;
	}

	print "Starting slapd ...\n";
	control(LDAP(), START());

	print "Restarting nscd ...\n";
	control(NSCD(), RESTART());

	if (Yaffas::Constant::get_os() eq "RHEL6" ) {
		print "Restarting nslcd ...\n";
		control(NSLCD(), RESTART());
	}

	open LDAPSEC, "< /etc/ldap.secret";
	@ldap = <LDAPSEC>;
	chomp($ldap[0]);
	`smbpasswd -w $ldap[0]`;
}

print "done\n";


# replaceString("oldstring", "newstring", textarray)
sub replaceString {
	my ($od, $nd, @array) = @_;
	my @newarray;

	foreach $_ (@array) {
		$_ =~ s/$od/$nd/g;
		push(@newarray, $_);
	}
	return @newarray;
}

# getLDAPDomain("domainstring")
sub getLDAPDomain {
	if ($_[0] eq "BASE") {
		return "BASE";
	}
	my @tmp = split(/\./, $_[0]);
	die "Domain $_[0] too short" if ($#tmp < 1 && $_[0] ne "BASE");
	my $new;
	my $org;

	for($i=0; $i<=$#tmp; $i++) {
		if ($i == $#tmp) {
			$new .= "dc=".$tmp[$i];
		} elsif ($i == $#tmp-1) {
			$new .= "dc=".$tmp[$i];
			$org = $tmp[$i];
		} else {
			$new .= "dc=".$tmp[$i];
		}
		$new .= "," if ($i != $#tmp);
	}

	return $new;
}

sub getOLDLDAPDomain {
	if ($_[0] eq "BASE") {
		return "BASE";
	}
	my @tmp = split(/\./, $_[0]);
	die "Domain $_[0] too short" if ($#tmp < 1 && $_[0] ne "BASE");
	my $new;
	my $org;

	for($i=0; $i<=$#tmp; $i++) {
		if ($i == $#tmp) {
			$new .= "c=".$tmp[$i];
		} elsif ($i == $#tmp-1) {
			$new .= "o=".$tmp[$i];
			$org = $tmp[$i];
		} else {
			$new .= "ou=".$tmp[$i];
		}
		$new .= "," if ($i != $#tmp);
	}

	return $new;
}


sub correctLDIF {
	my ($nd, @ldif) = @_;

	for ($i=0; $i<$#ldif; $i++) {
		last if ($ldif[$i] =~ /^$/);
		$ldif[$i] = "";
	}
	@tmp = split (/,/, $nd);
	@tmp = split (/=/, $tmp[0]);
	
#	if ($tmp[0] eq "o") {
		unshift (@ldif, "dn: ".$nd."\n", "dc: $tmp[1]\n", "objectClass: top\n", "objectClass: domain\n");
#	} else {
#		unshift (@ldif, "dn: ".$nd."\n", "ou: $tmp[1]\n", "objectClass: top\n", "objectClass: organizationalUnit\n");
#	}

	return @ldif;
}

