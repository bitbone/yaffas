# ui-lib.pl
# Common functions for generating HTML for Webmin user interface elements

####################### table generation functions

# ui_table_start(heading, [tabletags], [cols], [&default-tds])
# A table with a heading and table inside
sub ui_table_start
{
return &theme_ui_table_start(@_) if (defined(&theme_ui_table_start));
local ($heading, $tabletags, $cols, $tds) = @_;
local $rv;
$rv .= "<table class='ui_table' border $tabletags>\n";
$rv .= "<tr $tb> <td><b>$heading</b></td> </tr>\n" if (defined($heading));
$rv .= "<tr $cb> <td><table width=100%>\n";
$main::ui_table_cols = $cols || 4;
$main::ui_table_pos = 0;
$main::ui_table_default_tds = $tds;
return $rv;
}

# ui_table_end()
# The end of a table started by ui_table_start
sub ui_table_end
{
return &theme_ui_table_end(@_) if (defined(&theme_ui_table_end));
$main::ui_table_default_tds = undef;
return "</table></td></tr></table>\n";
}

# ui_columns_start(&headings, [width-percent], [noborder], [&tdtags], [heading])
# Returns HTML for a multi-column table, with the given headings
sub ui_columns_start
{
return &theme_ui_columns_start(@_) if (defined(&theme_ui_columns_start));
local ($heads, $width, $noborder, $tdtags, $heading) = @_;
local $rv;
$rv .= "<table".($noborder ? "" : " border").
		(defined($width) ? " width=$width%" : "")." class='ui_columns'>\n";
if ($heading) {
	$rv .= "<tr $tb><td colspan=".scalar(@$heads).
	       " class='ui_columns_heading'><b>$heading</b></td></tr>\n";
	}
$rv .= "<tr $tb class='ui_columns_heads'>\n";
local $i;
for($i=0; $i<@$heads; $i++) {
	$rv .= "<td ".$tdtags->[$i]."><b>".
	       ($heads->[$i] eq "" ? "<br>" : $heads->[$i])."</b></td>\n";
	}
$rv .= "</tr>\n";
return $rv;
}

# ui_columns_row(&columns, &tdtags)
# Returns HTML for a row in a multi-column table
sub ui_columns_row
{
return &theme_ui_columns_row(@_) if (defined(&theme_ui_columns_row));
local ($cols, $tdtags) = @_;
local $rv;
$rv .= "<tr $cb class='ui_columns_row'>\n";
local $i;
for($i=0; $i<@$cols; $i++) {
	$rv .= "<td ".$tdtags->[$i].">".
	       ($cols->[$i] !~ /\S/ ? "<br>" : $cols->[$i])."</td>\n";
	}
$rv .= "</tr>\n";
return $rv;
}

# ui_columns_header(&columns, &tdtags)
# Returns HTML for a row in a multi-column table, with a header background
sub ui_columns_header
{
return &theme_ui_columns_header(@_) if (defined(&theme_ui_columns_header));
local ($cols, $tdtags) = @_;
local $rv;
$rv .= "<tr $tb class='ui_columns_header'>\n";
local $i;
for($i=0; $i<@$cols; $i++) {
	$rv .= "<td ".$tdtags->[$i]."><b>".
	       ($cols->[$i] eq "" ? "<br>" : $cols->[$i])."</b></td>\n";
	}
$rv .= "</tr>\n";
return $rv;
}

# ui_checked_columns_row(&columns, &tdtags, checkname, checkvalue, [checked?])
# Returns HTML for a row in a multi-column table, in which the first
# column is a checkbox
sub ui_checked_columns_row
{
return &theme_ui_checked_columns_row(@_) if (defined(&theme_ui_checked_columns_row));
local ($cols, $tdtags, $checkname, $checkvalue, $checked) = @_;
local $rv;
$rv .= "<tr $cb class='ui_checked_columns'>\n";
$rv .= "<td class='ui_checked_checkbox' ".$tdtags->[0].">".
       &ui_checkbox($checkname, $checkvalue, undef, $checked)."</td>\n";
local $i;
for($i=0; $i<@$cols; $i++) {
	$rv .= "<td ".$tdtags->[$i+1].">";
	if ($cols->[$i] !~ /<a\s+href|<input|<select|<textarea/) {
		$rv .= "<label for=\"".
			&quote_escape("${checkname}_${checkvalue}")."\">";
		}
	$rv .= ($cols->[$i] !~ /\S/ ? "<br>" : $cols->[$i]);
	if ($cols->[$i] !~ /<a\s+href|<input|<select|<textarea/) {
		$rv .= "</label>";
		}
	$rv .= "</td>\n";
	}
$rv .= "</tr>\n";
return $rv;
}

# ui_radio_columns_row(&columns, &tdtags, checkname, checkvalue, [checked])
# Returns HTML for a row in a multi-column table, in which the first
# column is a radio button
sub ui_radio_columns_row
{
return &theme_ui_radio_columns_row(@_) if (defined(&theme_ui_radio_columns_row));
local ($cols, $tdtags, $checkname, $checkvalue, $checked) = @_;
local $rv;
$rv .= "<tr $cb class='ui_radio_columns'>\n";
$rv .= "<td class='ui_radio_radio' ".$tdtags->[0].">".
       &ui_oneradio($checkname, $checkvalue, "", $checked)."</td>\n";
local $i;
for($i=0; $i<@$cols; $i++) {
	$rv .= "<td ".$tdtags->[$i+1].">";
	if ($cols->[$i] !~ /<a\s+href|<input|<select|<textarea/) {
		$rv .= "<label for=\"".
			&quote_escape("${checkname}_${checkvalue}")."\">";
		}
	$rv .= ($cols->[$i] !~ /\S/ ? "<br>" : $cols->[$i]);
	if ($cols->[$i] !~ /<a\s+href|<input|<select|<textarea/) {
		$rv .= "</label>";
		}
	$rv .= "</td>\n";
	}
$rv .= "</tr>\n";
return $rv;
}

