package Yaffas::Module::Netconf;

use strict;
use warnings;

our @ISA = ("Yaffas::Module");

use Yaffas qw(do_back_quote);
use Yaffas::Exception;
use Yaffas::Service qw(WEBMIN USERMIN SASLAUTHD HYLAFAX SAMBA NETWORK NSCD RESTART control);
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Auth;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Check;
use Sort::Naturally;
use File::Copy;

=head1 NAME

Yaffas::Module::Netconf

=head1 NOTE

All functions in this module use exception handling with L<Error.pm>

Getter functions are RedHat aware, setters are not.

=head1 FUNCTIONS

=over

=item new ()

Creates a new object and reads the current configuration.
e.g. my $obj = Yaffas::Module::Netconf->new();

=cut

sub new {
	my $pkg = shift;
	my $testmode = shift;

	my $self = {};
	$self->{DEVICES} = _load_settings();

	my $app = Yaffas::Constant::APPLICATION->{hostname};
	chomp(my $hostname = `$app -s`);

	$app = Yaffas::Constant::APPLICATION->{dnsdomainname};
	chomp(my $domain = `$app`);

	$self->{OLD_HOSTNAME} = $hostname;
	$self->{HOSTNAME} = $hostname;

	$self->{OLD_DOMAINNAME} = $domain;
	$self->{DOMAINNAME} = $domain;
	$self->{TESTMODE} = $testmode;
	$self->{DELETE_DEVICES} = [];

	bless $self, $pkg;
}

=item device ( DEVICE )

Returns a object of type L<Yaffas::Module::Netconf::Device>.
With this object you can read and edit all values;

=cut

sub device {
	my $self = shift;
	my $d = shift;

	return $self->{DEVICES}->{$d} if (exists($self->{DEVICES}->{$d}));
	return undef;
}

=item save ()

Saves the configuration to file and loads the settings

=cut

sub save {
	my $self = shift;

	$self->disable_virtual();

	my $one_enabled = 0;
	foreach my $dev (values %{$self->{DEVICES}}) {
		next unless ($dev->{DEVICE} =~ /^eth\d+$/);
		if ($dev->{ENABLED} == 1) {
			$one_enabled = 1;
		}
	}

	throw Yaffas::Exception("err_one_enabled") unless($one_enabled);

	return if $self->{TESTMODE};

	foreach (@{$self->{DELETE_DEVICES}}) {
		system(Yaffas::Constant::APPLICATION->{ifdown}, $_);
	}

	$self->_save_interfaces();
	$self->_save_domainname();
	$self->_save_hostname();
	$self->_save_iftab();

	my $pid = fork();

	throw Yaffas::Exception("err_fork") unless (defined($pid));

	if ($pid == 0) {
		## child
		control(NETWORK, RESTART);
		if (-d Yaffas::Constant::DIR->{hylafax}) {
			control(HYLAFAX, RESTART);
		}
		system(Yaffas::Constant::APPLICATION->{nscd}, "-i", "hosts");
		control(USERMIN, RESTART);
		control(SASLAUTHD, RESTART);
		control(NSCD, RESTART) unless Yaffas::Constant::OS eq 'RHEL5';

	} else {
		## parent - will be killed by webmin restart
		wait;
	}
}

=item add_virtual_device ( DEVICE )

Adds new device object for the given DEVICE. It returns the new object.

=cut

sub add_virtual_device {
	my $self = shift;
	my $parent_device = shift;

	my $d = scalar grep { /^$parent_device:\d+/ } keys %{$self->{DEVICES}};

	$d = 0 if ($d < 0);

	my $device = "$parent_device:$d";

	if (defined $self->device($device)) {
		$d = 0;
		while (1) {
			$device = "$parent_device:$d";
			last unless(defined($self->device($device)));
			$d++;
		}
	}

	my $d_obj = Yaffas::Module::Netconf::Device->new($device);
	$d_obj->{PARENT} = $parent_device;
	$d_obj->enable(1) if ($self->device($parent_device)->enabled() == 1);
	$self->{DEVICES}->{$device} = $d_obj;

	return $d_obj;
}

=item delete_virtual_device ( DEVICE )

