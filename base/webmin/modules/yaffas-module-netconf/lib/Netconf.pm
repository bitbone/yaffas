package Yaffas::Module::Netconf;

use strict;
use warnings;

our @ISA = ("Yaffas::Module");

use Yaffas qw(do_back_quote);
use Yaffas::Exception;
use Yaffas::Service qw(WEBMIN USERMIN SASLAUTHD HYLAFAX SAMBA NETWORK NSCD ZARAFA_SERVER RESTART control);
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Auth;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Check;
use Sort::Naturally;
use File::Copy;
use Net::LDAP;
use IO::Interface::Simple;
use Error qw(:try);

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

	$app = Yaffas::Constant::APPLICATION->{hostname};
	chomp(my $domain = `$app -d`);



	my $workgroup = "" ;
	my $wgc = Yaffas::File->new(Yaffas::Constant::FILE->{smb_includes_global});
	my $linenr = $wgc->search_line(qr/^\s*workgroup.*/);

	my @file_content = $wgc->get_content();
	if (defined $linenr) {
		$workgroup = $file_content[$linenr];
		$workgroup =~ s/.+\s*=\s*//;
	}

	$self->{OLD_HOSTNAME} = $hostname;
	$self->{HOSTNAME} = $hostname;

	$self->{OLD_WORKGROUP} = $workgroup;
	$self->{WORKGROUP} = $workgroup;

	$self->{OLD_DOMAINNAME} = $domain;
	$self->{DOMAINNAME} = $domain;

	$self->{TESTMODE} = $testmode;
	$self->{DELETE_DEVICES} = [];

	if (grep {$_ =~ /^bond\d+/} keys %{$self->{DEVICES}}) {
		throw Yaffas::Exception("err_bonding_enabled");
	}

	bless $self, $pkg;
}

=item B<workgroup( [NEW WORKGROUP] )>

This routine returns the current workgroup name if you dont pass any arguments to it.
If you pass B<NEW WORKGROUP>, the current workgroup name will be modified. You will get
1 on succes, otherwise undef.

=cut