# ui_columns_end()
# Returns HTML to end a table started by ui_columns_start
sub ui_columns_end
{
return &theme_ui_columns_end(@_) if (defined(&theme_ui_columns_end));
return "</table>\n";
}

####################### form generation functions

# ui_form_start(script, method, [target], [tags])
# Returns HTML for a form that submits to some script
sub ui_form_start
{
return &theme_ui_form_start(@_) if (defined(&theme_ui_form_start));
local ($script, $method, $target, $tags) = @_;
local $rv;
$rv .= "<form class='ui_form' action='$script' ".
	($method eq "post" ? "method=post" :
	 $method eq "form-data" ?
		"method=post enctype=multipart/form-data" :
		"method=get").
	($target ? " target=$target" : "").
        " ".$tags.
       ">\n";
return $rv;
}

# ui_form_end([&buttons], [width])
# Returns HTML for the end of a form, optionally with a row of submit buttons
sub ui_form_end
{
return &theme_ui_form_end(@_) if (defined(&theme_ui_form_end));
local ($buttons, $width) = @_;
local $rv;
if ($buttons && @$buttons) {
	$rv .= "<table class='ui_form_end_buttons' ".($width ? " width=$width" : "")."><tr>\n";
	local $b;
	foreach $b (@$buttons) {
		if (ref($b)) {
			$rv .= "<td".(!$width ? "" :
				      $b eq $buttons->[0] ? " align=left" :
				      $b eq $buttons->[@$buttons-1] ?
					" align=right" : " align=center").">".
			       &ui_submit($b->[1], $b->[0], $b->[3], $b->[4]).
			       ($b->[2] ? " ".$b->[2] : "")."</td>\n";
			}
		elsif ($b) {
			$rv .= "<td>$b</td>\n";
			}
		else {
			$rv .= "<td>&nbsp;&nbsp;</td>\n";
			}
		}
	$rv .= "</tr></table>\n";
	}
$rv .= "</form>\n";
return $rv;
}

# ui_textbox(name, value, size, [disabled?], [maxlength], [tags])
# Returns HTML for a text input
sub ui_textbox
{
return &theme_ui_textbox(@_) if (defined(&theme_ui_textbox));
local ($name, $value, $size, $dis, $max, $tags) = @_;
$size = &ui_max_text_width($size);
return "<input name=\"".&quote_escape($name)."\" ".
       "value=\"".&quote_escape($value)."\" ".
       "size=$size ".($dis ? "disabled=true" : "").
       ($max ? " maxlength=$max" : "").
       " ".$tags.
       ">";
}

# ui_bytesbox(name, bytes, [size], [disabled?])
# Returns HTML for entering a number of bytes, but with friendly kB/MB/GB
# options. May truncate values to 2 decimal points!
sub ui_bytesbox
{
local ($name, $bytes, $size, $dis) = @_;
local $units = 1;
if ($bytes >= 10*1024*1024*1024) {
	$units = 1024*1024*1024;
	}
elsif ($bytes >= 10*1024*1024) {
	$units = 1024*1024;
	}
elsif ($bytes >= 10*1024) {
	$units = 1024;
	}
else {
	$units = 1;
	}
if ($bytes ne "") {
	$bytes = sprintf("%.2f", ($bytes*1.0)/$units);
	$bytes =~ s/\.00$//;
	}
$size = &ui_max_text_width($size || 8);
return &ui_textbox($name, $bytes, $size, $dis)." ".
       &ui_select($name."_units", $units,
		 [ [ 1, "bytes" ], [ 1024, "kB" ], [ 1024*1024, "MB" ],
		   [ 1024*1024*1024, "GB" ] ], undef, undef, undef, $dis);
}

# ui_upload(name, size, [disabled?], [tags])
# Returns HTML for a file upload input
sub ui_upload
{
return &theme_ui_upload(@_) if (defined(&theme_ui_upload));
local ($name, $size, $dis, $tags) = @_;
$size = &ui_max_text_width($size);
return "<input type=file name=\"".&quote_escape($name)."\" ".
       "size=$size ".
       ($dis ? "disabled=true" : "").
       ($tags ? " ".$tags : "").">";
}

# ui_password(name, value, size, [disabled?], [maxlength])
# Returns HTML for a password text input
sub ui_password
{
return &theme_ui_password(@_) if (defined(&theme_ui_password));
local ($name, $value, $size, $dis, $max) = @_;
$size = &ui_max_text_width($size);
return "<input type=password name=\"".&quote_escape($name)."\" ".
       "value=\"".&quote_escape($value)."\" ".
       "size=$size ".($dis ? "disabled=true" : "").
       ($max ? " maxlength=$max" : "").
       ">";
}

# ui_hidden(name, value)
# Returns HTML for a hidden field
sub ui_hidden
{
return &theme_ui_hidden(@_) if (defined(&theme_ui_hidden));
local ($name, $value) = @_;
return "<input type=hidden name=\"".&quote_escape($name)."\" ".
       "value=\"".&quote_escape($value)."\">\n";
}