Removes the specified DEVICE from config.

=cut

sub delete_virtual_device {
	my $self = shift;
	my $device_name = shift;

	my $dev = $self->device($device_name);

	throw Yaffas::Exception("err_device_not_found") unless (defined($dev));

	delete $self->{DEVICES}->{$device_name};
	push @{$self->{DELETE_DEVICES}}, $device_name;
}

=item disable_virtual ( DEVICE, VALUE )

Checks for every real interface, if it is disabled, and then it disables all virtual interfaces on this card

=cut

sub disable_virtual {
	my $self = shift;
	my $device = shift;

	foreach my $device (values %{$self->{DEVICES}}) {
		if ($device->{DEVICE} =~ /^eth\d+$/) {
			foreach my $d (grep { /^$device->{DEVICE}:\d+/ } keys %{$self->{DEVICES}}) {
				$self->device($d)->enable(0) if ($device->enabled() == 0);
			}
		}
	}

}

=item get_all_names ()

Returns all available in the object

=cut

sub get_all_names {
	my $self = shift;

	return keys %{$self->{DEVICES}};
}

# helper function to parse file and create Device objects
sub _load_settings {
	my %settings = ();

	my @lspci = do_back_quote(Yaffas::Constant::APPLICATION->{lspci}, '-mv');
	my %lspci = ();

	my $id = "";
	foreach my $line (@lspci) {
		if (!defined($id) and $line =~ /^Device:\s*(.*)$/) {
			$id = $1;
			$lspci{$1} = {};
			next;
		}

		if ($line =~ /^(\w+):\s*(.*)/) {
			$lspci{$id}->{$1} = $2;
		}

		if ($line =~ /^$/) {
			$id = undef;
		}
	}

	my @enabled_interfaces = ();

	my $resolv_conf = Yaffas::File->new( Yaffas::Constant::FILE->{resolv_conf} ) or Yaffas::Exception( "err_file_read", Yaffas::Constant::FILE->{resolv_conf} );
	my @dns = grep { /^nameserver\s*/ } $resolv_conf->get_content();
	map { s/^nameserver\s*// } @dns;

	my @search = grep { /^search\s*/ } $resolv_conf->get_content();
	@search = split /\s+/, $search[0];
	shift @search;

	foreach my $dev (_get_all_devices()) {
		$settings{$dev} = Yaffas::Module::Netconf::Device->new($dev);

		my $pciid = "";

		if ($dev =~ /^eth\d+(:\d+)?/) {
			my @udevinfo = do_back_quote(Yaffas::Constant::APPLICATION->{udevinfo}, '-ap', "/class/net/$dev");

			my $found_section = 0;
			foreach my $line (@udevinfo) {
				if (!$found_section and ( $line =~ /^\s*BUS=="pci"$/ or $line =~ /^\s*ID==".*"$/ )) {
					$found_section = 1;
				}


				if ($found_section) {
					if ($line =~ /^\s*$/) {
						$found_section = 0;
						last;
					}

					if ($line =~ /^\s*ID=="0000:(.*)"/) {
						$pciid = $1;
					}
				}
			}

			if ($pciid) {
				if (defined($lspci{$pciid}->{SVendor})) {
					$settings{$dev}->{VENDOR} = $lspci{$pciid}->{SVendor};
				}
				else {
					$settings{$dev}->{VENDOR} = $lspci{$pciid}->{Vendor};
				}

				if (defined($lspci{$pciid}->{SDevice})) {
					$settings{$dev}->{PRODUCT} = $lspci{$pciid}->{SDevice};
				}
				else {
					$settings{$dev}->{PRODUCT} = $lspci{$pciid}->{Device};
				}
			}

			my $config = Yaffas::File->new( Yaffas::Constant::DIR->{rhel5_devices}."ifcfg-".$dev )
				or throw Yaffas::Exception("err_file_read", Yaffas::Constant::DIR->{rhel5_devices}."ifcfg-".$dev );
			my @lines = $config->get_content();
			my( $ip, $netmask, $gateway, $dns, $search ) = "";
			foreach my $line ( @lines ) {
				if( $line =~ m/\s*IPADDR\s*=\s*(.*)/ ) {
					$ip = $1;
				}

				if( $line =~ m/\s*NETMASK\s*=\s*(.*)/ ) {
					$netmask = $1;
				}

				if( $line =~ m/\s*GATEWAY\s*=\s*(.*)/ ) {
					$gateway = $1;
				}

				$dns = \@dns; # FIXME: dns iface spezifisch?

				$search = \@search; # FIXME: search iface spezifisch?

				if( $line =~ m/\s*ON(BOOT|PARENT)\s*=\s*yes/ ) {
					push @enabled_interfaces, $dev;
				}
			}

			my $d_obj = Yaffas::Module::Netconf::Device->new( $dev );
			$d_obj->set_all( $ip, $netmask, $gateway, $dns, $search );

			my $parent;
			if( $dev =~ m/^(eth\d+):\d+$/ ) {
				$d_obj->{PARENT} = $parent = $1 if exists( $settings{$1} );
			}

			if( exists( $settings{$dev} ) or ( defined( $parent ) and exists( $settings{$parent} ) ) ) {
				$d_obj->{VENDOR} = $settings{$dev}->{VENDOR};
				$d_obj->{PRODUCT} = $settings{$dev}->{PRODUCT};
				$settings{$dev} = $d_obj;
			}
		}
	}

	foreach my $dev (@enabled_interfaces) {
		$settings{$dev}->{ENABLED} = 1 if exists $settings{$dev};
	}

	return \%settings;
}

# helper function which returns all available devices
sub _get_all_devices() {
	opendir DIR, Yaffas::Constant::DIR->{rhel5_devices};

	my @devs = grep {/^ifcfg-eth\d+(\:\d+)?/} readdir DIR;
	map { s/^ifcfg-// } @devs;

	closedir DIR;
	return @devs;
}

## ---------------------------------------------------------------------- ##

=item domainname ()

	Returns current domain name.

=cut

sub domainname {
	my $self = shift;
	my $domain = shift;

	if (defined($domain)) {
		throw Yaffas::Exception("err_domain") unless(Yaffas::Check::domainname($domain));
		$self->{DOMAINNAME} = $domain;
		return;
	}
	return $self->{DOMAINNAME};
}


=item set_domain_name ( DOMAIN )

Sets the domain name.

=cut

sub _save_domainname ($) {
	my $self = shift;

	my $newdom = $self->{DOMAINNAME};
	my $olddom = $self->{OLD_DOMAINNAME};

	if ($newdom ne $olddom) {
		if (Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP) {
			#my $ret = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{domrename}, $olddom, $newdom);
			my $ret = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{dnsdomainname}, $newdom );
			if ($?) {
				throw Yaffas::Exception("err_domain_rename", $ret);
			}
		}
		else {
			my $hostname = $self->hostname();
			my $ip = $self->device("eth0")->get_ip();

			# /etc/defaultdomain
			my $ddconf = Yaffas::File->new(Yaffas::Constant::FILE->{default_domain}, $newdom)
				or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{default_domain});
			$ddconf->write()
				or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{default_domain});
		}


		if (-d Yaffas::Constant::DIR->{hylafax}) {
			my $bkc_from = "/etc/defaultdomain";
			my $bkc_to = Yaffas::Constant::DIR->{hylafax_spool}."etc/defaultdomain";
			copy($bkc_from,$bkc_to) or throw Yaffas::Exception("err_copy_file", $bkc_from . " to " . $bkc_to . " with: $!");
		}
	}
}