sub workgroup {
	my $self = shift;
	my $workgroup = shift;

	if (defined $workgroup) {
		throw Yaffas::Exception("err_workgroup_check") unless Yaffas::Check::workgroup($workgroup);
		$self->{WORKGROUP} = $workgroup;
	}
	return $self->{WORKGROUP};
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

	$self->_save_domainname();
	$self->_save_hostname();
	$self->_save_iftab();
	$self->_save_workgroup();

	if(Yaffas::Constant::get_os() eq "Ubuntu"){
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{ifdown}, '-a');
	}
	else {
		Yaffas::do_back_quote(Yaffas::Constant::FILE->{'rhel_net'}, 'stop');
	}

	$self->_save_interfaces();

	my $pid = fork();

	throw Yaffas::Exception("err_fork") unless (defined($pid));

	if ($pid == 0) {
		## child
		if(Yaffas::Constant::get_os() eq "Ubuntu"){
			Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{ifup}, '-a');
		} else {
			Yaffas::do_back_quote(Yaffas::Constant::FILE->{'rhel_net'}, 'start');
		}

		if (-d Yaffas::Constant::DIR->{hylafax}) {
			control(HYLAFAX, RESTART);
		}
		system(Yaffas::Constant::APPLICATION->{nscd}, "-i", "hosts");
		control(USERMIN, RESTART);
		control(SASLAUTHD, RESTART);
		control(NSCD, RESTART) if Yaffas::Constant::OS eq 'Ubuntu';
		control(ZARAFA_SERVER, RESTART);
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

	foreach my $dev (_get_all_devices()) {
		$settings{$dev} = Yaffas::Module::Netconf::Device->new($dev);

		my $pciid = "";

		if ($dev =~ /^eth\d+(:\d+)?/) {
			my @udev_cmd;
			if(Yaffas::Constant::get_os() eq "Ubuntu"){
				@udev_cmd = (Yaffas::Constant::APPLICATION->{udevadm}, 'info', '-a', '-p', "/class/net/$dev");
			} else {
				@udev_cmd = (Yaffas::Constant::APPLICATION->{udevinfo}, '-a', '-p', "/class/net/$dev");
			}
			my @udevinfo = do_back_quote(@udev_cmd);

			my $found_section = 0;
			foreach my $line (@udevinfo) {
				if (!$found_section and $line =~ /^\s*KERNELS=="0000:.*"$/) {
					$found_section = 1;
				}


				if ($found_section) {
					if ($line =~ /^\s*$/) {
						$found_section = 0;
						last;
					}

					if ($line =~ /^\s*KERNELS=="0000:(.*)"/) {
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
		}
	}

	my @enabled_interfaces;

	if(Yaffas::Constant::get_os() eq "Ubuntu"){
		my $interfaces = Yaffas::File->new(Yaffas::Constant::FILE->{network_interfaces})
			or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{network_interfaces});

		my $device = "";
		my ($ip, $netmask, $gateway) = "";
		my ($dns, $search) = [];

		my $i = 0;
		my @lines = $interfaces->get_content();

		my $resolv = Yaffas::File->new(Yaffas::Constant::FILE->{resolv_conf});
		my @content = $resolv->get_content();

		foreach my $line (@content) {
			if ($line =~ /^search\s+(.*)/) {
				push @{$search}, split /\s+/, $1;
			}
			if ($line =~ /^nameserver\s+(.*)/) {
				push @{$dns}, split /\s+/, $1;
			}
		}

		foreach my $line (@lines) {
			$i++;

			if ($line =~ /\s*address\s(.*)/) {
				$ip = $1;
			}

			if ($line =~ /\s*netmask\s(.*)/) {
				$netmask = $1;
			}

			if ($line =~ /\s*gateway\s(.*)/) {
				$gateway = $1;
			}

			if ($line =~ /^\s*auto\s+(.*)$/) {
				push @enabled_interfaces, split /\s+/, $1;
			}

			if ($line =~ /\s*iface\s+(.*)\s+inet\s+(static|dhcp|loopback)/ or $i == scalar @lines) {
				if ($device ne "") {
					# create objects for settings

					my $d_obj = Yaffas::Module::Netconf::Device->new($device);
					$d_obj->set_all($ip, $netmask, $gateway, $dns, $search);

					my $parent;
					if ($device =~ /^(eth\d+):\d+$/) {
						$d_obj->{PARENT} = $parent = $1 if exists ($settings{$1});
					}

					if(exists ($settings{$device}) or (defined ($parent) and exists ($settings{$parent}))) {
						$d_obj->{VENDOR} = $settings{$device}->{VENDOR};
						$d_obj->{PRODUCT} = $settings{$device}->{PRODUCT};
						$settings{$device} = $d_obj;
					}

					$ip = $netmask = $gateway = $dns = $search = "";
				}
				$device = $1;
			}
		}
	} else {
		my ($ip, $netmask, $gateway);
		my ($dns, $search) = ([],[]);

		push @enabled_interfaces, map { $_->name } grep { m#^eth# } IO::Interface::Simple->interfaces;

		my @routes = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'route'}, '-n');
		foreach my $route (@routes){
			$gateway = $1 if $route =~ m#^0\.0\.0\.0\s+([^ ]+)#ix;
		}

		my $yf = Yaffas::File->new(Yaffas::Constant::FILE->{'resolv_conf'});
		foreach my $line ($yf->get_content()){
			chomp $line;

			if($line =~ m#search\s+(.+)\z#ix){
				push @$search, $1;
			}
		}

		foreach my $device (@enabled_interfaces){
			my $fn = Yaffas::Constant::DIR->{'rhel5_scripts'} . "ifcfg-$device";
			$dns = [];

			if(-e $fn){
				my $bkf = Yaffas::File->new($fn) || throw Yaffas::Exception("err_file_read", $fn);

				foreach my $line ($bkf->get_content()){
					chomp $line;
					$ip = $1 if $line =~ m#^IPADDR=(.+)\z#ix;
					$netmask = $1 if $line =~ m#^NETMASK=(.+)\z#ix;
					push @$dns, $1 if $line =~ m#^DNS\d+=(.+)\z#ix;
				}
			}

			unless($ip && $netmask){
				my $iface = IO::Interface::Simple->new($device);
				$ip = $iface->address();
				$netmask = $iface->netmask();
			}

			my $d_obj = Yaffas::Module::Netconf::Device->new($device);
			$d_obj->set_all($ip, $netmask, $gateway, $dns, $search);

			my $parent;
			if ($device =~ /^(eth\d+):\d+$/) {
				$d_obj->{PARENT} = $parent = $1 if exists ($settings{$1});
			}

			if(exists ($settings{$device}) or (defined ($parent) and exists ($settings{$parent}))) {
				$d_obj->{VENDOR} = $settings{$device}->{VENDOR};
				$d_obj->{PRODUCT} = $settings{$device}->{PRODUCT};
				$settings{$device} = $d_obj;
			}

			my $yf = Yaffas::File->new($fn) || throw Yaffas::Exception("err_file_read", $fn);
			$settings{$device}->{'ENABLED'} = (defined $yf->search_line("ONBOOT=yes")) ? "onboot" : undef;

		}
	}

	foreach my $dev (@enabled_interfaces) {
		if(exists $settings{$dev}){
			if(Yaffas::Constant::get_os() ne "Ubuntu") {
				if(exists $settings{$dev}->{ENABLED} && $settings{$dev}->{ENABLED} eq 'onboot'){
					$settings{$dev}->{ENABLED} = 1 
				}
			} else {
				$settings{$dev}->{ENABLED} = 1;
			}
		}
	}

	return \%settings;
}

