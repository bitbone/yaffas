#!/usr/bin/perl -w
use strict;
use warnings;
use Yaffas;
use Yaffas::UI qw($Cgi textfield);
use Yaffas::UI::TablePaging qw(show_page);
use Yaffas::Service qw(/.+/);
use Yaffas::Module::Time;

sub services_dlg() {
	print Yaffas::UI::section(
		$main::text{'index_header'},
		$Cgi->div( { -id => "table" }, "" ),
		$Cgi->div( { -id => "menu" },  "" )
	);
}

sub shutdown_dlg() {
	print Yaffas::UI::section(
		$main::text{lbl_shutdown},
		$Cgi->div(
			{ class => 'sbutton' },
			$Cgi->button( { -id => 'halt', -label => $main::text{lbl_halt} } ),
			$Cgi->button(
				{ -id => 'reboot', -label => $main::text{lbl_reboot} }
			)
		)
	);
}

sub datetime_dlg {
	my %src       = Yaffas::Module::Time::get_time();
	my %assoc_day = (
		"Mon", $main::text{'day_1'}, "Tue", $main::text{'day_2'},
		"Wed", $main::text{'day_3'}, "Thu", $main::text{'day_4'},
		"Fri", $main::text{'day_5'}, "Sat", $main::text{'day_6'},
		"Sun", $main::text{'day_0'}
	);

	my %assoc_month = (
		"Jan", "01", "Feb", "02", "Mar", "03", "Apr", "04",
		"May", "05", "Jun", "06", "Jul", "07", "Aug", "08",
		"Sep", "09", "Oct", "10", "Nov", "11", "Dec", "12"
	);

	print $Cgi->start_form( "post", "set_datetime.cgi" );

	print Yaffas::UI::section(
		$main::text{lbl_setdatetime},
		$Cgi->table(
			$Cgi->Tr(
				$Cgi->th(
					[
						$main::text{lbl_day},   $main::text{lbl_date},
						$main::text{lbl_month}, $main::text{lbl_year},
						$main::text{lbl_hour}
					]
				),
			),
			$Cgi->Tr(
				$Cgi->td(
					[
						$assoc_day{ $src{day} },
						$Cgi->popup_menu(
							{
								-name    => "date",
								-default => $src{date},
								-values  => [ ( 1 .. 31 ) ]
							}
						),
						$Cgi->popup_menu(
							{
								-name    => "month",
								-default => $assoc_month{ $src{'month'} },
								-values =>
								  [ map { sprintf "%02s", $_ } ( 1 .. 12 ) ],
								-labels => {
									map {
										sprintf( "%02s", $_ ),
										  $main::text{"month_$_"}
									  } ( 1 .. 12 )
								}
							}
						),
						$Cgi->popup_menu(
							{
								-name    => "year",
								-default => $src{year},
								-values  => [ ( 1970 .. 2037 ) ]
							}
						),    # positiver unix time bereich
					]
				),
				$Cgi->td(
					$Cgi->popup_menu(
						{
							-name    => "hour",
							-default => $src{hour},
							-values =>
							  [ map { sprintf "%02s", $_ } ( 0 .. 23 ) ]
						}
					),
					":",
					$Cgi->popup_menu(
						{
							-name    => "minute",
							-default => $src{minute},
							-values =>
							  [ map { sprintf "%02s", $_ } ( 0 .. 59 ) ]
						}
					),
					":",
					$Cgi->popup_menu(
						{
							-name    => "second",
							-default => $src{second},
							-values =>
							  [ map { sprintf "%02s", $_ } ( 0 .. 59 ) ]
						}
					)
				)
			)
		)
	);

	print Yaffas::UI::section_button( $Cgi->submit( $main::text{lbl_save} ) );

	print $Cgi->end_form();
}

sub timeserver_dlg {

	my ( $hour, $minute );
	my $type = "n"; # never
	my $cronjob = Yaffas::Module::Time::get_cron_values();

	if ($cronjob) {
		$type = $cronjob->{hour} eq "*" ? "h" : "d";
		$hour = $cronjob->{hour};
		$minute = $cronjob->{minute};
	}
	
	my $timeserver = Yaffas::Module::Time::get_timeserver();

	my $jscript_n =
"if(this.checked == true) {document.forms['autoupdate'].elements['hour'].disabled=1;document.forms['autoupdate'].elements['minute'].disabled=1;}";
	my $jscript_h =
"if(this.checked == true) {document.forms['autoupdate'].elements['hour'].disabled=1;document.forms['autoupdate'].elements['minute'].disabled=0;}";
	my $jscript_d =
"if(this.checked == true) {document.forms['autoupdate'].elements['hour'].disabled=0;document.forms['autoupdate'].elements['minute'].disabled=0;}";

	print $Cgi->start_form( { -action => "set_timeserver.cgi", -name => "autoupdate" } );
	my $dlg = $Cgi->table($Cgi->Tr($Cgi->td([
	  $main::text{lbl_timeserver} ,
	  textfield(
		{
			-name  => "timeserver",
			-value => $timeserver
		}
	  )])))
	 . $Cgi->input(
			{
				-type    => 'radio',
				-name    => 'sync_freq',
				-value   => 'once',
				-onclick => $jscript_n,
				( $type eq "n" ? ( -checked => "checked" ) : '' )
			},
			$main::text{'lbl_once'}
		  )
		  . $Cgi->br
		  . $Cgi->input(
			{
				-type    => 'radio',
				-name    => 'sync_freq',
				-value   => 'hourly',
				-onclick => $jscript_h,
				( $type eq "h" ? ( -checked => "checked" ) : '' )
			},
			$main::text{'lbl_every'}
		  )
		  . $Cgi->br
		  . $Cgi->input(
			{
				-type    => 'radio',
				-name    => 'sync_freq',
				-value   => 'daily',
				-onclick => $jscript_d,
				( $type eq "d" ? ( -checked => "checked" ) : '' )
			},
			$main::text{'lbl_daily'}
		  )
	  . $Cgi->p(
		$main::text{'lbl_hour'}
		  . $Cgi->popup_menu(
			{
				-name    => "hour",
				-values  => [ 0 .. 23 ],
				-default => $hour,
                ($type eq "h" or $type eq "n") ? (-disabled => "disabled") : (undef => undef),
			}
		  )
		  . $main::text{'lbl_minute'}
		  . $Cgi->popup_menu(
			{
				-name    => "minute",
				-values  => [ 0 .. 59 ],
				-default => $minute,
                 $type eq "n" ? (-disabled => "disabled") : (undef => undef),
			}
		  )
	  );
	print Yaffas::UI::section( $main::text{lbl_timeserver}, $dlg );
	print Yaffas::UI::section_button(
		$Cgi->submit(
			{
				-value => $main::text{lbl_save}
			}
		)
	);
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