## ---------------------------------------------------------------------- ##

=item hostname ()

	Returns current hostname.

=cut

sub hostname {
	my $self = shift;
	my $hostname = shift;

	if (defined $hostname) {
		throw Yaffas::Exception("err_hostname") unless Yaffas::Check::hostname($hostname);
		$self->{HOSTNAME} = $hostname;
		return;
	}
	return $self->{HOSTNAME};
}

=item set_hostname ( HOSTNAME )

Sets new HOSTNAME.

=cut

sub _save_hostname {
	my $self = shift;
	my $hostname = $self->{HOSTNAME};

	# create new /etc/hosts
	my $ip = $self->device("eth0")->get_ip();
	my $dnsname = $self->{DOMAINNAME};

	my $file = Yaffas::File->new(Yaffas::Constant::FILE->{hosts}, "") or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{hosts});

	$file->add_line("127.0.0.1\tlocalhost\n");

	my $tmp = "$ip\t$hostname";
	$tmp .= ".$dnsname" if (length($dnsname) > 0);
	$tmp .= "\t$hostname\n";

	$file->add_line($tmp);
	$file->save();

	$file = Yaffas::File->new(Yaffas::Constant::FILE->{hostname}, $hostname)
		or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{hostname});
	$file->wipe_content();
	$file->add_line( $hostname );
	$file->save();

	# call /etc/init.d/hostname.sh
	my $app = Yaffas::Constant::APPLICATION->{hostname};
	Yaffas::do_back_quote( $app, $hostname );
	throw Yaffas::Exception( "err_file_execute", $app ) if $?;
	#my $app = Yaffas::Constant::APPLICATION->{"hostname.sh"};
	#system($app, "start");
	#throw Yaffas::Exception("err_file_execute", $app) unless($?>>8 == 1);
}