# helper function which returns all available devices
sub _get_all_devices() {
	opendir DIR, "/sys/class/net";

	my @devs = grep {/^(eth|bond)\d+/} readdir DIR;

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
			my $ret = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{domrename}, $olddom, $newdom);
			if ($?) {
				throw Yaffas::Exception("err_domain_rename", $ret);
			}
		}
		else {
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
	my $old_hostname = uc( $self->{OLD_HOSTNAME} );

	# modify sambaDomainName entry in ldap
	_exchange_samba_domain($old_hostname, $hostname);

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
	$file->save();

	# call /etc/init.d/hostname.sh
	if(Yaffas::Constant::get_os() eq "Ubuntu"){
		my $app = Yaffas::Constant::APPLICATION->{"hostname.sh"};
		system($app, "start");
		throw Yaffas::Exception("err_file_execute", $app) unless($?>>8 == 0);
	}
	else {
		$file = Yaffas::File->new(Yaffas::Constant::FILE->{rhel5_network});
		my $line = $file->search_line(qr/^HOSTNAME/);
		$file->splice_line($line, 1, "HOSTNAME=$hostname.$dnsname");
		$file->save();

		system(Yaffas::Constant::APPLICATION->{hostname}, "$hostname.$dnsname");

		system(Yaffas::Constant::FILE->{'rhel_net'}, 'restart');
	}
}

## ---------------------------------------------------------------------- ##

sub _save_interfaces {
	my $self = shift;

	my $lo_exists = undef;
	foreach my $dev (keys %{$self->{DEVICES}}) {
		if ($dev eq "lo") {
			$lo_exists = 1;
			last;
		}
	}

	unless($lo_exists) {
		my $d_obj = Yaffas::Module::Netconf::Device->new("lo");
		$d_obj->set_all("127.0.0.1", "255.255.255.0");
		$d_obj->enable(1);
		$self->{DEVICES}->{lo} = $d_obj;
	}
	
	if(Yaffas::Constant::get_os() eq "Ubuntu"){
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{network_interfaces}, "");
		$file or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{network_interfaces});

		my (@dns, @search) = ();

		foreach my $dev (nsort keys %{$self->{DEVICES}}) {
			$file->add_line($self->{DEVICES}->{$dev}->interface_dump());

			if (ref $self->{DEVICES}->{$dev}->{DNS} eq "ARRAY") {
				push @dns, @{$self->{DEVICES}->{$dev}->{DNS}};
			}
			else {
				push @dns, $self->{DEVICES}->{$dev}->{DNS};
			}

			if (ref $self->{DEVICES}->{$dev}->{SEARCH} eq "ARRAY") {
				push @search, @{$self->{DEVICES}->{$dev}->{SEARCH}};
			}
			else {
				push @search, $self->{DEVICES}->{$dev}->{SEARCH};
			}
		}

		$file->save();

		my $resolv = Yaffas::File->new(Yaffas::Constant::FILE->{resolv_conf}, "");
		$resolv->add_line("nameserver ".join " ", @dns);
		$resolv->add_line("search ".join " ", @search);
		$resolv->save();
	}
	else {
		foreach my $dev (nsort keys %{$self->{DEVICES}}){
			my $fn = Yaffas::Constant::DIR->{'rhel5_scripts'} . "ifcfg-$dev";
			my $file = Yaffas::File->new($fn, "");
			$file or throw Yaffas::Exception("err_file_write", $fn);

			$file->add_line($self->{DEVICES}->{$dev}->interface_dump_rhel());
			$file->save();
		}
	}
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