# ui_select(name, value|&values, &options, [size], [multiple],
#	    [add-if-missing], [disabled?], [javascript])
# Returns HTML for a drop-down menu or multiple selection list
sub ui_select
{
return &theme_ui_select(@_) if (defined(&theme_ui_select));
local ($name, $value, $opts, $size, $multiple, $missing, $dis, $js) = @_;
local $rv;
$rv .= "<select name=\"".&quote_escape($name)."\"".
       ($size ? " size=$size" : "").
       ($multiple ? " multiple" : "").
       ($dis ? " disabled=true" : "")." ".$js.">\n";
local ($o, %opt, $s);
local %sel = ref($value) ? ( map { $_, 1 } @$value ) : ( $value, 1 );
foreach $o (@$opts) {
	$o = [ $o ] if (!ref($o));
	$rv .= "<option value=\"".&quote_escape($o->[0])."\"".
	       ($sel{$o->[0]} ? " selected" : "").">".
	       ($o->[1] || $o->[0])."\n";
	$opt{$o->[0]}++;
	}
foreach $s (keys %sel) {
	if (!$opt{$s} && $missing) {
		$rv .= "<option value=\"".&quote_escape($s)."\"".
		       "selected>".($s eq "" ? "&nbsp;" : $s)."\n";
		}
	}
$rv .= "</select>\n";
return $rv;
}

# ui_radio(name, value, &options, [disabled?])
# Returns HTML for a series of radio buttons
sub ui_radio
{
return &theme_ui_radio(@_) if (defined(&theme_ui_radio));
local ($name, $value, $opts, $dis) = @_;
local $rv;
local $o;
foreach $o (@$opts) {
	local $id = &quote_escape($name."_".$o->[0]);
	local $label = $o->[1] || $o->[0];
	local $after;
	if ($label =~ /^(.*?)((<a\s+href|<input|<select|<textarea)[\000-\377]*)$/i) {
		$label = $1;
		$after = $2;
		}
	$rv .= "<input type=radio name=\"".&quote_escape($name)."\" ".
               "value=\"".&quote_escape($o->[0])."\"".
	       ($o->[0] eq $value ? " checked" : "").
	       ($dis ? " disabled=true" : "").
	       " id=\"$id\"".
	       " $o->[2]> <label for=\"$id\">".
	       $label."</label>".$after."\n";
	}
return $rv;
}

# ui_radio_table(name, value, &options, [disabled?])
# Returns HTML for a series of radio buttons, one per line in a table
sub ui_radio_table
{
return &theme_ui_radio_table(@_) if (defined(&theme_ui_radio_table));
local ($name, $value, $opts, $dis) = @_;
local $rv = "<table>";
local $o;
foreach $o (@$opts) {
	local $id = &quote_escape($name."_".$o->[0]);
	local $label = $o->[1] || $o->[0];
	local $after;
	if ($label =~ /^([^<]*)(<[\000-\377]*)$/) {
		$label = $1;
		$after = $2;
		}
	$rv .= "<tr> <td>";
	$rv .= "<input type=radio name=\"".&quote_escape($name)."\" ".
               "value=\"".&quote_escape($o->[0])."\"".
	       ($o->[0] eq $value ? " checked" : "").
	       ($dis ? " disabled=true" : "").
	       " id=\"$id\"".
	       " $o->[3]> <label for=\"$id\">".
	       $label."</label>".$after."</td>\n";
	$rv .= "<td>$o->[2]</td>\n";
	$rv .= "</tr>\n";
	}
$rv .= "</table>\n";
return $rv;
}

# ui_yesno_radio(name, value, [yes], [no], [disabled?])
# Like ui_yesno, but always displays just two inputs (yes and no)
sub ui_yesno_radio
{
local ($name, $value, $yes, $no, $dis) = @_;
return &theme_ui_yesno_radio(@_) if (defined(&theme_ui_yesno_radio));
$yes = 1 if (!defined($yes));
$no = 0 if (!defined($no));
$value = int($value);
return &ui_radio($name, $value, [ [ $yes, $text{'yes'} ],
				  [ $no, $text{'no'} ] ], $dis);
}

# ui_checkbox(name, value, label, selected?, [tags], [disabled?])
# Returns HTML for a single checkbox
sub ui_checkbox
{
return &theme_ui_checkbox(@_) if (defined(&theme_ui_checkbox));
local ($name, $value, $label, $sel, $tags, $dis) = @_;
local $after;
if ($label =~ /^([^<]*)(<[\000-\377]*)$/) {
	$label = $1;
	$after = $2;
	}
return "<input type=checkbox name=\"".&quote_escape($name)."\" ".
       "value=\"".&quote_escape($value)."\" ".
       ($sel ? " checked" : "").($dis ? " disabled=true" : "").
       " id=\"".&quote_escape("${name}_${value}")."\"".
       " $tags> ".
       ($label eq "" ? $after :
	 "<label for=\"".&quote_escape("${name}_${value}").
	 "\">$label</label>$after")."\n";
}

# ui_oneradio(name, value, label, selected?, [tags], [disabled?])
# Returns HTML for a single radio button
sub ui_oneradio
{
return &theme_ui_oneradio(@_) if (defined(&theme_ui_oneradio));
local ($name, $value, $label, $sel, $tags, $dis) = @_;
local $id = &quote_escape("${name}_${value}");
local $after;
if ($label =~ /^([^<]*)(<[\000-\377]*)$/) {
	$label = $1;
	$after = $2;
	}
return "<input type=radio name=\"".&quote_escape($name)."\" ".
       "value=\"".&quote_escape($value)."\" ".
       ($sel ? " checked" : "").($dis ? " disabled=true" : "").
       " id=\"$id\"".
       " $tags> <label for=\"$id\">$label</label>$after\n";
}

