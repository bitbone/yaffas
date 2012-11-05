#! /usr/bin/perl -w
use strict;
use warnings;

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas;
use Yaffas::Module::Secconfig;
use Yaffas::UI;
use Yaffas::Service qw(EXIM GREYLIST KAS SPAMASSASSIN control RESTART STOP START);
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();
ReadParse();
header($main::text{'index_header'}, "");


my @change_features = split /\0/, $main::in{'feature'};
my $action = $main::in{action};
my @features = Yaffas::Module::Secconfig::get_enabled();

if ($action eq "start") {
	my %t;
	for (@features, @change_features) {
		$t{$_} = 1;
	}

	@features = keys %t;
} elsif ($action eq "stop") {
	for my $e (@change_features){
		@features = grep {$e ne $_} @features;
	}
}

# antivirus antispam greylist spamassassin start
if ($action eq 'start') {
	if(grep { $_ eq 'antivirus' } @features) {
		if (! Yaffas::Module::Secconfig::check_kav_licence())
		{
			print Yaffas::UI::error_box($main::text{'err_kav_licence'});
			footer();
			exit;
		}
		elsif (! Yaffas::Module::Secconfig::check_kav_bases())
		{
			print Yaffas::UI::error_box($main::text{'err_kav_update'});
			footer();
			exit;
		}
		else
		{
			Yaffas::Module::Secconfig::_control_kav("start");
		}
	}
	if(grep { $_ eq 'antispam' } @features && grep { $_ eq 'antispam' } @change_features) {
		if (! -f "/data/config/mail/bbkasupdate/update_success") {
			print Yaffas::UI::error_box($main::text{'err_kas_update'});
			footer();
			exit;
		} else {
			control(KAS(), START());
		}
	}
	if(grep { $_ eq 'greylist' } @features && grep { $_ eq 'greylist' } @change_features) {
		control(GREYLIST(), START());
	}
	if(grep { $_ eq 'spamassassin' } @features && grep { $_ eq 'spamassassin' } @change_features) {
		control(SPAMASSASSIN(), START());
	}
	
	if(grep { $_ eq 'policyserver' } @features && ! Yaffas::Module::Secconfig::check_mpp_policyserver()) {
		print Yaffas::UI::error_box($main::text{'err_activate_policyserver'});
		exit 0;	
	}
}

# antivirus antispam greylist spamassassin stop
if ($action eq 'stop') {
	if((! grep { $_ eq 'antivirus' } @features) && grep { $_ eq 'antivirus' } @change_features) {
		Yaffas::Module::Secconfig::_control_kav("stop");
	}

	if((! grep { $_ eq 'antispam' } @features) && grep { $_ eq 'antispam' } @change_features) {
		control(KAS(), STOP());
	}

	if((! grep { $_ eq 'greylist' } @features) && grep { $_ eq 'greylist' } @change_features) {
		control(GREYLIST(), STOP());
	}

	if((! grep { $_ eq 'spamassassin' } @features) && grep { $_ eq 'spamassassin' } @change_features) {
		control(SPAMASSASSIN(), STOP());
	}
}

try {
	Yaffas::Module::Secconfig::set_enabled(@features);
	control(EXIM(), RESTART());
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
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