## ---------------------------------------------------------------------- ##

sub _save_interfaces {
	my $self = shift;
	#my $file = Yaffas::File->new(Yaffas::Constant::FILE->{network_interfaces}, "");
	#$file or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{network_interfaces});

	#my $lo_exists = undef;
	#foreach my $dev (keys %{$self->{DEVICES}}) {
	#	if ($dev eq "lo") {
	#		$lo_exists = 1;
	#		last;
	#	}
	#}

	#unless($lo_exists) {
	#	my $d_obj = Yaffas::Module::Netconf::Device->new("lo");
	#	$d_obj->set_all("127.0.0.1", "255.255.255.0");
	#	$d_obj->enable(1);
	#	$self->{DEVICES}->{lo} = $d_obj;
	#}

	#$file->save();

	# delete old ifcfg's
	opendir( DIR, Yaffas::Constant::DIR->{rhel5_devices} );
	my @oldfiles = grep { /^ifcfg-(eth\d+:\d+)$/ && not defined $self->{DEVICES}->{$1} } readdir DIR;
	unlink Yaffas::Constant::DIR->{rhel5_devices}.$_ foreach @oldfiles;
	closedir( DIR );

	foreach my $dev (nsort keys %{$self->{DEVICES}}) {
		my $file = Yaffas::File->new( Yaffas::Constant::DIR->{rhel5_devices}."ifcfg-".$dev, "" );
		$file or throw Yaffas::Exception( "err_file_write", Yaffas::Constant::DIR->{rhel5_devices}."ifcfg-".$dev );
		$file->add_line($self->{DEVICES}->{$dev}->interface_dump());
		$file->save();
	}

	my $resolv_conf = Yaffas::File->new( Yaffas::Constant::FILE->{resolv_conf} ) or throw Yaffas::Exception( "err_file_write", Yaffas::Constant::FILE->{resolv_conf} );
	$resolv_conf->wipe_content();
	$resolv_conf->add_line( "search " . join ' ', @{$self->{DEVICES}->{eth0}->{SEARCH}} );
	foreach my $nameserver ( @{$self->{DEVICES}->{eth0}->{DNS}} ) {
		$resolv_conf->add_line( "nameserver ".$nameserver );
	}
	$resolv_conf->save();
}

sub _save_iftab {
	my $self = shift;

	my $file = Yaffas::File->new(Yaffas::Constant::FILE->{iftab}, "");
	throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{iftab}) unless(defined($file));

	foreach my $dev (nsort keys %{$self->{DEVICES}}) {
		if ($dev =~ /^eth\d+$/) {
			$file->add_line($dev." mac ".$self->device($dev)->{MAC});
		}
	}
	$file->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{iftab});
}

## ---------------------------------------------------------------------- ##

=item set_configuration ( DOMAINNAME, HOSTNAME )

	Helper function to set configuration from bitkit.xml

=cut

