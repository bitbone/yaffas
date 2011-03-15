package Yaffas::Module::Secconfig;
use strict;
use warnings;
use Yaffas qw(do_back_quote);
use POSIX qw(mktime);
use Yaffas::File::Config;
use Yaffas::Constant;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Exception;
use Yaffas::Check;
use Yaffas::Service qw(EXIM GREYLIST KAS control RESTART STOP START);
use Error qw(:try);

=pod

=head1 NAME

Yaffas::Module::Secconfig

=head1 DESCRIPTION

This Modules provides functions for Webmin module bbsecconfig

=head1 FUNCTIONS

=over

=item get_all()

=cut

our @ISA = ("Yaffas::Module");

sub get_all(){
	return qw(antivirus antispam greylist quarantine spamassassin policyserver);
}

=item get_enabled()

=cut

sub get_enabled(){
	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => '\s*=\s*',
										 -StoreDelimiter => ' = ',
										}
									   );
	my $cfg = $bkf->get_cfg_values();
	my @enabled;
	foreach (keys %{$cfg}) {
		next unless $cfg->{$_} eq "1";
		if (m/BB(.*)/) {
			push @enabled, $1;
		}
	}
	return @enabled;
}

=item set_enabled()

=cut

sub set_enabled(@) {
	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => '\s*=\s*',
										 -StoreDelimiter => ' = ',
										}
									   );
	my $cfg = $bkf->get_cfg_values();


	foreach my $key (keys %{$cfg}) {
	# für alle werte aus dem config file.
		unless ( grep {"BB" . $_ eq $key} get_all() ){
			next;
		}
		# überspringen wenn es ein unbekanntes feature ist.

		if ($key =~ m/BB(.*)/) { # alle BB features
			delete $cfg->{$key}; # deaktiviren.
		}
	}

	if (grep {$_ eq "policyserver"} @_) {
		throw Yaffas::Exception("err_activate_policyserver") unless check_mpp_policyserver();
	}

	# alle übergebenen features aktivieren.
	for (@_) {
		if ($_ eq "antivirus") {
			next unless check_kav_licence()
		}
		$cfg->{"BB" . $_} = 1;
	}

	$bkf->save();
}

sub check_kav_licence() {
	my $dir = Yaffas::Constant::DIR->{'kav_licence'};
	my $app = Yaffas::Constant::APPLICATION->{'kav_licence'};

	opendir(DIR, $dir) || return undef;
	foreach (readdir(DIR)) {
		my $file = $dir .'/' . $_ if m/\.key$/;
		next unless $file;

		my ($out) = (do_back_quote($app, "-k", $file) =~ m/Expiration date:\s*([0-9-]+)/);
		next unless $out;

		my ($day, $mon, $year) = split('-', $out, 3);
		$mon--; $year -= 1900;

		my $valid = mktime(0, 0, 0, $day, $mon, $year);
		my $now = time;

		return 1 if $valid > $now;
	}
	closedir(DIR);

	return undef;
}

=item check_kav_bases()

Checks if there was an update since installation. If there are no base files, then aveserver won't start.

=cut

sub check_mpp_policyserver() {
	my $file = Yaffas::File->new(Yaffas::Constant::FILE->{mppd_conf_xml});

	foreach ($file->get_content()) {
		if (m#<policy_enabled>(.*)</policy_enabled>#) {
			if ($1 =~ /\s*yes\s*/) {
				return 1;
			}
		}
	}
	return 0;
}

sub check_kav_bases() {
	my $dir = Yaffas::Constant::DIR->{'kav_bases'};
	my $bases = 0;
	opendir(DIR, $dir) || return undef;
	foreach (readdir(DIR)) {
		$bases++ if ($_ =~ /^base.*$/);
	}
	closedir(DIR);
	return $bases;
}


# needed because you can't simply restart kav
sub _control_kav($) {
	my $option = shift;
	Yaffas::system_silent("/etc/init.d/aveserver $option");
}