# ui_textarea(name, value, rows, cols, [wrap], [disabled?], [tags])
# Returns HTML for a multi-line text input
sub ui_textarea
{
return &theme_ui_textarea(@_) if (defined(&theme_ui_textarea));
local ($name, $value, $rows, $cols, $wrap, $dis, $tags) = @_;
$cols = &ui_max_text_width($cols, 1);
return "<textarea name=\"".&quote_escape($name)."\" ".
       "rows=$rows cols=$cols".($wrap ? " wrap=$wrap" : "").
       ($dis ? " disabled=true" : "").
       ($tags ? " $tags" : "").">".
       &html_escape($value).
       "</textarea>";
}

# ui_user_textbox(name, value, [form], [disabled?])
# Returns HTML for a Unix user input
sub ui_user_textbox
{
return &theme_ui_user_textbox(@_) if (defined(&theme_ui_user_textbox));
return &ui_textbox($_[0], $_[1], 13, $_[3])." ".
       &user_chooser_button($_[0], 0, $_[2]);
}

# ui_group_textbox(name, value, [form], [disabled?])
# Returns HTML for a Unix group input
sub ui_group_textbox
{
return &theme_ui_group_textbox(@_) if (defined(&theme_ui_group_textbox));
return &ui_textbox($_[0], $_[1], 13, $_[3])." ".
       &group_chooser_button($_[0], 0, $_[2]);
}

# ui_opt_textbox(name, value, size, option1, [option2], [disabled?],
#		 [&extra-fields], [max])
# Returns HTML for a text field that is optional
sub ui_opt_textbox
{
return &theme_ui_opt_textbox(@_) if (defined(&theme_ui_opt_textbox));
local ($name, $value, $size, $opt1, $opt2, $dis, $extra, $max) = @_;
local $dis1 = &js_disable_inputs([ $name, @$extra ], [ ]);
local $dis2 = &js_disable_inputs([ ], [ $name, @$extra ]);
local $rv;
$size = &ui_max_text_width($size);
$rv .= &ui_radio($name."_def", $value eq '' ? 1 : 0,
		 [ [ 1, $opt1, "onClick='$dis1'" ],
		   [ 0, $opt2 || " ", "onClick='$dis2'" ] ], $dis)."\n";
$rv .= "<input name=\"".&quote_escape($name)."\" ".
       "size=$size value=\"".&quote_escape($value)."\" ".
       ($value eq "" || $dis ? "disabled=true" : "").
       ($max ? " maxlength=$max" : "").">\n";
return $rv;
}

# ui_submit(label, [name], [disabled?], [tags])
# Returns HTML for a form submit button
sub ui_submit
{
return &theme_ui_submit(@_) if (defined(&theme_ui_submit));
local ($label, $name, $dis, $tags) = @_;
return "<input type=submit".
       ($name ne '' ? " name=\"".&quote_escape($name)."\"" : "").
       " value=\"".&quote_escape($label)."\"".
       ($dis ? " disabled=true" : "").
       ($tags ? " ".$tags : "").">\n";
			
}

# ui_reset(label, [disabled?])
# Returns HTML for a form reset button
sub ui_reset
{
return &theme_ui_reset(@_) if (defined(&theme_ui_reset));
local ($label, $dis) = @_;
return "<input type=submit value=\"".&quote_escape($label).
       ($dis ? " disabled=true" : "")."\">\n";
			
}

# ui_date_input(day, month, year, day-name, month-name, year-name, [disabled?])
# Returns HTML for a date-selection field
sub ui_date_input
{
local ($day, $month, $year, $dayname, $monthname, $yearname, $dis) = @_;
local $rv;
$rv .= &ui_textbox($dayname, $day, 3, $dis);
$rv .= "/";
$rv .= &ui_select($monthname, $month,
		  [ map { [ $_, $text{"smonth_$_"} ] } (1 .. 12) ],
		  1, 0, 0, $dis);
$rv .= "/";
$rv .= &ui_textbox($yearname, $year, 5, $dis);
return $rv;
}

# ui_table_row(label, value, [cols], [&td-tags])
# Returns HTML for a row in a table started by ui_table_start, with a 1-column
# label and 1+ column value.
sub ui_table_row
{
return &theme_ui_table_row(@_) if (defined(&theme_ui_table_row));
local ($label, $value, $cols, $tds) = @_;
$cols ||= 1;
$tds ||= $main::ui_table_default_tds;
local $rv;
if ($main::ui_table_pos+$cols+1 > $main::ui_table_cols) {
	# If the requested number of cols won't fit in the number
	# remaining, start a new row
	$rv .= "</tr>\n";
	$main::ui_table_pos = 0;
	}
$rv .= "<tr>\n" if ($main::ui_table_pos%$main::ui_table_cols == 0);
$rv .= "<td valign=top $tds->[0]><b>$label</b></td>\n" if (defined($label));
$rv .= "<td valign=top colspan=$cols $tds->[1]>$value</td>\n";
$main::ui_table_pos += $cols+(defined($label) ? 1 : 0);
if ($main::ui_table_pos%$main::ui_table_cols == 0) {
	$rv .= "</tr>\n";
	$main::ui_table_pos = 0;
	}
return $rv;
}

# ui_table_hr()
sub ui_table_hr
{
return &theme_ui_table_hr(@_) if (defined(&theme_ui_table_hr));
local $rv;
if ($ui_table_pos) {
	$rv .= "</tr>\n";
	$ui_table_pos = 0;
	}
$rv .= "<tr> <td colspan=$main::ui_table_cols><hr></td> </tr>\n";
return $rv;
}

# ui_table_span(text)
# Outputs a table row that spans the whole table, and contains the given text
sub ui_table_span
{
local ($text) = @_;
return &theme_ui_table_hr(@_) if (defined(&theme_ui_table_hr));
local $rv;
if ($ui_table_pos) {
	$rv .= "</tr>\n";
	$ui_table_pos = 0;
	}
$rv .= "<tr> <td colspan=$main::ui_table_cols>$text</td> </tr>\n";
return $rv;
}

