#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::UI;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::Mail;
use Yaffas::Module::ZarafaConf;

sub show_userfilter() {
	my @settings = Yaffas::Module::ZarafaConf::zarafa_ldap_filter();
	my $auth = Yaffas::Auth::get_auth_type();

	return if not $auth eq ADS;

	print "<script src='functions.js' type='text/javascript'></script>";
	print $Cgi->start_form({-action=>"filteruser.cgi"});
	print Yaffas::UI::section($main::text{lbl_userfilter},
							  $Cgi->table(
										  $Cgi->Tr([
												   _filtertype(\@settings),
												   _filtergroup(\@settings),
												   ])
										 )
							 );
	print Yaffas::UI::section_button($Cgi->button({-id=>"savefilter", -label=>$main::text{'lbl_save'}}));
	print $Cgi->end_form();
}

sub confirm_userfilter {
	my $filter = shift;
	my $group = shift;
	my $stores = shift;
	print Yaffas::UI::yn_confirm({
								 -action => "index.cgi",
								 -hidden => [filtertype => $filter, filtergroup => $group, userfilter => 1, confirmed => 1],
								 -title => $main::text{lbl_confirm_filter_save},
								 -yes => $main::text{lbl_yes},
								 -no => $main::text{lbl_no},
								 },
								 $main::text{lbl_confirm_msg},
								 $Cgi->ul($Cgi->li($stores))
								);
}

sub _filtertype {
	my $settings = shift;
	return $Cgi->td([$main::text{lbl_filtertype}.":",
					$Cgi->scrolling_list({
										 -id=>"filtertype",
										 -name=>"filtertype",
										 -values=>[0..2],
										 -labels=>{map {$_ => $main::text{"lbl_ldapfilter_type_".$_}} (0..2)},
										 -default=>$settings->[0],
										 -size=>1,
										 -onChange=>"javascript:toggle_filtergroup(this.value)",
										 })
					]);
}

sub _filtergroup {
	my $settings = shift;
	
	if ($settings->[0] == Yaffas::Module::ZarafaConf::FILTERTYPE->{ADGROUP}) {
	}
	return $Cgi->td({-class=>"filtergroup"}, [$main::text{lbl_filtergroup}.":",
					$Cgi->scrolling_list({
										 -id=>"filtergroup",
										 -name=>"filtergroup",
										 -values=>[Yaffas::UGM::get_groups()],
										 -default=>$settings->[1],
										 -size=>1,
										 }),
										 $Cgi->span({-id=>"filtersetting", class=>"hidden"}, $settings->[0])
					]);
}

sub show_attachment_size(;$) {
	my $value = shift;

	$value = Yaffas::Module::ZarafaConf::attachment_size() unless defined $value;
	print $Cgi->start_form({-action=>"attachment.cgi"});
	print Yaffas::UI::section($main::text{lbl_attachment_size},
							  $Cgi->table(
										  $Cgi->Tr([
												   $Cgi->td([
															$main::text{lbl_size}.":",
															$Cgi->textfield({-name=>"size", -value=>$value}),
															"MB"
														   ]),
												   ])
										 )
							 );
	print Yaffas::UI::section_button($Cgi->submit({-name=>"attachment_size", -value=>$main::text{'lbl_save'}}));
	print $Cgi->end_form();
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
			$Cgi->h2 ({-name => 'quota_textarea_label'}, $main::text{'lbl_quota_' . $_} . ':'),
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

sub defaultquota_form {
	my $quota = Yaffas::Mail::get_default_quota(); # in kB

	if (defined($main::in{limit})) {
	    $quota = $main::in{limit}
	}elsif($quota == -1){
	    undef $quota;
	}else{
	    $quota /= 1024;
	}

	print $Cgi->start_form("post", "quota.cgi");
	print Yaffas::UI::section(
				  $main::text{'lbl_default_quota_header'},

				  $Cgi->p($Cgi->input({
							   -type => 'radio',
							   -name => 'quota',
							   -value => 'noquota',
							   (defined $quota ? () : (-checked => 'checked')),
							  }),
				  $main::text{lbl_no_quota},

				  $Cgi->br(),
				  $Cgi->input({
							   -type => 'radio',
							   -name => 'quota',
							   -value => 'yesquota',
							   (defined $quota ? (-checked => 'checked') : ()),
							  }),
				  $Cgi->textfield(
								  -name => 'limit',
								  -default => (defined $quota?$quota:""),
								 ),
				  "MB",
				 ));
	print Yaffas::UI::section_button(
						 $Cgi->submit({ -name => 'default_quota', -value => $main::text{lbl_save}} )
						);
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