sub set_configuration {
	my $conf = Yaffas::Module::Netconf->new();
	$conf->domainname(shift);
	$conf->hostname(shift);
	$conf->save();
}


sub conf_dump () {
	# do not save network configuration for RHEL5
	return 1 if Yaffas::Constant::OS eq 'RHEL5';

	my $cnf = Yaffas::Module::Netconf->new();

	my $conf = Yaffas::Conf->new();
	my $section = $conf->section("netconf");
	my $function = Yaffas::Conf::Function->new("domain-hostname", "Yaffas::Module::Netconf::set_configuration");

	$function->add_param({type=>"scalar", param=>$cnf->domainname()});
	$function->add_param({type=>"scalar", param=>$cnf->hostname()});

	$section->del_func("domain");
	$section->add_func($function);

	$conf->save();

	1;
}

package Yaffas::Module::Netconf::Device;

use Yaffas::File;

sub new {
	my $pkg = shift;
	my $device = shift;

	my %self = ();
	$self{DEVICE} = $device;
	$self{IP} = "";
	$self{NETMASK} = "";
	$self{GATEWAY} = "";
	$self{DNS} = "";
	$self{SEARCH} = "";
	$self{ENABLED} = 0;
	$self{VENDOR} = "";
	$self{PRODUCT} = "";
	$self{PARENT} = "";

	my $file = Yaffas::File->new("/sys/class/net/$device/address");
	if ($file) {
		$self{MAC} = $file->get_content();
	}

	bless \%self, $pkg;
}

sub set_all {
	my $self = shift;
	my ($ip, $netmask, $gateway, $dns, $search) = @_;

	$self->{IP} = $ip;
	$self->{NETMASK} = $netmask;
	$self->{GATEWAY} = $gateway;
	$self->{DNS} = $dns;
	$self->{SEARCH} = $search;
}

sub set_ip {
	my $self = shift;
	my $ip = shift;
	my $netmask = shift;

	throw Yaffas::Exception("err_undefined_value", $self->_err_value("ip")) unless defined $ip;
	throw Yaffas::Exception("err_undefined_value", $self->_err_value("netmask")) unless defined $netmask;

	my $exception = Yaffas::Exception->new();
	if ($ip ne "" or $netmask ne "") {
		$exception->add("err_ip", $self->_err_value($ip."/".$netmask)) unless(Yaffas::Check::ip($ip, $netmask));

		throw $exception if $exception;

		$self->{IP} = $ip;
		$self->{NETMASK} = $netmask;
	}
}

sub set_gateway {
	my $self = shift;
	my $gateway = shift;

	throw Yaffas::Exception("err_undefined_value", $self->_err_value("gateway")) unless defined $gateway;

	if ($gateway ne "") {
		my $exception = Yaffas::Exception->new();

		if ($self->{IP}) {
			$exception->add("err_gateway_eq_ip", $self->_err_value($gateway)) if($gateway eq $self->{IP});
		}

		throw $exception if $exception;
	}

	$self->{GATEWAY} = $gateway;
}

sub set_dns {
	my $self = shift;
	my $server = shift;
	throw Yaffas::Exception("err_undefined_value", "dns") unless defined $server;


	my @server = ();

	if (ref $server eq "ARRAY") {
		@server = @{$server};
	}
	else {
		push @server, $server;
	}

	my $exception = Yaffas::Exception->new();
	my @verifyed = ();

	foreach my $dns (@server) {
		if ($dns ne "") {
			$exception->add("err_dns", $self->_err_value($dns)) unless(Yaffas::Check::ip($dns));

			push @verifyed, $dns;
		}
	}
	throw $exception if $exception;

	$self->{DNS} = undef;
	push @{$self->{DNS}}, @verifyed;
}

sub set_search {
	my $self = shift;
	my $s = shift;

	throw Yaffas::Exception("err_undefined_value", "search") unless defined $s;

	my @search = ();

	if (ref $s eq "ARRAY") {
		@search = @{$s};
	}
	else {
		push @search, $s;
	}

	my $exception = Yaffas::Exception->new();

	my @verifyed = ();
	foreach my $search (@search) {
		if ($search ne "") {
			$exception->add("err_search", $self->_err_value($search)) unless(Yaffas::Check::domainname($search));
			push @verifyed, $search;
		}
	}

	throw $exception if $exception;

	$self->{SEARCH} = undef;
	push @{$self->{SEARCH}}, @verifyed;
}