# ui_buttons_start()
sub ui_buttons_start
{
return &theme_ui_buttons_start(@_) if (defined(&theme_ui_buttons_start));
return "<table width=100%>\n";
}

# ui_buttons_end()
sub ui_buttons_end
{
return &theme_ui_buttons_end(@_) if (defined(&theme_ui_buttons_end));
return "</table>\n";
}

# ui_buttons_row(script, button-label, description, [hiddens], [after-submit],
#		 [before-submit]) 
sub ui_buttons_row
{
return &theme_ui_buttons_row(@_) if (defined(&theme_ui_buttons_row));
local ($script, $label, $desc, $hiddens, $after, $before) = @_;
return "<form action=$script>\n".
       $hiddens.
       "<tr> <td nowrap width=20% valign=top>".($before ? $before." " : "").
       &ui_submit($label).($after ? " ".$after : "")."</td>\n".
       "<td valign=top width=80% valign=top>$desc</td> </tr>\n".
       "</form>\n";
}

# ui_buttons_hr([title])
sub ui_buttons_hr
{
local ($title) = @_;
return &theme_ui_buttons_hr(@_) if (defined(&theme_ui_buttons_hr));
if ($title) {
	return "<tr> <td colspan=2><table cellpadding=0 cellspacing=0 width=100%><tr> <td width=50%><hr></td> <td nowrap>$title</td> <td width=50%><hr></td> </tr></table></td> </tr>\n";
	}
else {
	return "<tr> <td colspan=2><hr></td> </tr>\n";
	}
}

####################### header and footer functions

# ui_post_header([subtext])
# Returns HTML to appear directly after a standard header() call
sub ui_post_header
{
return &theme_ui_post_header(@_) if (defined(&theme_ui_post_header));
local ($text) = @_;
local $rv;
$rv .= "<center class='ui_post_header'><font size=+1>$text</font></center>\n" if (defined($text));
if (!$tconfig{'nohr'} && !$tconfig{'notophr'}) {
	$rv .= "<hr id='post_header_hr'>\n";
	}
return $rv;
}

# ui_pre_footer()
# Returns HTML to appear directly before a standard footer() call
sub ui_pre_footer
{
return &theme_ui_pre_footer(@_) if (defined(&theme_ui_pre_footer));
local $rv;
if (!$tconfig{'nohr'} && !$tconfig{'nobottomhr'}) {
	$rv .= "<hr id='pre_footer_hr'>\n";
	}
return $rv;
}

# ui_print_header(subtext, args...)
# Print HTML for a header with the post-header line. The args are the same
# as those passed to header()
sub ui_print_header
{
&load_theme_library();
return &theme_ui_print_header(@_) if (defined(&theme_ui_print_header));
local ($text, @args) = @_;
&header(@args);
print &ui_post_header($text);
}

# ui_print_unbuffered_header(subtext, args...)
# Like ui_print_header, but ensures that output for this page is not buffered
# or contained in a table.
sub ui_print_unbuffered_header
{
&load_theme_library();
return &theme_ui_print_unbuffered_header(@_) if (defined(&theme_ui_print_unbuffered_header));
$| = 1;
$theme_no_table = 1;
&ui_print_header(@_);
}

# ui_print_footer(args...)
# Print HTML for a footer with the pre-footer line. Args are the same as those
# passed to footer()
sub ui_print_footer
{
return &theme_ui_print_footer(@_) if (defined(&theme_ui_print_footer));
local @args = @_;
print &ui_pre_footer();
&footer(@args);
}

# ui_config_link(text, &subs)
# Returns HTML for a module config link. The first non-null sub will be
# replaced with the appropriate URL.
sub ui_config_link
{
return &theme_ui_config_link(@_) if (defined(&theme_ui_config_link));
local ($text, $subs) = @_;
local @subs = map { $_ || "../config.cgi?$module_name" }
		  ($subs ? @$subs : ( undef ));
return "<p>".&text($text, @subs)."<p>\n";
}

# ui_print_endpage(text)
# Prints HTML for an error message followed by a page footer with a link to
# /, then exits. Good for main page error messages.
sub ui_print_endpage
{
return &theme_ui_print_endpage(@_) if (defined(&theme_ui_print_endpage));
local ($text) = @_;
print $text,"<p class='ui_footer'>\n";
print "</p>\n";
&ui_print_footer("/", $text{'index'});
exit;
}

# ui_subheading(text, ...)
# Returns HTML for a section heading
sub ui_subheading
{
return &theme_ui_subheading(@_) if (defined(&theme_ui_subheading));
return "<h3 class='ui_subheading'>".join("", @_)."</h3>\n";
}

# ui_links_row(&links)
# Returns HTML for a row of links, like select all / invert selection / add..
sub ui_links_row
{
return &theme_ui_links_row(@_) if (defined(&theme_ui_links_row));
local ($links) = @_;
return @$links ? join("\n|\n", @$links)."<br>\n"
	       : "";
}

########################### collapsible section / tab functions

