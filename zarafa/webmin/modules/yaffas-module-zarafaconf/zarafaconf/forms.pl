#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::UI qw/textfield radio_group scrolling_list/;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::Mail;
use Yaffas::Module::ZarafaConf;

sub show_basic_settings() {
	print "<script src='functions.js' type='text/javascript'></script>";
	print $Cgi->start_form({-action=>"basicsettings.cgi",
		-name=>"basic_settings_form"});
	print Yaffas::UI::start_section($main::text{lbl_basic_settings});
	print $Cgi->start_table();

	# user filter
	my @settings = Yaffas::Module::ZarafaConf::zarafa_ldap_filter();
	my $auth = Yaffas::Auth::get_auth_type();
	if ($auth eq ADS) {
		print $Cgi->Tr([
			$Cgi->td([$main::text{lbl_userfilter},
				_filtertype(\@settings) .
				$Cgi->br() .
				_filtergroup(\@settings),
			])
		]);
	}


	# features
	my $features = Yaffas::Module::ZarafaConf::get_default_features();
	foreach my $feature (keys %{$features}) {
		print $Cgi->Tr([
			$Cgi->td([
				$main::text{"lbl_enable_${feature}_by_default"},
				$Cgi->checkbox({
					name => "feature_$feature",
					label => "",
					value => undef,
					checked => ($features->{$feature} eq "on") ? 1 : 0
				})
			])
		]);
	}

	# attachment size
	my $value = Yaffas::Module::ZarafaConf::attachment_size();
	print $Cgi->Tr([
		$Cgi->td([
			$main::text{lbl_attachment_size} . " (MB)",
			textfield({-name=>"attachment_size", -value=>$value})
		])
	]);

	# default quota
	my $quota = Yaffas::Mail::get_default_quota(); # in kB

	if (defined($main::in{quota})) {
	    $quota = $main::in{quota}
	} elsif($quota == -1){
	    undef $quota;
	} else{
	    $quota /= 1024;
	}

	print $Cgi->Tr([
		$Cgi->td([
			$main::text{'lbl_default_quota_header'},
			textfield(
				-name => 'quota',
				-default => (defined $quota ? $quota : ""),
			)
		])
	]);

	# softdelete lifetime
	my $softdelete_lifetime =
		Yaffas::Module::ZarafaConf::softdelete_lifetime();

	print $Cgi->Tr([
		$Cgi->td([
			$main::text{'lbl_softdelete_lifetime'},
			textfield(
				-name => 'softdelete_lifetime',
				-default => (defined $softdelete_lifetime ?
					$softdelete_lifetime : ""),
			)
		])
	]);

	print $Cgi->end_table();
	print Yaffas::UI::section_button(
		$Cgi->submit({
			-name=>"save_basic_settings",
			-label=>$main::text{'lbl_save'}}));
	print Yaffas::UI::end_section();
	print $Cgi->end_form();
}

sub _filtertype {
	my $settings = shift;
	return $Cgi->scrolling_list({
			 -id=>"filtertype",
			 -name=>"filtertype",
			 -values=>[0..2],
			 -labels=>{map {$_ => $main::text{"lbl_ldapfilter_type_".$_}} (0..2)},
			 -default=>$settings->[0],
			 -size=>1,
			 -onChange=>"javascript:toggle_filtergroup(this.value)",
			 });
}

sub _filtergroup {
	my $settings = shift;
	
	return $Cgi->scrolling_list({
			 -id=>"filtergroup",
			 -name=>"filtergroup",
			 -values=>[Yaffas::UGM::get_groups()],
			 -default=> lc $settings->[1],
			 -size=>1,
			 -style=> $settings->[0] != 2 ? 'visibility:hidden' : ''
			 }) .
			 $Cgi->input({-id=>"filtersetting", type=>"hidden", value=>$settings->[0]});
}

sub show_memory_optimize {
	my @values = Yaffas::Module::ZarafaConf::optimized_memory_for();

	if ($values[0] == -1) {
		$values[0] = $main::text{lbl_unknown};
	}
	else {
		$values[0] /= 1024*1024;
	}
	if ($values[1] > 0) {
		$values[1] /= 1024*1024;
	}
	print $Cgi->start_form({-action=>"optimize.cgi"});

	print Yaffas::UI::section($main::text{lbl_memory_optimize_header},
							  $Cgi->table(
										  [
										  $Cgi->Tr(
												   [
												   $Cgi->td([$main::text{lbl_memory_optimize}.":", sprintf('%d MB', $values[0])]),
												   $Cgi->td([$main::text{lbl_memory_installed}.":", sprintf('%d MB', $values[1])]),
												   ]
												  )
										  ]
										 )
							 );
							 
	print Yaffas::UI::section_button($Cgi->submit({-name=>"optimize_memory", -value=>$main::text{'lbl_optimize'}}));
	print $Cgi->end_form();
}

