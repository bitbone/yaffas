#!/usr/bin/perl
package Yaffas::UI::TablePaging;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(show_page match fetch store);
}

use Yaffas::UI qw($Cgi start_table end_table section_button);
use Data::Dumper;
use Yaffas::Constant;
use POSIX;
use URI::Escape;
use File::Path;
use URI::Escape;

sub _apply_filter(\@$);
sub _apply_sort(\@$);
sub show_page(\@\@\@$\%);

our $sort_column;

=head1 NAME

Yaffas::UI::TablePaging - Functions to provide Paging Management

=head1 SYNOPSIS

 use Yaffas::UI::TablePaging;

=head1 DESCRIPTION

Yaffas::UI::TablePaging is a Framework to generate Pages.

=head1 HINTS

Since You probably use index.cgi quite often, You cant use the footer with its default behavour. ( footer() )
See the developer guide for futher information on the footer.

If you want to make your footer easier use:

 category name: $main::text{BBCATEGORY};
 modul name: $main::text{BBMODULEDESC};

=head1 FUNCTIONS

=over

=item show_page (HEADER, FOOTER, CONTENT, PAGENR, PARAMTER )

If PAGENR == 0 it will display the whole CONTENT, not only some lines. (Note: filter and sort will work.)
PAGENR musst be a integer number.

If PAGENR == -1 than the whole CONTENT will be displayed, but footer will not be displayed. This is only usefull
if you need to build a table out of array refs.

The HEADER will be displayed on the top of every Page.
HEADER can be a Array in with the first element is the first Cell of the Table.
Or HEADER can be a two-dimensional Array. Something like a multi-line-header, with HEADER[0] is the first line
HEADER[1] the second. The first element of one line is (again) the first cell of the table.

FOOTER works simmilar to HEADER. The only difference is that FOOTER will be displayed on the bottom of a page.

CONTENT is a two-dimentional Array. One line in the array is one line in the page. First line

PARAMETERS is a hash with following keys:

B<VERY IMPORTANT!> take care that your "user data" wont clash with the "control date" of the TablePaging Module.
This could be nice to test in whiteboxtests.

=over

=item -refresh_button

if -refresh_button is set, then there is a "refresh" link to load the table without its cache.

=item -filter

-filter has to be a reference to a subroutine. the sub gets a single parameter.
the Parameter is a refrence to a line of Content.

=item -sort

-sort has to be a reference to a subroutine. the sub gets 2 parmaters. Think of $a, $b in sort.
Each Parameter contains a refrerence to a line of Content.

=item -script

-script containts the name of the script. It is used for the links.
B<This is mandatory>.

=item -linkattrib

-linkattrib is a hashref. The Key and Value pais will be appended to the links for paging through the pages.

=item -hiddenattrib

-hiddenattrib is a hashref. The Key and Value pais will be hidden fields.

=item -linkheader

It Containts the columnt numbers, which will be transformed to a link. If this is undef, the HEADER
will be text only. For Excample:

	-linkheader => [ 1, 2, 3 ]

=item -headerlinkattrib

This works like -linkeattrib, but this is importent for the links for the header.
usually you do sorting with that links, so you need to have different Parameters for the links.

B<ACHTUNG>

	$param{-headerlinkattrib}->{sort_column};

sort_column has a special meaning. for each column it will be increased by 1

=item -column_width

This can be used for formating the Width of each column. They are inserted in a sytle xhtml attribute.
For Example:

	-column_width => [ ("20%", "30%", "30%", "20%") ]

=item -toggle_selection_link

If you set this to 1 you will get a a link in your header to invert selection of your checkboxes.

=back

=cut

