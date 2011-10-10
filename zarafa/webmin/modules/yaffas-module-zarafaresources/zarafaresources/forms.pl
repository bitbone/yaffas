#!/usr/bin/perl

use strict;
use warnings;

use Yaffas::Module::About;
use Yaffas::UI qw(section section_button textfield checkbox);
use Yaffas::UI::TablePaging qw(show_page match);
use Yaffas::Module::ZarafaResources;
use Sort::Naturally;

sub show_zarafa_resources () {
	print Yaffas::UI::section($main::text{lbl_resourcemanagement},
		$Cgi->div({-id=>"table"}, ""),
		$Cgi->div({-id=>"menu"}, "")
	);
}

sub show_edit_zarafa_resource (@) {
	my @resources = @_;

	my $create = 0;
	unless ( scalar @resources ) {
		@resources = (undef);
		$create    = 1;
	}

	my $is_local_auth = Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP || Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES;

	return if ($create == 1 && ! $is_local_auth);

	if ($create) {
		print $Cgi->start_form ( "post", "create.cgi" );
	}
	else {
		print $Cgi->start_form ( "post", "edit.cgi" );
	}

	foreach my $resource (@resources) {
		chomp($resource);
		my %details = (
			$create
			? ()
			: Yaffas::Module::ZarafaResources::get_resource_details($resource)
		);
		unless ($create) {
			print $Cgi->hidden ( 'resource', $resource );
		}
		print section (
			(
				  $create ? $main::text{lbl_newresource}
				: $main::text{lbl_editresource} . ': ' . $resource
			),
			$Cgi->table(
				$Cgi->Tr(
					[
						$Cgi->td(
							[
								$main::text{lbl_resource} . ':',
								(
									$create ? textfield(
										-name      => 'name',
										-maxlength => 100
									  )
									: $resource
								)
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_description} . ':',
								(
								$is_local_auth ?
								textfield(
												-name => 'description'
												. ( $create ? '' : '_' . $resource ),
												-value   => $details{description},
												-maxlength => 100
											   )
								:
								$details{description}
								)
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_decline_conflict} . ':',
								checkbox(
									-name => 'decline_conflict'
									  . ( $create ? '' : '_' . $resource ),
									-label   => '',
									-value   => 'yes',
									-checked => $details{decline_conflict}
								)
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_decline_recurring} . ':',
								checkbox(
									-name => 'decline_recurring'
									  . ( $create ? '' : '_' . $resource ),
									-label   => '',
									-value   => 'yes',
									-checked => $details{decline_recurring}
								)
							]
						)
					]
				)
			)
		);
	}

	print section_button( $Cgi->submit( "btnaction", $main::text{lbl_save} ) );
	print $Cgi->end_form ();
}

1;
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