sub quota_message_forms () {
	my $type    = 'warn';
	my $content = 'test123';

	print $Cgi->start_form( { -action => 'quotamsg.cgi' } );
	print Yaffas::UI::start_section( $main::text{'lbl_quota'});

	my %labels = (
		'warn' => $main::text{'lbl_quota_warn'},
		'soft' => $main::text{'lbl_quota_soft'},
		'hard' => $main::text{'lbl_quota_hard'}
	);
	print $Cgi->span (
		{ -name => 'quota_radiogroup', -style => 'display:none;' },
		$Cgi->radio_group(
			-values   => [ 'warn', 'soft', 'hard' ],
			-labels   => \%labels,
			-onchange => 'javascript:quota_select_mail();',
			-style    => "display: none;"
		),
	);

	my $i = 0;
	foreach ( 'warn', 'soft', 'hard' ) {
		my $content = Yaffas::Module::ZarafaConf::get_quota_message($_);
		print $Cgi->div (
			{ -name => 'message_' . $_ },
			$Cgi->h2({-name => 'quota_textarea_label'}, $main::text{'lbl_quota_' . $_} . ':'),
			$Cgi->textarea(
				-id     => 'message_' . $_,
				-name     => 'message_' . $_,
				-default  => $content,
				-rows     => 15,
				-columns  => 80,
			)
		);
	}

	print Yaffas::UI::end_section ();
	print Yaffas::UI::section_button(
		$Cgi->submit(
			{ -name => 'quota_msg', -value => $main::text{'lbl_save'} }
		)
	);
	print $Cgi->end_form();
}

sub database_settings {
	my $settings = Yaffas::Module::ZarafaConf::get_zarafa_database();

	print $Cgi->start_form({-action=>"zarafadb.cgi", -method=>"post"});
	print Yaffas::UI::section($main::text{lbl_database_settings},
		$Cgi->table(
			$Cgi->Tr(
				$Cgi->td($main::text{lbl_mysql_user}.":"),
				$Cgi->td(textfield({-name=>"mysql_user", -value => $settings->{user}}))
			),
			$Cgi->Tr(
				$Cgi->td($main::text{lbl_mysql_password}.":"),
				$Cgi->td(textfield({-name=>"mysql_password", -value => ""}))
			),
			$Cgi->Tr(
				$Cgi->td($main::text{lbl_mysql_host}.":"),
				$Cgi->td(textfield({-name=>"mysql_host", -value => $settings->{host}}))
			),
			$Cgi->Tr(
				$Cgi->td($main::text{lbl_mysql_database}.":"),
				$Cgi->td(textfield({-name=>"mysql_database", -value => $settings->{database}}))
			)
		)
	);
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_save'}}));
	print $Cgi->end_form();
}

sub prf_creator {
    my $settings = Yaffas::Module::ZarafaConf::get_zarafa_database();
    print $Cgi->start_form({-name=>"createprf", -action=>"createprf.cgi", -method=>"post"});

    print Yaffas::UI::section($main::text{lbl_prf_creator},
        $Cgi->p($main::text{lbl_outlook_start}),
        $Cgi->table(
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_homeserver}.":"),
                $Cgi->td(textfield({-name=>"homeserver", -value=>$ENV{SERVER_NAME}}))
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_connectiontype}.":"),
                $Cgi->td(scrolling_list({
                            -name=>"connectiontype",
                            -values=>[qw(0x000 0x580 0x80)],
                            -labels=>{
                                "0x580" => $main::text{lbl_connectiontype_cached},
                                "0x000" => $main::text{lbl_connectiontype_online},
                                "0x80" => $main::text{lbl_connectiontype_autodetect},
                                },
                            -size => 1
                            })
                    )
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_profilename}.":"),
                $Cgi->td(textfield({-name=>"profilename", -value => "Zarafa"}))
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_mailboxname}.":"),
                $Cgi->td(textfield({-name=>"mailboxname", -value => '%UserName%' }))
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_password}.":"),
                $Cgi->td(textfield({-name=>"password", -value => '' }))
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_overwriteprofile}.":"),
                $Cgi->td(radio_group({-name=>"overwriteprofile", -values => [qw(yes no)], -default=>"yes", -labels=> {yes => $main::text{lbl_yes}, no => $main::text{lbl_no}}}))
            ),
            $Cgi->Tr(
                $Cgi->td($main::text{lbl_backupprofile}.":"),
                $Cgi->td(radio_group({-name=>"backupprofile", -values => [qw(yes no)], -default=>"no", -labels=> {yes => $main::text{lbl_yes}, no => $main::text{lbl_no}}}))
            ),
        )
    );
    print Yaffas::UI::section_button($Cgi->button({-id=>"btncreateprf", -value=>$main::text{'lbl_download'}}));
    print $Cgi->end_form();

}

return 1;
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
