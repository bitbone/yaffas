#!/usr/bin/perl -w
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use strict;
use warnings;
use Yaffas;
use Yaffas::UI qw(section ok_box error_box section_button);

our $cgi = $Yaffas::UI::Cgi;

sub index_dlg()
{
	print $Cgi->start_form(-action => 'create.cgi', -method => 'post');
	print section($main::text{'lbl_dump'}, '<iframe style="display: none" src="blank.html" id="createframe"></iframe>');
	print section_button($Cgi->button({-id=>'create', -label=>$main::text{'save'}}));
	print $Cgi->end_form();

	print $Cgi->start_multipart_form(-action => 'restore.cgi', -method => 'post');
	print section($main::text{'lbl_restore'}, $Cgi->filefield('backup'));
	print section_button($Cgi->submit('restore', $main::text{'send'}));
	print $Cgi->end_multipart_form();
	
}
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
