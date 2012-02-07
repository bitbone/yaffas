#!/usr/bin/perl
use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::UI qw($Cgi section start_section end_section section_button textfield checkbox);
use Yaffas::Product qw(check_product);
use Yaffas::Module::Security;

my @dnsbl_policy = (
	[ $main::text{'lbl_host'}, 'dnsbl_host', ''],
	[ $main::text{'lbl_hit'}, 'dnsbl_hit', ''],
	[ $main::text{'lbl_miss'}, 'dnsbl_miss', ''],
	[ $main::text{'lbl_log'}, 'dnsbl_log', '']);

my @rhsbl_policy = (
	[ $main::text{'lbl_host'}, 'rhsbl_host',''],
	[ $main::text{'lbl_hit'}, 'rhsbl_hit',''],
	[ $main::text{'lbl_miss'}, 'rhsbl_miss',''],
	[ $main::text{'lbl_log'}, 'rhsbl_log','']);


sub _activator {
	my $module = shift || die "no module given";
	my ($label, $status);

	if($module eq 'policy'){
		$status = Yaffas::Module::Security::check_policy();
		$label = $main::text{ $status ? 'lbl_policy_disable' : 'lbl_policy_enable'};
	} elsif($module eq 'spam'){
		$status = Yaffas::Module::Security::check_spam();
		$label = $main::text{ $status ? 'lbl_sa_disable' : 'lbl_sa_enable'};
	} elsif($module eq 'antivirus'){
		$status = Yaffas::Module::Security::check_antivirus();
		$label = $main::text{ $status ? 'lbl_clamav_deactivate' : 'lbl_clamav_activate'};
	} else {
		die "unknown module";
	}

	return $Cgi->p($Cgi->button({-id => "status_$module", -value => $label}));
}

sub _policy_form {
	my @form = @_;

	my $ret = $Cgi->start_table();
	foreach my $r (@form){
		$ret .= $Cgi->Tr(
			$Cgi->td([$r->[0], $Cgi->textfield({-id => $r->[1], -value=>$r->[2]})])
		);
	}
	$ret .= $Cgi->end_table();
	return $ret;
}

sub policy(){
	my $enabled = Yaffas::Module::Security::check_policy();

	print start_section($main::text{lbl_policy});
	print $Cgi->h2($main::text{ $enabled ? 'lbl_policy_disable' : 'lbl_policy_enable' }),
		  _activator("policy");

	print $Cgi->hidden({-name=>'s_policy',-id=>'s_policy',-value=> $enabled ? 1 : 0});
	print $Cgi->start_div({-id=>'policy_show', -style => 'display:'. ($enabled ? 'block' : 'none') .';'}),
		  $Cgi->h2($main::text{lbl_dnsbl}),
		  $Cgi->div({-id=>'dnsbl_dialog'}, 
				  $Cgi->div({-class=>'hd'}, $main::text{lbl_add}).
				  $Cgi->div({-class=>'bd'}, _policy_form(@dnsbl_policy))
				  ),
		  $Cgi->p($Cgi->button({-id => 'dnsbl_add', -value => $main::text{'lbl_add'}})),
		  $Cgi->div({-id=>'dnsbl'}, ""),
		  $Cgi->div({-id=>'dnsbl_menu'},""),
		  $Cgi->h2($main::text{lbl_rhsbl}),
		  $Cgi->div({-id=>'rhsbl_dialog'}, 
				  $Cgi->div({-class=>'hd'}, $main::text{lbl_add}).
				  $Cgi->div({-class=>'bd'}, _policy_form(@rhsbl_policy))
				  ),
		  $Cgi->p($Cgi->button({-id => 'rhsbl_add', -value => $main::text{'lbl_add'}})),
		  $Cgi->div({-id=>'rhsbl'}, ""),
		  $Cgi->end_div();

	print end_section();
}