sub _save_workgroup {
	my $self = shift;

	return if ( Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::ADS );

	my $workgroup = $self->{WORKGROUP};
	my $old_workgroup = $self->{OLD_WORKGROUP};

	if (uc($workgroup) ne uc($old_workgroup)) {
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{smb_includes_global});
		throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{iftab}) unless(defined($file));

		my $linenr = $file->search_line(qr/^\s*workgroup.*/);

		# add line if entry was not found
		if ($linenr !~ m/^\d+/) {
			$file->add_line("workgroup = $workgroup");
		}
		else {
			# exchange line if entry was found
			$file->splice_line($linenr, 1, "workgroup = $workgroup");
		}

		_exchange_samba_domain($old_workgroup, $workgroup);

		$file->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{iftab});
		control(SAMBA, RESTART);
	}
}

sub _exchange_samba_domain ($$) {
	my $old_dom = uc(shift);
	my $new_dom = uc(shift);

	return unless ( Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP );

	if ($new_dom ne $old_dom) {
		my $auth = Yaffas::Auth::get_bk_ldap_auth();
		my $ldap = Net::LDAP->new( $auth->{uri}, verify => 'none' )
		or throw Yaffas::Exception('err_get_sambasid');
		my $msg = $ldap->bind( $auth->{'binddn'}, password => $auth->{'bindpw'} );

		$msg->code && throw Yaffas::Exception('err_get_sambasid', $msg->code, $msg->error);
		$msg = $ldap->search(
							 base   => $auth->{'base'},
							 filter => "(sambaDomainName=$old_dom)"
							);
		$msg->code && throw Yaffas::Exception('err_get_sambasid', $msg->code, $msg->error);

		my @entries = $msg->entries;
		if ( scalar @entries == 1 ) {
			$msg = $ldap->moddn(
								$entries[0],
								newrdn       => 'sambaDomainName=' . uc($new_dom),
								deleteoldrdn => 1
							   );
			$msg->code && throw Yaffas::Exception('err_set_sambasid', $msg->code, $msg->error);
		}

		$msg = $ldap->unbind;
		$msg->code && throw Yaffas::Exception('err_set_sambasid', $msg->code, $msg->error);
	}
}

## ---------------------------------------------------------------------- ##

=item set_configuration ( DOMAINNAME, HOSTNAME )

	Helper function to set configuration from yaffas.xml

=cut

sub set_configuration {
	my $conf = Yaffas::Module::Netconf->new();
	$conf->domainname(shift);
	$conf->hostname(shift);
	$conf->save();
}


sub conf_dump () {
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

		$exception->add("err_ip", $ip) if ($ip =~ /(\.0\d)+/);

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

sub interface_dump_rhel {
	my $self = shift;

	return unless ($self->{IP});
	my @lines;

	push @lines, "DEVICE=$self->{DEVICE}";
	push @lines, "BOOTPROTO=none";
	push @lines, "HWADDR=$self->{MAC}";
	push @lines, "IPADDR=$self->{IP}";
	push @lines, $self->{'ENABLED'} ? "ONBOOT=yes" : "ONBOOT=no";
	push @lines, "NETMASK=$self->{NETMASK}";
	push @lines, "GATEWAY=$self->{GATEWAY}";

	for my $i (0 .. $#{ $self->{'DNS'} }){
		push @lines, "DNS" . ($i+1) . "=" . $self->{'DNS'}->[$i];
	}

	push @lines, "PEERDNS=yes";
	push @lines, "TYPE=Ethernet";

	return @lines;
}

sub interface_dump {
	my $self = shift;

	return unless ($self->{IP});

	my @lines;

	push @lines, "auto ".$self->{DEVICE} if ($self->{ENABLED} == 1);
	push @lines, "iface ".$self->{DEVICE}." inet static";
	push @lines, "\taddress ".$self->{IP} if ($self->{IP});
	push @lines, "\tnetmask ".$self->{NETMASK} if ($self->{NETMASK});
	push @lines, "\tgateway ".$self->{GATEWAY} if ($self->{GATEWAY});
	push @lines, "";

	return @lines;
}

sub _err_value {
	my $self = shift;
	$self->{DEVICE}." - ".$_[0];
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
