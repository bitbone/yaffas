#!/usr/bin/perl -w
use warnings;
use strict;

use Yaffas::UI;
sub show_dialog() {

	print $Cgi->start_form("post", "index.cgi");
	print Yaffas::UI::section(
		$main::text{'index_bulk'},
			$Cgi->table(
				$Cgi->Tr([
					$Cgi->td([
						$main::text{index_from}.":",
						$Cgi->textfield("from", $main::in{'from'}, 50),
					]),
					$Cgi->td([
						$main::text{index_subject}.":",
						$Cgi->textfield("subject",  $main::in{'subject'}, 50),
					]),
					$Cgi->td([
						$main::text{index_message}.":",
						$Cgi->textarea("message",  $main::in{'message'}, 15, 80),
					]),
				])
			),
		);
	print Yaffas::UI::section_button($Cgi->submit("submit", $main::text{index_send}) );
	print $Cgi->end_form();
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
