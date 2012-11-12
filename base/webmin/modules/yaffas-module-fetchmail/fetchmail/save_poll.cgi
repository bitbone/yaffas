#!/usr/bin/perl
# save_poll.cgi
# Update, create or delete a server to poll

use Yaffas;
use Yaffas::UI;
use Yaffas::UGM;
use Yaffas::Product;
use Yaffas::Module::Mailsrv;
use Yaffas::Service;
use Yaffas::Constant;
use Yaffas::Exception;
use Error qw(:try);
Yaffas::init_webmin();

require './fetchmail-lib.pl';

sub main() {
	# This is clearly a hack; the whole module should be refactored
	# and proper exception handling should be added... TODO

	&error_setup($text{'poll_err'});
	$file = Yaffas::Constant::FILE->{'fetchmailrc'};
	@conf = &parse_config_file($file);
	if (!$in{'new'}) {
		$poll = $conf[$in{'idx'}];
	}

	&lock_file($file);
	if ($in{'delete'}) {
		# Just delete the poll
		&delete_poll($poll, $file);
	}
	else {
		# Validate poll inputs
		$in{'poll'} =~ /^\S+$/ || &_my_error($text{'poll_epoll'});
		$in{'via_def'} || &check_host($in{'via'}) ||
			&_my_error($text{'poll_evia'});
		!$in{'via_def'} || &check_host($in{'poll'}) ||
			&_my_error($text{'poll_epoll'});
		$in{'port_def'} || ($in{'port'} =~ /^\d+$/ && $in{'port'} > 0 && $in{'port'} <= 65535) ||
			&_my_error($text{'poll_eport'});


		&_my_error($main::text{'poll_evia'}) unless $main::in{'via_def'} =~ m/^\S+$/;
		&_my_error($main::text{'poll_eport'}) unless $main::in{'port_def'} =~ m/^\d+$/;

		&_my_error($main::text{'err_remote_user'}) unless $main::in{'user_0'};

		# Create the poll structure
		$poll->{'poll'} = $in{'poll'};
		my @domains = Yaffas::Module::Mailsrv::get_accept_domains();
		$poll->{'aka'} = join " ", @domains if (scalar @domains);
		#$poll->{'aka'} = "#aka" unless (@domains);
		$poll->{'skip'} = $in{'skip'};
		$poll->{'via'} = $in{'via_def'} ? undef : $in{'via'};
		$poll->{'proto'} = $in{'proto'};
		$poll->{'port'} = $in{'port_def'} ? undef : $in{'port'};
		$poll->{'envelope'} = $in{'poll_envelope'};


		# Validate user inputs
		for($i=0; defined($in{"user_$i"}); $i++) {
			$user = $poll->{'users'}->[$i];
			next if (!$in{"user_$i"});
			# check if username is valid and password exists!
			$in{"user_$i"} =~ /^\S*$/ || &_my_error($text{'err_remote_user'});
			if(not exists $in{"pass_$i"} or
					not defined $in{"pass_$i"} or
					$in{"pass_$i"} eq ""){
				_my_error($text{err_remote_passwd});
			}
			$user->{'user'} = $in{"user_$i"};
			$user->{'pass'} = $in{"pass_$i"};

			# Determine which radiobutton was selected and put the value of the affected popup menu in @is
			local @is;
			if( $main::in{"type_$i"} eq "local_user" ){
				if ( Yaffas::UGM::user_exists($main::in{"local_user_$i"}) ){
					my $email = Yaffas::UGM::get_email(
							$main::in{"local_user_$i"});
					throw Yaffas::Exception("err_bad_email",
						$main::in{"local_user_$i"})
						unless $email;
					push(@is, $email);
				}
				else{
					&_my_error($main::text{'err_local_user'}); 
				}
			}
			elsif( $main::in{"type_$i"} eq "local_alias" ){
				my %aliase = Yaffas::Mail::Mailalias::list_alias();	
				if( $aliase{$main::in{"alias_$i"}} ){
					push(@is, $main::in{"alias_$i"});
				}
				else{
					&_my_error($main::text{'err_local_alias'});
				}
			}
			elsif( $main::in{"type_$i"} eq "multidrop" ){
				push(@is, '*');
			}
			else{
				&_my_error($main::text{'err_no_selection'});
			}
			if (not @is) {
				throw Yaffas::Exception("err_bad_targets");
			}

			$user->{'is'} = \@is;
			$user->{'keep'} = $in{"keep_$i"};
			$user->{'fetchall'} = $in{"fetchall_$i"};
			$user->{'ssl'} = $in{"ssl_$i"};
			$user->{'preconnect'} = $in{"preconnect_$i"};
			$user->{'postconnect'} = $in{"postconnect_$i"};
			push(@users, $user);
		}
		$poll->{'users'} = \@users;

		if ($in{'new'}) {
			&create_poll($poll, $file);
			if ($in{'user'} && $< == 0) {
				local @uinfo = getpwnam($in{'user'});
				&system_logged("chown $uinfo[2]:$uinfo[3] $file");
			}
			&system_logged("chmod 700 $file");
		}
		else {
			&modify_poll($poll, $file);
		}
	}

	&unlock_file($file);

	enable_daemon();

	Yaffas::Service::control(Yaffas::Service::FETCHMAIL(), Yaffas::Service::RESTART());
}

&ReadParse();
header();

try {
	main();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer();

sub enable_daemon() {
	if(Yaffas::Constant::OS eq "Ubuntu" or Yaffas::Constant::OS eq "Debian") {
		my $fetchmail_conf = Yaffas::File->new(Yaffas::Constant::FILE->{'fetchmail_default_conf'})
					or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{'fetchmail_default_conf'});

			my $linenr = $fetchmail_conf->search_line(qr/^\s*START_DAEMON\s*=/);
			if ( defined($linenr)) {
					$fetchmail_conf->splice_line($linenr, 1, "START_DAEMON=yes");
				$fetchmail_conf->write();
			} else {
			throw Yaffas::Exception("err_enable_fetchmail");
		}
	}
}

sub check_host
{
return 1 if (gethostbyname($_[0]));
return 1;
}


sub _my_error {
	header();
	print Yaffas::UI::error_box(shift);
	footer();
	exit;
}