=item get_virus_notify ()

Returns the set notify email or undef if nothing is set.

=cut

sub get_virus_notify() {
	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => ' = ',
										}
									   ) or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{bbexim_conf});
	my $cfg = $bkf->get_cfg_values();

	if (exists($cfg->{BBnotify_virus}) && $cfg->{BBnotify_virus} ne "") {
		return $cfg->{BBnotify_virus};
	}
	return undef;
}

=item set_virus_notify ( EMAIL )

Enables virus notify and sets EMAIL as notification email

=cut

sub set_virus_notify($) {
	my $email = shift;

	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => ' = ',
										}
									   ) or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{bbexim_conf});
	my $cfg = $bkf->get_cfg_values();

	if (defined($email) && $email ne "") {
		Yaffas::Check::email($email) or throw Yaffas::Exception("err_email_wrong");
		$cfg->{BBnotify_virus} = $email;
	} else {
		delete $cfg->{BBnotify_virus};
	}

	$bkf->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{bbexim_conf});
	control(EXIM(), RESTART());
}

## disable tls

sub get_tls_status() {
	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => ' = ',
										}
									   ) or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{bbexim_conf});
	my $values = $bkf->get_cfg_values();
	my %status;

	$status{client} = $values->{BBclient_no_tls} if (exists($values->{BBclient_no_tls}));
	$status{server} = $values->{BBserver_no_tls} if (exists($values->{BBserver_no_tls}));

	return %status;
}

sub set_tls_status(%) {
	my %value = @_;

	my $bkf = Yaffas::File::Config->new(
										Yaffas::Constant::FILE()->{bbexim_conf},
										{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => ' = ',
										}
									   ) or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{bbexim_conf});

	my $cfg_values = $bkf->get_cfg_values();
	foreach my $type (keys %value) {
		if ($type eq "server" or $type eq "client") {
			$cfg_values->{"BB".$type."_no_tls"} = $value{$type};
		}
	}
	if (exists($value{server}) && $value{server} == 1) {
		$cfg_values->{BBserver_no_tls} = 1;
	} else {
		delete $cfg_values->{BBserver_no_tls};
	}

	if (exists($value{client}) && $value{client} == 1) {
		$cfg_values->{BBclient_no_tls} = 1;
	} else {
		delete $cfg_values->{BBclient_no_tls};
	}

	$bkf->save();

	control(EXIM(), RESTART());
}

sub conf_dump() {
	my @enabled = get_enabled();

	# nothing configured -> nothing to do
	return 1 unless @enabled;

	# save configured entries
	my $conf		= Yaffas::Conf->new();
	my $section		= $conf->section('secconfig');
	my $function	= Yaffas::Conf::Function->new('enabled', 'Yaffas::Module::Secconfig::set_enabled');
	$function->add_param({type => 'array', param => \@enabled});
	$section->del_func("enabled");
	$section->add_func($function);

	try {
		my $email = get_virus_notify();
		if ($email) {
			$function = Yaffas::Conf::Function->new('notify_email', 'Yaffas::Module::Secconfig::set_virus_notify');
			$function->add_param({type=>'scalar', param=>$email});
			$section->del_func("notify_email");
			$section->add_func($function);
		}
	} catch Yaffas::Exception with {
		# ok, file doesn't exists - so I do nothing
	};

	try {
		my %tls_status = get_tls_status();
		if (%tls_status) {
			$function = Yaffas::Conf::Function->new('tls_status', 'Yaffas::Module::Secconfig::set_tls_status');
			$function->add_param({type=>'hash', param=>\%tls_status});
			$section->del_func("tls_status");
			$section->add_func($function);
		}
	} catch Yaffas::Exception with {
		# ok, file doesn't exists - so I do nothing
	};

	$conf->save();
}

sub antivirus_available {
	return -r $Yaffas::Service::SERVICES{Yaffas::Service::KAV()};
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
