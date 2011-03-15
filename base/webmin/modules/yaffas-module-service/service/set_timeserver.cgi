#!/usr/bin/perl

use strict;
use warnings;

my $format;

use Yaffas;
use Yaffas::UI;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Module::Time;
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();
&ReadParse();

header();

try {
	my $type = $main::in{sync_freq};
	my $minute = $main::in{minute};
	my $hour = $main::in{hour};
	my $timeserver = $main::in{timeserver};
	
	$hour = 0 unless(defined($hour));
	$minute = 0 unless(defined($minute));

	if ($type eq "hourly") {
		$hour = "*";
	}
	
	if ($timeserver) {
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{ntpdate}, "-u",  $timeserver);
		Yaffas::do_back_quote("/sbin/hwclock", "--systohc");
	}
	Yaffas::Module::Time::set_timeserver($timeserver);

	if ($type eq "once") {
		Yaffas::Module::Time::rm_crontab();
	} elsif($type eq "hourly" || $type eq "daily") {
		Yaffas::Module::Time::set_crontab($hour, $minute, $timeserver);
	}
	
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer();

=pod

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