sub show_page(\@\@\@$\%) {
	my $header = shift;
	my $footer = shift;
	my $content = shift;
	my $page_nr = shift;
	my $param = shift;

	$sort_column = 	$param->{-headerlinkattrib}->{sort_column};

	my @content = _apply_filter(@$content, $param->{-filter});
	@content = _apply_sort(@content, $param->{-sort});

	# contain me from Bitkti::Const.
	my $lines_per_page = 10;
	my $content_length = scalar @content;

	# error cased
	return unless defined $page_nr;
	return unless $page_nr =~ /^-?\d+$/;
	return unless defined $param->{-script};

	if ($page_nr <= 0) { ## display the whole thing.
		$lines_per_page = $content_length;
	}

	my $max_pages;
	eval {
		$max_pages = ceil ($content_length / $lines_per_page);
	};
	if ($@ || !$max_pages) {
		$max_pages = 1;
	}

	$page_nr = $max_pages if ($page_nr > $max_pages);
	my $offset = ($page_nr - 1 ) * $lines_per_page;
	if ($page_nr <= 0) { # display the whole thing.
		$offset = 0;
	}

	if (defined $param->{-linkheader}) {
		_header_as_links($header, $param, $page_nr);
	}

	my @display = splice(@content, $offset, $lines_per_page);

	my $hidden_information = "";
	foreach (keys %{$param->{-hiddenattrib}}) {
		$hidden_information .= $Cgi->hidden($_, $param->{-hiddenattrib}->{$_});
	}

	my $size = $param->{-column_width};
	my $toggle_selection = $param->{-toggle_selection_link};

	my $content_out = start_table();
	if (ref $header->[0]) {
		for my $line (@$header) {
			$content_out .= $Cgi->start_Tr();
			my $i = 0;
			foreach (@$line) {
				my %style = ($size->[$i]) ? ( -style => "width: " . $size->[$i] ) : ();
				if ($i == 0 && $toggle_selection) {
					$content_out .= $Cgi->th(\%style,
											 $Cgi->label({-title => $main::text{lbl_toggleselect}},
														 $Cgi->a({-style=>"margin-left:5px;",
																  -href=>"javascript:toggle_selection()"},
																 $Cgi->img({-alt=> $main::text{lbl_toggleselect},
																			-src=>"/images/cross.gif"})
																)
														)
											);
				} else {
					$content_out .= $Cgi->th(\%style, $_);
				}
				$i++;
			}
			$content_out .= $Cgi->end_Tr();
		}
	} else {
		$content_out .= $Cgi->start_Tr();
		my $i = 0;
		foreach (@$header) {
			my %style = ($size->[$i]) ? ( -style => "width: " . $size->[$i] ) : ();
			if ($i == 0 && $toggle_selection) {
				$content_out .= $Cgi->th(\%style,
										 $Cgi->label({-title => $main::text{lbl_toggleselect}},
													 $Cgi->a({-style=>"margin-left:5px;",
															  -href=>"javascript:toggle_selection()"},
															 $Cgi->img({-alt=> $main::text{lbl_toggleselect},
																		-src=>"/images/cross.gif"})
															)
													)
										);
			} else {
				$content_out .= $Cgi->th(\%style, $_);
			}
			$i++;
		}
		$content_out .= $Cgi->end_Tr();
	}
	## neues element
	foreach (@display) {
		$content_out .= $Cgi->Tr(
								 $Cgi->td(
										  $_
										 )
								)
	}
	## neues element
	## footer gleiche logik wie be header
	if ($page_nr >= 0) {
		if (ref $footer->[0]) {
			$content_out .= map {
				$Cgi->Tr({class => 'footer'},
						 $Cgi->td(
								  $_
								 )
						)
			} @$footer;
		}else {
			$content_out .= $Cgi->Tr({class => 'footer'},
									 $Cgi->td($footer)
									);
		}
	}
	$content_out .= end_table();
	my $page_switcher = _page_switcher($param, $page_nr, $max_pages);
	my $refresh_without_cache = "";
	if ($param->{-refresh_button}) {
		$refresh_without_cache = _refresh_without_cache();
	}

	return $content_out . $page_switcher . $refresh_without_cache . $hidden_information;
}

sub _refresh_without_cache {
	my $parameters = "?";
	my $scriptname = $ENV{SCRIPT_NAME};

	if ($scriptname =~ m/\/$/) {
		$scriptname .= "index.cgi";
	}

	## hoffentlich wurde %main::in nicht verändert.
	if (%main::in) {
		foreach (keys %main::in) {
			## zu löschende parameter:
			# cat
			# cacheid

			next if $_ eq "cat";
			next if $_ eq "cacheid";

			$parameters .= uri_escape($_) . "=" . uri_escape($main::in{$_}) . "&";
		}
	}

	$parameters =~ s/.$//; # das letzte zeichen entfernen. entweder & oder ?

	return $Cgi->a(
				   {href => $scriptname . $parameters},
				   $main::text{lbl_refresh}
				  );
}

# generates links. interal use only.
sub _link($$;$) {
	my $param = shift;
	my $page = shift;
	my $header = shift; # optionaler parameter, errrzeugt links für den header, wenn gesetzt.
	my $link_base = $param->{-script} . q(?page=);
	my $link = $param->{-linkattrib};

	if ($header) {
		$link = $param->{-headerlinkattrib}; # überschreiben. wenn wir für dne header links erzeugen.
		$link->{sort_column} = $sort_column;
	}

	my $r = $link_base . $page;
	if (keys %$link) {
		my $tmp = join "&",map {$_ . "=" . (defined($link->{$_})?($link->{$_}):("")) } (keys %$link);;
		$r .= "&" . $tmp;
	}
	return $r;
}

# wandelt den header zu links mit sortierung um
sub _header_as_links($$$){
	my $header = shift;
	my $param = shift;
	my $page_nr = shift;

#	my $sub = $param->{-headerlinksub}; # some idea, maybe
	my @link_me = @{ $param->{-linkheader} };

	if (ref $header->[0] ) {
		# multi line
		for my $line(@$header) {
			local $sort_column = $sort_column;
			for (@$line) {
				if (grep {$_ == $sort_column}@link_me) {
					$_ = $Cgi->label({
									  title => $main::text{lbl_togglesort},
									 },
									 $Cgi->a(
											 {href => _link($param, $page_nr, 1)},
											 $Cgi->img({src => "/images/arrow.gif"}) . $_
											)
									);

				}
				$sort_column++;
			}
		}
	}else {
		local $sort_column = $sort_column;
		for (@$header) {
			if (grep {$_ == $sort_column}@link_me) {
					$_ = $Cgi->label({
									  title => $main::text{lbl_togglesort},
									 },
									 $Cgi->a(
											 {href => _link($param, $page_nr, 1)},
											 $Cgi->img({src => "/images/arrow.gif"}) . $_
											)
									);
			}
			$sort_column++;

		}
	}
}

