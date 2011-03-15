# file bbmailq-forms.pl
# for all my bbmailq forms

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Yaffas::UI qw($Cgi creating_cache_finish creating_cache_start);
use Yaffas::Module::Mailq;
use Yaffas::UI::TablePaging qw(show_page match fetch store);
use Yaffas::Product qw(check_product);
use Yaffas::Constant;

our $Cgi = $Yaffas::UI::Cgi;

sub print_mailq() {
	my $form = $Cgi->start_form({-action=>"forward.cgi"});
	$form .= $main::text{lbl_email}.":".$Cgi->textfield({-id=>"email", -name=>'email', -size=>50, -maxlength=>200});
	$form .= $Cgi->hidden({-id=>'mailid'});
	$form .= $Cgi->end_form();
	
	print Yaffas::UI::section(
		$main::text{'lbl_mails'},
		$Cgi->div({-id=>"menu"}, ""),
		$Cgi->div({-id=>"table"}, ""),
		$Cgi->div({-id=>"forwardform"},
			$Cgi->div({-class=>"hd"}, $main::text{lbl_dequeue}),
			$Cgi->div({-class=>"bd"}, $form)
		)
	);
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
