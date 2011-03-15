#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::Module::Notify;
use Yaffas::UI qw(section section_button);

sub notify_mail() {
	my $notify_mail = shift || Yaffas::Module::Notify::_get_notify_mail();
	
	print $Cgi->start_form( {-action=>"check_notify.cgi"} );
	print Yaffas::UI::section($main::text{lbl_status},
							  $Cgi->table(
										  $Cgi->Tr(
												   $Cgi->td($main::text{lbl_mail}.":"),
												   $Cgi->td(
															$Cgi->textfield(-name=>'email',
																			-value=>$notify_mail,
																			-size=>30,
																			-maxlength=>200),
														   ),
												  ),
										   _send_mail_on(),
										 )
							 );
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_save'}}));
	print $Cgi->end_form();
}

sub _send_mail_on()
{
	my @ret_array = ();

	my $notify_type = Yaffas::Module::Notify::_get_notify_type();
	
	if (Yaffas::Product::check_product('fax'))
	{
		push @ret_array, $Cgi->Tr(
								  $Cgi->td( $main::text{lbl_send_mail}.":"),
								  $Cgi->td(
										   $Cgi->popup_menu(
															-name=>'send_mail_on',
															-values=>['always','never','errors'],
															-default=>$notify_type,
															-labels=>{always=>"$main::text{lbl_always}",
															errors=>"$main::text{lbl_errors}",
															never=>"$main::text{lbl_never}"},
														   )
										  )
								 );
	}
	return @ret_array;
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
