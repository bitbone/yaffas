#!/usr/bin/perl -w

package Yaffas::UI::Help;
use strict;
use Yaffas::Constant;
use Yaffas::File;
use Yaffas::UI;
use Yaffas::UI::Webmin;

sub add_help($$$);
sub show_help_button($);

=pod

=head1 NAME

Yaffas::Help - Online Help functions

=head1 SYNOPSIS

 add_help($$)
 show_help_button($)

=head1 DESCRIPTION

Yaffas::Help is an easy Module for Help messages in Webmin.

To use this module you have to the following things:

 - Create "<module>/help/<language>/" dir.
 - You can create as many help files as you want in this directory.
 - To use one of the help messages defined in your helpfile you have to call footer() with
    "filename" as your third parameter
 - Your file have to look like this.

	help_key1=text
	text
	text
	--
	help_key2=text
	text
	text
	--

 - To show a button which will open your helpmessage just use show_help_button("help_key1"), with
    your key from your file.

 - Note: don't forget the "help_" at every key. It is _really_ important!

=head1 METHODS

=over

=item add_help_msg ( MODULE, SCRIPTNAME, LANG )

Adds all help messages for of this module for the script in that language

=cut

sub add_help($$$) {
	my $module = shift;
	my $script = shift;
	my $lang = shift;

	unless (defined($module) && defined($script) && defined($lang)) {
		return undef;
	}

	my $file = Yaffas::File->new(Yaffas::Constant::DIR->{'webmin_prefix'}."$main::gconfig{product}/$module/help/$lang/$script");

	if (defined($file)) {
		my @tmp;
		my $id;
		foreach my $line ($file->get_content()) {
			if ($line =~ /^(help_.*)=(.*)$/) {
				@tmp = ();
				@tmp = $2."<br />" if $2;
				$id = $1;
			} elsif ($line =~ /^--\s*$/) {
				_gen_help_msg($id, @tmp);
			} else {
				push @tmp, $line;
				push @tmp, $Cgi->br() unless ($line =~ /^<.*>$/);
			}
		}
		return 1;
	}
	return undef;
}

=item show_help_button ( ID )

Shows the button for help

Important: ID have to begin with "help_"

=cut

sub show_help_button($) {
	my $id = shift;
	return undef if (!$id);
	my $lang = Yaffas::UI::Webmin::get_lang_name();
	return $Cgi->a({-style=>"color: #0055ff;", -href=>"javascript:openHelp('$id')"},
				   "&nbsp;",
				   $Cgi->img({-alt=>"help", -src=>"/images/help_$lang.gif"})
				  );
}

# print out message
sub _gen_help_msg ($@) {
	my $id = shift;
	my @msg = @_;

	return undef if (!$id);
	print $Cgi->div(
		{-class=>"help", -id=>$id},
		$Cgi->div(
				  $main::text{lbl_help},
				  $Cgi->a({-class=>"close", -href=>"javascript:closeHelp('$id')"},
						  $main::text{lbl_close}
						 )
				  ),
		@msg
	);
}

1;

=back

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