=item match (VALUE, SEARCHTERM, [ CASE SENSE ])

_match can be usefull for your filter subroutins. it converts a "windows style regex" to a perlish one. and tests if
the regex would match the VALUE or not.

=cut

sub match {
	my $value = shift;
	my $term = shift; #searchterm
	my $casesense = shift;

	my $regex;
	return 1 unless $term;
	return 1 unless $value;
	$term =~ s/[^\w*?\._-]//g;
	$regex = $term;
	$regex = "*" if $term eq "";
	$regex =~ s/\*/\.\*/g;
	$regex =~ s/\?/\./g;

	if (defined $casesense and $casesense == 1) {
		return $value =~ m/$regex/i;
	}
	else {
		return $value =~ m/$regex/;
	}
}


sub _apply_filter(\@$){
	my $content = shift;
	my $sub = shift;

	return @$content unless $sub;
	return grep { &{$sub}($_) }@$content;
}

sub _apply_sort(\@$){
	my $content = shift;
	my $sub = shift;

	return @$content unless $sub;
	return sort { &{$sub}($a, $b) } @$content;
 }

sub _page_switcher() {
	my $param = shift;
	my $page_nr = shift;
	my $max_pages = shift;
	my $page_switcher;

	if ($page_nr < 0) {
		return "";
	} elsif ($page_nr == 0) {
		$page_switcher .= $Cgi->div({class=>'pager'},
									$Cgi->a({href => _link($param, 1)}, $main::text{'lbl_per_page'}),
									## dirty hack.. in the single page mode you need to have the page as hidden field.
									$Cgi->hidden("page", 0),
								   );

	} else {
		if ($max_pages <= 1 ) {
			return "";
		}
		$page_switcher .= $Cgi->div({class=>'pager'},
									$Cgi->scrolling_list(
														 -name => "page",
														 -values => [1..$max_pages],
														 -size => 1,
														 -multiple => 0,
														 -default => $page_nr,
														 -onChange => "this.form.submit",
														),
									$Cgi->submit("goto", $main::text{lbl_paging_goto}),

									(
									 $page_nr > 1 ?
									 (
									  $Cgi->a({href => _link($param, $page_nr - 1)}, $main::text{lbl_paging_previous}),
									 ) : (
										  $main::text{lbl_paging_previous},
										 )
									),

									" | ", # seperator

									$page_nr < $max_pages ?
									(
									 $Cgi->a({href => _link($param, $page_nr + 1)}, $main::text{lbl_paging_next})
									) : (
										 $main::text{lbl_paging_next}
										),

									" | ", # seperator

									$Cgi->a({href => _link($param, 0) }, $main::text{lbl_paging_all}),

								   );

	}


}

=item store ( ARRAY )

Stores the given array and returns true on success.

=cut

sub store(\@) {
	my $array = shift;
	my $spool = _get_spool_dir();

	mkpath($spool);

	my $name = $ENV{REMOTE_USER};

	my $file = $spool . "/". $name;
	open FH, ">", $file or return undef;
	print FH Dumper $array;
	close FH;
	return $name;
}

=item fetch ( )

Fetch an array based on your REMOTE_USER.

=back

=cut

sub fetch($) {
	my $array;
	my $spool = _get_spool_dir();

	my $file = $spool . "/". $ENV{REMOTE_USER};
	local $/ = undef; # slurp
	open FH, "<", $file or return;
	$array = <FH>;
	close FH;
	$array = "my " . $array;
	$array = eval $array;

	return @$array;
}

sub _get_spool_dir() {
	return Yaffas::Constant::DIR->{paging_framework};
}

sub _clear_spool_dir($$) {
	my $spool = shift;
	my $id = shift;

	opendir DIR, $spool;
	my @dirs = readdir DIR;
	closedir DIR;

	foreach (@dirs) {
		if (-f $spool."/".$_ && $_ ne $id) {
			unlink $spool."/".$_;
		}
	}
}

1;

=head1 EXAMPLE ( SIMPLE )

	my @header = ("", "username", "Gecos" );
	my @footer = ();
	my @users = get_all_users();
	my @content = (
		map {[
			$Cgi->checkbox(),
			$_,
			get_gecos($_),
		]} @users
	);
	my %param = (
				 -script => "index.cgi",
				 -column_width => [ ("20%", "40%", "40%") ],
				);
	my $page_nr = $main::in{page};
	show_page(@header, @footer, @content, $page_nr, %param);

This will display a simple pager without sorting or filter abilitys. For a more
complex example you can have a look at the yaffas webmin usermanagment, groupmanagment or
mailalias modules.

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