sub get_ip {
	my $self = shift;
	return $self->{IP};
}

sub get_netmask {
	my $self = shift;
	return $self->{NETMASK};
}

sub get_gateway {
	my $self = shift;
	return $self->{GATEWAY};
}

sub get_dns {
	my $self = shift;
	return $self->{DNS};
}

sub get_search {
	my $self = shift;
	return $self->{SEARCH};
}

sub vendor {
	my $self = shift;
	return $self->{VENDOR};
}

*enabled = \&enable;
sub enable {
	my $self = shift;
	my $val = shift;

	if (defined $val) {
		# on virtual device check if parent is enabled
		if ($self->{DEVICE} =~ /^eth\d+:\d+$/ && $val == 1 && $self->{PARENT}) {
			my $conf = Yaffas::Module::Netconf->new();
			my $parent = $conf->device($self->{PARENT});

			throw Yaffas::Exception("err_parent_enable", $self->{PARENT})  if ($parent->enabled() == 0);
		}

		$self->{ENABLED} = $val;
	}
	return $self->{ENABLED};
}

sub interface_dump {
	my $self = shift;

	return unless ($self->{IP});

	my @lines;

	#push @lines, "auto ".$self->{DEVICE} if ($self->{ENABLED} == 1);
	#push @lines, "iface ".$self->{DEVICE}." inet static";
	#push @lines, "\taddress ".$self->{IP} if ($self->{IP});
	#push @lines, "\tnetmask ".$self->{NETMASK} if ($self->{NETMASK});
	#push @lines, "\tgateway ".$self->{GATEWAY} if ($self->{GATEWAY});
	#if (ref $self->{DNS} eq "ARRAY") {
	#	push @lines, "\tdns-nameservers ".join " ", @{$self->{DNS}} if (@{$self->{DNS}});
	#}
	#else {
	#	push @lines, "\tdns-nameservers ".$self->{DNS} if ($self->{DNS});
	#}

	#if (ref $self->{SEARCH} eq "ARRAY") {
	#	push @lines, "\tdns-search ".join " ", @{$self->{SEARCH}} if (@{$self->{SEARCH}});
	#}
	#else {
	#	push @lines, "\tdns-search ".$self->{SEARCH} if ($self->{SEARCH});
	#}

	#push @lines, "";

	push @lines, "DEVICE=".$self->{DEVICE};
	push @lines, "HWADDR=".$self->{MAC} if $self->{MAC};
	if( $self->{ENABLED} == 1 ) {
		if( $self->{PARENT} ) {
			push @lines, "ONPARENT=yes";
		} else {
			push @lines, "ONBOOT=yes";
		}
	}
	push @lines, "NETMASK=".$self->{NETMASK} if $self->{NETMASK};
	push @lines, "IPADDR=".$self->{IP} if $self->{IP};
	push @lines, "GATEWAY=".$self->{GATEWAY} if $self->{GATEWAY};
	push @lines, "TYPE=Ethernet"; # FIXME
	push @lines, "USERCTL=no";
	push @lines, "IPV6INIT=no"; # FIXME
	push @lines, "PEERDNS=yes"; # FIXME
	push @lines, "BOOTPROTO=none";

	return @lines;
}

sub _err_value {
	my $self = shift;
	$self->{DEVICE}." - ".$_[0];
}

package Yaffas::Module::Netconf::Test;

use strict;
use Test::More qw(no_plan);
use Test::Exception;

use Yaffas::Module::Netconf;