# ui_hidden_javascript()
# Returns <script> and <style> sections for hiding functions and CSS
sub ui_hidden_javascript
{
return &theme_ui_hidden_javascript(@_)
	if (defined(&theme_ui_hidden_javascript));
local $rv;
local $imgdir = "$gconfig{'webprefix'}/images";
local ($jscb, $jstb) = ($cb, $tb);
$jscb =~ s/'/\\'/g;
$jstb =~ s/'/\\'/g;

return <<EOF;
<style>
.opener_shown {display:inline}
.opener_hidden {display:none}
</style>
<script>
// Open or close a hidden section
function hidden_opener(divid, openerid)
{
var divobj = document.getElementById(divid);
var openerobj = document.getElementById(openerid);
if (divobj.className == 'opener_shown') {
  divobj.className = 'opener_hidden';
  openerobj.innerHTML = '<img border=0 src=$imgdir/closed.gif>';
  }
else {
  divobj.className = 'opener_shown';
  openerobj.innerHTML = '<img border=0 src=$imgdir/open.gif>';
  }
}

// Show a tab
function select_tab(name, tabname, form)
{
var tabnames = document[name+'_tabnames'];
var tabtitles = document[name+'_tabtitles'];
for(var i=0; i<tabnames.length; i++) {
  var tabobj = document.getElementById('tab_'+tabnames[i]);
  var divobj = document.getElementById('div_'+tabnames[i]);
  var title = tabtitles[i];
  if (tabnames[i] == tabname) {
    // Selected table
    tabobj.innerHTML = '<table cellpadding=0 cellspacing=0><tr>'+
		       '<td valign=top $jscb>'+
		       '<img src=$imgdir/lc2.gif alt=""></td>'+
		       '<td $jscb nowrap>'+
		       '&nbsp;<b>'+title+'</b>&nbsp;</td>'+
	               '<td valign=top $jscb>'+
		       '<img src=$imgdir/rc2.gif alt=""></td>'+
		       '</tr></table>';
    divobj.className = 'opener_shown';
    }
  else {
    // Non-selected tab
    tabobj.innerHTML = '<table cellpadding=0 cellspacing=0><tr>'+
		       '<td valign=top $jstb>'+
		       '<img src=$imgdir/lc1.gif alt=""></td>'+
		       '<td $jstb nowrap>'+
                       '&nbsp;<a href=\\'\\' onClick=\\'return select_tab("'+
		       name+'", "'+tabnames[i]+'")\\'>'+title+'</a>&nbsp;</td>'+
		       '<td valign=top $jstb>'+
    		       '<img src=$imgdir/rc1.gif alt=""></td>'+
		       '</tr></table>';
    divobj.className = 'opener_hidden';
    }
  }
if (document.forms[0] && document.forms[0][name]) {
  document.forms[0][name].value = tabname;
  }
return false;
}
</script>
EOF
}

# ui_hidden_start(title, name, status, thisurl)
# Returns HTML for the start of a collapsible hidden section, such as for
# advanced options.
sub ui_hidden_start
{
return &theme_ui_hidden_start(@_) if (defined(&theme_ui_hidden_start));
local ($title, $name, $status, $url) = @_;
local $rv;
if (!$main::ui_hidden_start_donejs++) {
	$rv .= &ui_hidden_javascript();
	}
local $divid = "hiddendiv_$name";
local $openerid = "hiddenopener_$name";
local $defimg = $status ? "open.gif" : "closed.gif";
local $defclass = $status ? 'opener_shown' : 'opener_hidden';
$rv .= "<a href=\"javascript:hidden_opener('$divid', '$openerid')\" id='$openerid'><img border=0 src='$gconfig{'webprefix'}/images/$defimg'></a>\n";
$rv .= "<a href=\"javascript:hidden_opener('$divid', '$openerid')\">$title</a><br>\n";
$rv .= "<div class='$defclass' id='$divid'>\n";
return $rv;
}

# ui_hidden_end(name)
# Returns HTML for the end of a hidden section
sub ui_hidden_end
{
return &theme_ui_hidden_end(@_) if (defined(&theme_ui_hidden_end));
local ($name) = @_;
return "</div>\n";
}

# ui_hidden_table_start(heading, [tabletags], [cols], name, status,
#			[&default-tds])
# A table with a heading and table inside, and which is collapsible
sub ui_hidden_table_start
{
return &theme_ui_hidden_table_start(@_)
	if (defined(&theme_ui_hidden_table_start));
local ($heading, $tabletags, $cols, $name, $status, $tds) = @_;
local $rv;
if (!$main::ui_hidden_start_donejs++) {
	$rv .= &ui_hidden_javascript();
	}
local $divid = "hiddendiv_$name";
local $openerid = "hiddenopener_$name";
local $defimg = $status ? "open.gif" : "closed.gif";
local $defclass = $status ? 'opener_shown' : 'opener_hidden';
local $text = defined($tconfig{'cs_text'}) ? $tconfig{'cs_text'} : 
	      defined($gconfig{'cs_text'}) ? $gconfig{'cs_text'} : "000000";
$rv .= "<table border $tabletags>\n";
$rv .= "<tr $tb> <td><a href=\"javascript:hidden_opener('$divid', '$openerid')\" id='$openerid'><img border=0 src='$gconfig{'webprefix'}/images/$defimg'></a> <a href=\"javascript:hidden_opener('$divid', '$openerid')\"><b><font color=#$text>$heading</font></b></a></td> </tr>\n" if (defined($heading));
$rv .= "<tr $cb> <td><div class='$defclass' id='$divid'><table width=100%>\n";
$main::ui_table_cols = $cols || 4;
$main::ui_table_pos = 0;
$main::ui_table_default_tds = $tds;
return $rv;
}

# ui_hidden_table_end(name)
# Returns HTML for the end of table with hiding, as started by
# ui_hidden_table_start
sub ui_hidden_table_end
{
local ($name) = @_;
return &theme_ui_hidden_table_end(@_) if (defined(&theme_ui_hidden_table_end));
return "</table></div></td></tr></table>\n";
}

# ui_tabs_start(&tabs, name, selected, show-border)
# Render a row of tabs from which one can be selected. Each tab is an array
# ref containing a name, title and link.
sub ui_tabs_start
{
return &theme_ui_tabs_start(@_) if (defined(&theme_ui_tabs_start));
local ($tabs, $name, $sel, $border) = @_;
local $rv;
if (!$main::ui_hidden_start_donejs++) {
	$rv .= &ui_hidden_javascript();
	}

# Build list of tab titles and names
local $tabnames = "[".join(",", map { "\"".&html_escape($_->[0])."\"" } @$tabs)."]";
local $tabtitles = "[".join(",", map { "\"".&html_escape($_->[1])."\"" } @$tabs)."]";
$rv .= "<script>\n";
$rv .= "document.${name}_tabnames = $tabnames;\n";
$rv .= "document.${name}_tabtitles = $tabtitles;\n";
$rv .= "</script>\n";

# Output the tabs
local $imgdir = "$gconfig{'webprefix'}/images";
$rv .= &ui_hidden($name, $sel)."\n";
$rv .= "<table border=0 cellpadding=0 cellspacing=0>\n";
$rv .= "<tr><td bgcolor=#ffffff colspan=".(scalar(@$tabs)*2+1).">";
if ($ENV{'HTTP_USER_AGENT'} !~ /msie/i) {
	# For some reason, the 1-pixel space above the tabs appears huge on IE!
	$rv .= "<img src=$imgdir/1x1.gif>";
	}
$rv .= "</td></tr>\n";
$rv .= "<tr>\n";
$rv .= "<td bgcolor=#ffffff width=1><img src=$imgdir/1x1.gif></td>\n";
foreach my $t (@$tabs) {
	if ($t ne $tabs[0]) {
		# Spacer
		$rv .= "<td width=2 bgcolor=#ffffff>".
		       "<img src=$imgdir/1x1.gif></td>\n";
		}
	local $tabid = "tab_".$t->[0];
	$rv .= "<td id=${tabid}>";
	$rv .= "<table cellpadding=0 cellspacing=0 border=0><tr>";
	if ($t->[0] eq $sel) {
		# Selected tab
		$rv .= "<td valign=top $cb>".
		       "<img src=$imgdir/lc2.gif alt=\"\"></td>";
		$rv .= "<td $cb nowrap>".
		       "&nbsp;<b>$t->[1]</b>&nbsp;</td>";
		$rv .= "<td valign=top $cb>".
		       "<img src=$imgdir/rc2.gif alt=\"\"></td>";
		}
	else {
		# Other tab (which has a link)
		$rv .= "<td valign=top $tb>".
		       "<img src=$imgdir/lc1.gif alt=\"\"></td>";
		$rv .= "<td $tb nowrap>".
		       "&nbsp;<a href='$t->[2]' ".
		       "onClick='return select_tab(\"$name\", \"$t->[0]\")'>".
		       "$t->[1]</a>&nbsp;</td>";
		$rv .= "<td valign=top $tb>".
		       "<img src=$imgdir/rc1.gif ".
		       "alt=\"\"></td>";
		$rv .= "</td>\n";
		}
	$rv .= "</tr></table>";
	$rv .= "</td>\n";
	}
$rv .= "<td bgcolor=#ffffff width=1><img src=$imgdir/1x1.gif></td>\n";
$rv .= "</table>\n";

if ($border) {
	# All tabs are within a grey box
	$rv .= "<table width=100% cellpadding=0 cellspacing=0 border=0>\n";
	$rv .= "<tr> <td bgcolor=#ffffff rowspan=3 width=1><img src=$imgdir/1x1.gif></td>\n";
	$rv .= "<td $cb colspan=3 height=2><img src=$imgdir/1x1.gif></td> </tr>\n";
	$rv .= "<tr> <td $cb width=2><img src=$imgdir/1x1.gif></td>\n";
	$rv .= "<td valign=top>";
	}
$main::ui_tabs_selected = $sel;
return $rv;
}

# ui_tabs_end(border)
sub ui_tabs_end
{
return &theme_ui_tabs_end(@_) if (defined(&theme_ui_tabs_end));
local ($border) = @_;
local $rv;
local $imgdir = "$gconfig{'webprefix'}/images";
if ($border) {
	$rv .= "</td>\n";
	$rv .= "<td $cb width=2><img src=$imgdir/1x1.gif></td>\n";
	$rv .= "</tr>\n";
	$rv .= "<tr> <td $cb colspan=3 height=2><img src=$imgdir/1x1.gif></td> </tr>\n";
	$rv .= "</table>\n";
	}
return $rv;
}

# ui_tabs_start_tab(name, tab)
# Must be called before outputting the HTML for the named tab
sub ui_tabs_start_tab
{
return &theme_ui_tabs_start_tab(@_) if (defined(&theme_ui_tabs_start_tab));
local ($name, $tab) = @_;
local $defclass = $tab eq $main::ui_tabs_selected ?
			'opener_shown' : 'opener_hidden';
local $rv = "<div id='div_$tab' class='$defclass'>\n";
return $rv;
}

# ui_tabs_start_tabletab(name, tab)
# Behaves like ui_tabs_start_tab, but for use within a ui_table_start block
sub ui_tabs_start_tabletab
{
return &theme_ui_tabs_start_tabletab(@_)
	if (defined(&theme_ui_tabs_start_tabletab));
local $div = &ui_tabs_start_tab(@_);
return "</table>\n".$div."<table width=100%>\n";
}

sub ui_tabs_end_tab
{
return &theme_ui_tabs_end_tab(@_) if (defined(&theme_ui_tabs_end_tab));
return "</div>\n";
}

sub ui_tabs_end_tabletab
{
return &theme_ui_tabs_end_tabletab(@_)
	if (defined(&theme_ui_tabs_end_tabletab));
return "</table></div><table width=100%>\n";
}

# ui_max_text_width(width, [text-area?])
# Returns a new width for a text field, based on theme settings
sub ui_max_text_width
{
local ($w, $ta) = @_;
local $max = $ta ? $tconfig{'maxareawidth'} : $tconfig{'maxboxwidth'};
return $max && $w > $max ? $max : $w;
}

####################### radio hidden functions

# ui_radio_selector(&opts, name, selected)
# Returns HTML for a set of radio buttons, each of which shows a different
# block of HTML when selected. &opts is an array ref to arrays containing
# [ value, label, html ]
sub ui_radio_selector
{
return &theme_ui_radio_selector(@_) if (defined(&theme_ui_radio_selector));
local ($opts, $name, $sel) = @_;
local $rv;
if (!$main::ui_radio_selector_donejs++) {
	$rv .= &ui_radio_selector_javascript();
	}
local $optnames =
	"[".join(",", map { "\"".&html_escape($_->[0])."\"" } @$opts)."]";
foreach my $o (@opts) {
	$rv .= &ui_oneradio($name, $o->[0], $o->[1], $sel eq $o->[0],
	    "onClick='selector_show(\"$name\", \"$o->[0]\", $optnames)'");
	}
$rv .= "<br>\n";
foreach my $o (@opts) {
	local $cls = $o->[0] eq $sel ? "selector_shown" : "selector_hidden";
	$rv .= "<div id=sel_${name}_$o->[0] class=$cls>".$o->[2]."</div>\n";
	}
return $rv;
}

sub ui_radio_selector_javascript
{
return <<EOF;
<style>
.selector_shown {display:inline}
.selector_hidden {display:none}
</style>
<script>
function selector_show(name, value, values)
{
for(var i=0; i<values.length; i++) {
	var divobj = document.getElementById('sel_'+name+'_'+values[i]);
	divobj.className = value == values[i] ? 'selector_shown'
					      : 'selector_hidden';
	}
}
</script>
EOF
}

####################### grid layout functions

# ui_grid_table(&elements, columns, [width-percent], [tds])
# Given a list of HTML elements, formats them into a table with the given
# number of columns. However, themes are free to override this to use fewer
# columns where space is limited.
sub ui_grid_table
{
return &theme_ui_grid_table(@_) if (defined(&theme_ui_grid_table));
local ($elements, $cols, $width, $tds) = @_;
return "" if (!@$elements);
local $rv = "<table ".($width ? "width=$width%" : "").">\n";
for(my $i=0; $i<@$elements; $i++) {
	$rv .= "<tr>" if ($i%$cols == 0);
	$rv .= "<td ".$tds->[$i%$cols].">".$elements->[$i]."</td>\n";
	$rv .= "</tr>" if ($i%$cols == $cols-1);
	}
if ($i%$cols) {
	while($i%$cols) {
		$rv .= "<td ".$tds->[$i%$cols]."><br></td>\n";
		$i++;
		}
	$rv .= "</tr>\n";
	}
$rv .= "</table>\n";
return $rv;
}

# ui_radio_table(name, selected, &rows)
# Returns HTML for a table of radio buttons, each of which has a label and
# some associated inputs to the right.
sub ui_radio_table
{
return &theme_ui_radio_table(@_) if (defined(&theme_ui_radio_table));
local ($name, $sel, $rows) = @_;
return "" if (!@$rows);
local $rv = "<table>\n";
foreach my $r (@$rows) {
	$rv .= "<tr>\n";
	$rv .= "<td>".&ui_oneradio($name, $r->[0], "<b>$r->[1]</b>",
				   $r->[0] eq $sel)."</td>\n";
	$rv .= "<td>".$r->[2]."</td>\n";
	$rv .= "</tr>\n";
	}
$rv .= "</table>\n";
return $rv;
}

####################### javascript functions

# js_disable_input(&disable-inputs, &enable-inputs, [tag])
# Returns Javascript to disable some form elements and enable others
sub js_disable_inputs
{
local $rv;
local $f;
foreach $f (@{$_[0]}) {
	$rv .= "e = form.elements[\"$f\"]; e.disabled = true; ";
	$rv .= "for(i=0; i<e.length; i++) { e[i].disabled = true; } ";
	}
foreach $f (@{$_[1]}) {
	$rv .= "e = form.elements[\"$f\"]; e.disabled = false; ";
	$rv .= "for(i=0; i<e.length; i++) { e[i].disabled = false; } ";
	}
foreach $f (@{$_[1]}) {
	if ($f =~ /^(.*)_def$/ && &indexof($1, @{$_[1]}) >= 0) {
		# When enabling both a _def field and its associated text field,
		# disable the text if the _def is set to 1
		local $tf = $1;
		$rv .= "e = form.elements[\"$f\"]; for(i=0; i<e.length; i++) { if (e[i].checked && e[i].value == \"1\") { form.elements[\"$tf\"].disabled = true } } ";
		}
	}
return $_[2] ? "$_[2]='$rv'" : $rv;
}

# js_checkbox_disable(name, &checked-disable, &checked-enable, [tag])
sub js_checkbox_disable
{
local $rv;
local $f;
foreach $f (@{$_[1]}) {
	$rv .= "form.elements[\"$f\"].disabled = $_[0].checked; ";
	}
foreach $f (@{$_[2]}) {
	$rv .= "form.elements[\"$f\"].disabled = !$_[0].checked; ";
	}
return $_[3] ? "$_[3]='$rv'" : $rv;
}

1;

