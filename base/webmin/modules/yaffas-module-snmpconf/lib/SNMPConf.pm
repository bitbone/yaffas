package Yaffas::Module::SNMPConf;
use strict;
use warnings;

use Yaffas::File;
use Yaffas::Exception;
use Yaffas::Service qw(STOP START RESTART SNMPD);
use Yaffas::Check;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Constant;
use Error qw(:try);

our @ISA = qw(Yaffas::Module);

our $DEFAULT_CONFIG = <<'EOT';
# yaffas-1.3 configuration - DO NOT MOVE OR DELETE THIS LINE

# COMMUNITYs
#       sec.name source    community
com2sec readonly 127.0.0.1 public

# GROUPs
#             	sec.model  sec.name
group MyROGroup v1         readonly
group MyROGroup v2c        readonly
group MyROGroup usm        readonly

# VIEWs
#           incl/excl subtree                          mask
view all    included  .1                               80

# ACLs
#                context sec.model sec.level match  read   write  notif
access MyROGroup ""      any       noauth    exact  all    none   none

# System information
syslocation Unknown (configure /etc/snmp/snmpd.local.conf)
syscontact Root <root@localhost> (configure /etc/snmp/snmpd.local.conf)
EOT

=head1 NAME

Yaffas::Module::SNMPConf - Functions for SNMP configuration

=head1 SYNOPSIS

 use Yaffas::Module::SNMPConf;

=head1 DESCRIPTION

Yaffas::Module::SNMPConf

=head1 FUNCTIONS

=over

=item set_snmp_config ( ACTIVE, COMMUNITY, NETMASK )

Sets config.

=cut

sub set_snmp_config($;$$) {
	my ($enabled, $community, $network) = @_;

	if (defined($enabled) and $enabled == 1) {
		if (defined($community)) {
			throw Yaffas::Exception("err_community_string") unless ($community =~ /^[a-zA-Z0-9]+$/);
		} else {
			$community = "public";
		}

		$network = "127.0.0.1" unless defined $network;
		if ($network ne "default" &&
				!Yaffas::Check::ip($1, $2, "netaddr") &&
				!Yaffas::Check::ip($network)) {
			throw Yaffas::Exception("err_network_string");
		}

		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			system(Yaffas::Constant::APPLICATION->{"chkconfig"}, "--level", "2345", "snmpd", "on");
			system(Yaffas::Constant::APPLICATION->{"chkconfig"}, "--level", "016", "snmpd", "off");
		}
		else {
			system(Yaffas::Constant::APPLICATION->{"update-rc.d"}, "snmpd", "defaults");
		}
		throw Yaffas::Exception("err_update_rc") if($?);

		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{snmpd_conf});

		throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{snmpd_conf}) unless($file->get_content());

		if (!config_has_yaffas_tag($file)) {
			# do a backup:
			my $bkpfile = Yaffas::File->new(
				Yaffas::Constant::FILE->{snmpd_conf} . '.yaffassave');
			my @oldlines = $file->get_content();
			$bkpfile->set_content(\@oldlines);
			$bkpfile->save() or
				throw Yaffas::Exception("err_file_write",
					Yaffas::Constant::FILE->{snmpd_conf} . '.yaffassave');

			# we have permission to replace the file with our default
			# config, so lets do that
			my @lines = split(/\n/, $DEFAULT_CONFIG);
			$file->set_content(\@lines);
		}

		my @lines = $file->search_line(qr/^com2sec/);

		foreach (@lines) {
			$file->splice_line($_, 1, "com2sec readonly $network $community");
		}
		$file->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{snmpd_conf});

        if (Yaffas::Constant::OS eq "Ubuntu" or Yaffas::Constant::OS eq 'Debian') {
            $file = Yaffas::File->new("/etc/default/snmpd");
            my @lines = $file->search_line(qr/^SNMPDOPTS/);

            foreach (@lines) {
                $file->splice_line($_, 1, "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -g snmp -I -smux -p /var/run/snmpd.pid'");
            }
            $file->save();
        }

		Yaffas::Service::control(SNMPD, RESTART);
	} else {
		Yaffas::Service::control(SNMPD, STOP);
		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			system(Yaffas::Constant::APPLICATION->{"chkconfig"}, "--del", "snmpd");
		}
		else {
			system(Yaffas::Constant::APPLICATION->{"update-rc.d"}, "-f", "snmpd", "remove");
		}
	}
}

=over

=item config_has_yaffas_tag(FILEOBJ)

FILEOBJ - Yaffas::File instance

Returns whether the given config file contains the yaffas tag.

=cut

sub config_has_yaffas_tag(;$) {
	my $file = shift;
	if (!defined($file)) {
		$file = Yaffas::File->new(Yaffas::Constant::FILE->{snmpd_conf});
		throw Yaffas::Exception("err_file_read",
			Yaffas::Constant::FILE->{snmpd_conf})
			unless($file->get_content());
	}
	return $file->get_content(0) =~ qr/^\s*#\s*yaffas-\S+ configuration/;
}

sub _set_snmp_config($;$$) {
	my ($enabled, $community, $network) = @_;
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("snmpd");
	my $func = Yaffas::Conf::Function->new("snmpd-config", "Yaffas::Module::SNMPConf::set_snmp_config");
	$func->add_param({type => "scalar", param => $enabled});
	$func->add_param({type => "scalar", param => $community});
	$func->add_param({type => "scalar", param => $network});
	$sec->del_func("snmpd-config");
	$sec->add_func($func);
	$bkc->save();
}

=item get_snmp_config()

Reads config and returns ENABLED, COMMUNITY, NETWORK as array.

=cut

sub get_snmp_config() {
	my $file = undef;
	try{
        	$file = Yaffas::File->new(Yaffas::Constant::FILE->{snmpd_conf});
        }
        catch Yaffas::Exception with{
                throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{snmpd_conf});
        }

	my @vals;
	foreach ($file->get_content()) {
		if (/^com2sec/) {
			@vals = split /\s+/, $_;
			last;
		}
	}
	if (!config_has_yaffas_tag($file)) {
		if (!$vals[3]) {
			$vals[3] = "public";
		}
		if (!$vals[2] || $vals[2] eq "default") {
			$vals[2] = "127.0.0.1";
		}
	}

	my $enabled;
	if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
		$enabled = -l "/etc/rc2.d/S50snmpd" ? 1 : 0;
	}
	else {
		$enabled = -l "/etc/rc2.d/S20snmpd" ? 1 : 0;
	}

	return $enabled, $vals[3], $vals[2];
}

sub conf_dump() {
	my @conf = get_snmp_config();
	_set_snmp_config($conf[0], $conf[1], $conf[2]);
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