sub antispam(){
	my $enabled = Yaffas::Module::Security::check_spam();
	my $spam_headers = Yaffas::Module::Security::sa_tag2_level();

	print start_section($main::text{'lbl_sa'});
	print $Cgi->h2($main::text{ $enabled ? 'lbl_sa_disable' : 'lbl_sa_enable' }),
		  _activator("spam");

	print $Cgi->hidden({-name=>'s_spam',-id=>'s_spam',-value=>($enabled ? 1 : 0)});
	print $Cgi->start_div({-id=>'spam_show', -style => 'display:'. ($enabled ? 'block' : 'none') .';'});
	print $Cgi->h2($main::text{'lbl_sa_update'}),
		  $Cgi->p($Cgi->button({-id=>'sa_update',-value => $main::text{'lbl_update'}}));

	print $Cgi->h2($main::text{'lbl_sa_configure'});
	print $Cgi->table(
				$Cgi->Tr([
					$Cgi->td([$main::text{lbl_add_headers}, textfield({-id=>'spam_headers',-name=>'spam_headers',-value=>$spam_headers})])
				])
			),
			$Cgi->p($Cgi->button({-id=>'spam_submit',-value=>$main::text{'lbl_apply'}}));

	print $Cgi->h2($main::text{'lbl_trusted'}),
		  $Cgi->div({-id=>'sa_trusted_dialog'}, 
				  $Cgi->div({-class=>'hd'}, $main::text{lbl_add}).
				  $Cgi->div({-class=>'bd'}, 
					  $Cgi->table($Cgi->Tr($Cgi->td([$main::text{'lbl_network'}, textfield({-id => 'sa_trusted_net', -name=>'sa_trusted_net', -value=>''})])))
				  )
		  ),
		  $Cgi->p($Cgi->button({-id => 'sa_trusted_add', -value => $main::text{'lbl_add'}})),
		  $Cgi->div({-id=>'sa_trusted'}, ""),
		  $Cgi->div({-id=>'sa_trusted_menu'},"");

	print $Cgi->end_div();

	print end_section();
}

sub antivirus(){
	my $enabled = Yaffas::Module::Security::check_antivirus();
	my $scan_archive = Yaffas::Module::Security::clam_scan_archive();
	my $max_length = Yaffas::Module::Security::clam_max_length();
	my $virusalert = Yaffas::Module::Security::amavis_virusalert();

	print start_section($main::text{'lbl_clamav'});

	print $Cgi->h2($main::text{$enabled ? 'lbl_clamav_deactivate' : 'lbl_clamav_activate'}),
		  _activator("antivirus");

	print $Cgi->hidden({-name=>'s_antivirus',-id=>'s_antivirus',-value=>($enabled ? 1 : 0)});
	print $Cgi->start_div({-id=>'antivirus_show', -style => 'display:'. ($enabled ? 'block' : 'none') .';'});
	print $Cgi->h2($main::text{'lbl_clam_configure'});
	print $Cgi->table(
				$Cgi->Tr([
					$Cgi->td([$main::text{lbl_archive}, checkbox({-id=>'archive',-name=>'archive',-checked=>($scan_archive ? 1 : 0),-label=>""})]),
					$Cgi->td([$main::text{lbl_maxlength}, textfield({-id=>'max_length',-name=>'max_length',-value=>$max_length})]),
					$Cgi->td([$main::text{lbl_virusalert}, textfield({-id=>'virusalert',-name=>'virusalert',-value=>$virusalert})])
				])
			),
			$Cgi->p($Cgi->button({-id=>'av_submit',-value=>$main::text{'lbl_apply'}}));
			#$Cgi->h2($main::text{'lbl_clam_update'}),
			#$Cgi->button({-id=>'av_update',-value=>$main::text{'lbl_update'}});

	print $Cgi->end_div();
	print end_section();
}

sub whitelist(){
    print Yaffas::UI::section($main::text{'lbl_whitelist'},
        $Cgi->div(
            $Cgi->h2($main::text{'lbl_wl_desc'}),
            $Cgi->p($Cgi->button({-id => 'whitelist_add', -value => $main::text{'lbl_add'}})),
            $Cgi->div({-id=>'whitelist'}, ""),
            $Cgi->div({-id=>'whitelist_menu'},""),
        ),

        $Cgi->div({-id=>'whitelist_dialog'}, 
            $Cgi->div({-class=>'hd'}, $main::text{'lbl_add'}),
            $Cgi->div({-class=>'bd'}, _policy_form([$main::text{'lbl_wl_entry'},'whitelist_entry','']))
        ),
    );
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
