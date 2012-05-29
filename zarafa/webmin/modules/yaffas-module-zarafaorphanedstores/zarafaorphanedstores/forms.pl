#!/usr/bin/perl

use strict;
use warnings;

use Yaffas::Module::About;
use Yaffas::UI qw(section section_button);
use Yaffas::Module::ZarafaOrphanedStores;
use Sort::Naturally;

sub show_zarafa_orphaned {
	print Yaffas::UI::section($main::text{lbl_orphanedstores},
		$Cgi->div({-id=>"table"}, ""),
		$Cgi->div({-id=>"hookToUser", -class=>"yui-pe-content"},
#			$Cgi->div({-class=>"hd"}),
#			$Cgi->div({-class=>"bd"},
#				$Cgi->start_form(-method=>"post", -action=>"/zarafaorphanedstores/hook.cgi",-name=>"hook_orphan"),
#				$Cgi->div({-id=>"userdata"}, ""),
#				$Cgi->end_form()
#			),
		),
		$Cgi->div({-id=>"menu"}, ""),
	);
}

sub show_hook_zarafa_orphaned {
	my @orphans = @_;
	foreach my $orphan(@orphans) {
		print $Cgi->start_form("post", "hook.cgi");
		print section($main::text{lbl_hook_orphan});
		print $Cgi->hidden ( 'orphans', $orphan );
		print $Cgi->table(
			$Cgi->Tr(
				$Cgi->td([$main::text{lbl_orphan_id}.": ", $orphan])
			)
		);
		print $Cgi->table(
			$Cgi->Tr(
				$Cgi->td([$main::text{lbl_hook_to_user}])
			),
			$Cgi->Tr(
				$Cgi->td(
					$Cgi->div({-id=>"userdata"}, "")
				)
			)
		);
		print section_button( $Cgi->submit( "btnaction", $main::text{lbl_hook} ) );
		print $Cgi->end_form ();
	}
}

1;