sub start {
	my $conf = Yaffas::Module::Netconf->new(1);
	my $eth0 = $conf->device("eth0");

	dies_ok {$eth0->set_ip("192.168.7.11", "234.30.0.4")} "wrong netmask";
	dies_ok {$eth0->set_ip("192.168.7.255", "255.255.255.0")} "wrong ip";
	dies_ok {$eth0->set_ip("192.168.7.256", "255.255.255.0")} "wrong ip";
	dies_ok {$eth0->set_ip("192.168.7.256")} "no netmask";
	dies_ok {$eth0->set_ip()} "no values";
	lives_ok {$eth0->set_ip("192.168.7.11", "255.255.255.0")} "ip ok";

	dies_ok {$eth0->set_gateway()} "no gateway";
	lives_ok {$eth0->set_gateway("192.168.7.254")} "gateway ok";

	dies_ok {$eth0->set_dns("192.168.7.256")} "wrong dns";
	dies_ok {$eth0->set_dns()} "wrong dns";
	lives_ok {$eth0->set_gateway("")} "remote gateway";
	lives_ok {$eth0->set_gateway("192.168.7.254")} "reset gateway";
	lives_ok {$eth0->set_dns("192.168.7.250")} "dns ok";
	lives_ok {$eth0->set_dns(["192.168.7.250", "192.168.7.251"])} "multiple dns ok";

	dies_ok {$eth0->set_search()} "no search domain";
	lives_ok {$eth0->set_search("")} "remove search domain";
	dies_ok {$eth0->set_search("bla§")} "wrong search domain";
	dies_ok {$eth0->set_search(["bla.bitbone.de", "blub\$.bitbone.de"])} "wrong search domain";
	lives_ok {$eth0->set_search("technik.bitbone.de")} "search ok";
	lives_ok {$eth0->set_search(["technik.bitbone.de", "bitkit.com"])} "multiple search ok";

	dies_ok {$conf->hostname("")} "empty hostname";
	dies_ok {$conf->hostname("ho\$tname")} "wrong hostname";
	lives_ok {$conf->hostname("hostname")} "hostname ok";
	is ($conf->hostname(), "hostname", "read hostname");

	dies_ok {$conf->domainname("")} "empty domainname";
	dies_ok {$conf->domainname("doma\$nname")} "wrong domainname";
	lives_ok {$conf->domainname("domainname.de")} "domainname ok";
	is ($conf->domainname(), "domainname.de", "read domainname");

	is ($eth0->get_ip(), "192.168.7.11", "read ip");
	is ($eth0->get_gateway(), "192.168.7.254", "read gateway");
	eq_array ($eth0->get_dns(), ["192.168.7.250", "192.168.7.251"], "read dns");
	eq_array ($eth0->get_search(), ["technik.bitbone.de", "bitkit.com"], "read search");

	test_disable_interface($conf);
	test_remove_middle_interface($conf);
	test_disable_all_but_one_virtual($conf);
}

sub test_disable_interface {
	my $conf = shift;

	my $eth0 = $conf->device("eth0");

	my $eth00;
	lives_ok {$eth00 = $conf->add_virtual_device("eth0")} "add first virtual device";
	my $eth01;
	lives_ok {$eth01 = $conf->add_virtual_device("eth0")} "add second virtual device";

	$eth0->enable(0);
	$conf->disable_virtual();

	is($eth00->enabled(), 0, "check if first virtual is disabled");
	is($eth01->enabled(), 0, "check if second virtual is disabled");
	lives_ok {$conf->delete_virtual_device($eth00->{DEVICE})} "remove first device";
	lives_ok {$conf->delete_virtual_device($eth01->{DEVICE})} "remove second device";
}

sub test_remove_middle_interface {
	my $conf = shift;

	my $eth0 = $conf->device("eth0");
	my $name;
	lives_ok {$name = $conf->add_virtual_device("eth0")->{DEVICE}} "read device name";
	$conf->add_virtual_device("eth0");

	$conf->delete_virtual_device($name);

	is($conf->add_virtual_device("eth0")->{DEVICE}, $name, "check if new name eq old name");
}

sub test_disable_all_but_one_virtual {
	my $conf = shift;

	my $vdev = $conf->add_virtual_device("eth0");

	foreach my $d (values %{$conf->{DEVICES}}) {
		$d->enable(0);
	}
	dies_ok {$conf->save()} "can't save with only one virtual enabled interface";
	is($vdev->enable(), 0, "eth0:0 has to be disabled");
	$conf->delete_virtual_device($vdev->{DEVICE});
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
