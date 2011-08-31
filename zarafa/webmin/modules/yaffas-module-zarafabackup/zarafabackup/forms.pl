use strict;
use warnings;

use Yaffas::Module::ZarafaBackup;
use Yaffas::UI qw($Cgi section section_button table yn_confirm creating_cache_finish creating_cache_start textfield);

sub show_index {
    print Yaffas::UI::section($main::text{lbl_overwiew_title},
        $Cgi->div({-id=>"backuplayout", -style=>"height: 600px"},
            $Cgi->div({-id=>"backupselectpane"},
                $Cgi->p(
                    $main::text{lbl_select_backupdate}.":",
                    $Cgi->scrolling_list({-id=>"backupselect", -values => [""]}, ""),
                )
            ),
            $Cgi->div({-id=>"folderpane"}, ""),
            $Cgi->div({-id=>"mainpane"}, ""),
        )
    );

    print Yaffas::UI::section($main::text{lbl_restore_title},
            $Cgi->div({-id=>"restorepane"},
                $Cgi->p(
                    $Cgi->button({-id=>"btn_restore", -value => $main::text{lbl_restore}}),
                    $Cgi->button({-id=>"btn_clear", -value => $main::text{lbl_clear}}),
                ),
                $Cgi->div({-id=>"lst_restore"}, ""),
            ),
                $Cgi->div({-id=>"restoredlg"},
                    $Cgi->div({-class=>"hd", -id=>"restorehd"}, $main::text{lbl_restore_start}),
                    $Cgi->div({-class=>"bd", -id=>"restorebd"},
                        $Cgi->div({-id=>"restoreloading"}, ""),
                        $Cgi->div({-id=>"restoremessage"}, $main::text{lbl_restore_start_msg})
                    )
                ),
    );

    my $settings = Yaffas::Module::ZarafaBackup::settings();

    print $Cgi->start_form({ -action => "settings.cgi", -method => "POST" });
    print Yaffas::UI::section($main::text{lbl_settings_title},
        $Cgi->h2($main::text{lbl_backup_date}),
        $Cgi->table(
            $Cgi->Tr(
                $Cgi->td([
                    $main::text{lbl_backup_full}.":",
                    show_select_days("full", $settings->{full}->{days}),
                    $main::text{lbl_at},
                    show_select_time("full", $settings->{full}->{hour}, $settings->{full}->{min})
                    ]
                ),
            ),
            $Cgi->Tr(
                $Cgi->td([
                    $main::text{lbl_backup_diff}.":",
                    show_select_days("diff", $settings->{diff}->{days}),
                    $main::text{lbl_at},
                    show_select_time("diff", $settings->{diff}->{hour}, $settings->{diff}->{min})
                    ]
                ),
            )
        ),

        $Cgi->h2($main::text{lbl_settings}),
        $Cgi->table(
            $Cgi->Tr([
                $Cgi->td([$main::text{lbl_backup_dir}.":", textfield({-name=>"backup_dir", -value => $settings->{global}->{dir}})]),
                $Cgi->td([$main::text{lbl_preserve_time}.":", textfield({-name=>"preserve_time", -value => $settings->{global}->{preserve_time}})]),
                ]
            )
        ),

    );
    print Yaffas::UI::section_button(
        $Cgi->submit({-value => $main::text{lbl_save}})
    );
    print $Cgi->end_form();
}

sub show_select_days {
    my $type = shift;
    my $selected = shift;
    my $ret;

    $ret = $Cgi->checkbox_group({
            -name => "days_$type",
            -values => [(0..6)],
            -default => $selected,
            -linebreak => 1,
            -labels => { map {("$_" => $main::text{"day_".$_})} (0..6) },
        }
    );

    return $ret;
}

sub show_select_time {
    my $type = shift;
    my $hour = shift;
    my $min = shift;
    return $Cgi->input({-name => "hour_$type", -size => 2, -value => $hour }).":".$Cgi->input({-name => "min_$type", -size => 2, -value => $min });
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
