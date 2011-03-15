use warnings;
use strict;
package Yaffas::UI;

use CGI '-nosticky';

our $Cgi;
sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw($Cgi);
	our @EXPORT_OK = qw(error_box ok_box all_error_box message_box yn_confirm
						section_button section start_section end_section
						table start_table end_table small_form
						value_add_del_form creating_cache_finish creating_cache_start
					   );
	*CGI::start_form = \&CGI::startform;
	$Cgi = CGI->new("");
}

our $Print_inner_div;
our $Convert_nl;
$Print_inner_div = 1;
$Convert_nl = 1;

=head1 NAME

Yaffas::UI - Functions for the UI

=head1 SYNOPSIS

 use Yaffas::UI;

=head1 DESCRIPTION

Yaffas::UI provides some basic functions for Webmin / Usermin User Interface.

=head1 FUNCTIONS

=over

=item yn_confirm (OPTIONS MSG)

returns a yes/no confirmation in html.
usefull for CGI scripts. the method of the form will be 'post'

=over

=item Options

=over

=item -action ( Skalar )

=item -hidden ( Arrayref )

=item -title ( Skalar )

=item -no ( Skalar )

=item -yes ( Skalar )

=item -no_target ( Skalar); Optional! Default is index.cgi

=back

=item Example

	yn_confirm({
		-action => "script.cgi",
		-hidden => [key => \@values, foo => "bar", key => $value2],
		-title => $main::text{title},
		-yes => 'ja',
		-no => 'no',
		},
		@MSG
	)

=back

=cut

sub yn_confirm ($@){
    my $options = shift;
	my @msg = @_;
	my $msg = join ( $Cgi->br(), map { if($Convert_nl){  s/\n/$Cgi->br()/eg } $_ } @msg );

	# my $options->{-hidden}   <-- array ref, mit geradem index key, und nächster ungerader value

	my @hidden;
	while (@{$options->{-hidden}}) {
		my ($k, $v) = splice @{$options->{-hidden}}, 0, 2; # shift shift ;)

		if (ref $v eq "ARRAY") {
			push @hidden, $Cgi->hidden($k, $_) foreach @{$v};
		} else {
			push @hidden, $Cgi->hidden($k, $v);
		}
	}

	my $no_target = "index.cgi";
	$no_target = $options->{-no_target} if defined($options->{-no_target});

	return join "", (
					 $Cgi->start_form({-method => 'POST',
									   -action => $options->{-action},
									  }),
					 section($options->{-title},
							 $msg,
							 @hidden,
							),
					 $Cgi->div({class => 'sbutton'},
							   $Cgi->submit($options->{-yes}),
							   $Cgi->reset(-name => "Verweis",
										   -value=>$options->{-no},
										   -onClick => "self.location.href='$no_target'",
							   ),
							  ),
					 $Cgi->end_form(),
					);


}

=item error_box ( MESSAGE )

returns an error message. Use it if you want to print a errormessage to the user.

=cut

sub error_box ($) {
	my $msg = shift;
	$msg =~ s/\n/$Cgi->br()/eg if ($Convert_nl);
	_section_error($msg);
}

=item ok_box( MESSAGE )

returns an ok message as xhtml. Use it if you want to print a Success Message to the user.

=cut

sub ok_box(;$){
	message_box(":-)", (@_ ? @_ : "OK"));
}


=item message_box ( MESSAGEHEAD, MESSAGE )

returns a message as xhtml. use it, if its neither a Error or a Success Message.

=cut

sub message_box ($$) {
	my $type = shift;
	my $msg = shift;
	$msg =~ s/\n/$Cgi->br()/eg if ($Convert_nl);
	section($type, $msg);
}

=item all_error_box ( EXCEPTION )

returns formated html with all errors. Works only in Webmin modules.
This subroutine can only be used with Error.pm and Yaffas::Exception.pm.
Just call all_error_box() with your EXCEPTION. The sub prints everything pretty.

=cut

# leben Sie, wir kümmern uns um die details ;)
sub all_error_box($) {
	my $exception = shift;
	return undef unless $exception;

	my @err;
	my %errors = %{$exception->get_errors()};
	my $r;

	$r = $Cgi->comment($exception);

	foreach my $key (keys %errors) {
		my $string = "";
		if (defined($main::text{$key})) {
			$string = "$main::text{error}: $main::text{$key}";
		} else {
			$string = "$main::text{error}: $key";
			$string .= " - ".$exception->text() if (defined($exception->text()));
		}

		my @errors = @{$errors{$key}};
		$string .= " " . $Cgi->ul(
								  $Cgi->li([
											@errors
										   ]),
								 )   if( @errors >= 1 && $errors[0] ne "");
		push @err, $string;
	}


	if (@err) {
		$r .= _section_error(
							 $Cgi->ol(
									  $Cgi->li(
											   [@err]
											  )
									 ));
	} else {
		$r .= _section_error($Cgi->p("No error specified!"));
	}
	return $r;
}

=item table ()

=item start_table ()

Think CGI. behaves exactly equal. Use it, if you have a table in a section().

=cut

sub table(@){
	$Cgi->table({class => "table_in_section"}, @_);
}

sub start_table(@){
	$Cgi->start_table({class => "table_in_section"});
}

=item end_table ()

Think CGI;

=cut

sub end_table(){
	$Cgi->end_table();
}

=item start_section ( HEADER )

=item section ( HEADER, BODY )

Creates a section. use it instead of Tables to format your content.

=cut

sub section ($@) {
	my $header = shift;

	return $Cgi->div(
					 {
					 -class=>"section"},
					 $Cgi->h1($header),
					 (@_ ? $Cgi->div(@_) : undef),
					);
}

sub start_section($) {
	my $header = shift;

	return $Cgi->start_div({-class=>"section"}) . $Cgi->h1($header) . $Cgi->start_div();
}

=item end_section ()

Ends a section.

=cut

sub end_section() {
	return $Cgi->end_div() . $Cgi->end_div();
}

sub _section_error (@) {
	my $header = ":-(";
	return $Cgi->div( {-class=>"section"}, $Cgi->h1({class => 'error'},$header), $Cgi->div(@_) );
}

=item section_button ( BODY )

Creates the <div> for correct button decoration. Example:

 $Cgi->start_form(...);
 section(.....);
 section_button( $Cgi->submit(...)):
 $Cgi->end_form();


=cut

sub section_button (@){
	$Cgi->div(
			  {class => 'sbutton'},
			  @_,
			 );
}

=item download_to_client ( FILE DISPLAYNAME )

Sends html stuff for a filedownload from server to client.

 FILE: File to send (complete path)
 DISPLAYNAME: Filename to show in users browser 'save as' dialog

=cut

sub download_to_client ($$)
{
	my $file = shift;
	my $displayname = shift;
	
	if (open(DLFILE, "$file"))
	{
		my @info = stat(DLFILE);
		my $length = $info[7];
		my $blksize = $info[11] || 16384;
		print "Content-type: application/bitkit-filedownload\n";
		print "Content-length: $length\n";
		print "Content-Disposition: filename=$displayname\n\n";

		my $buffer;
		while (!eof(DLFILE))
		{
			read(DLFILE, $buffer, $blksize);
			print $buffer;
		}
		close (DLFILE);
	}
	else
	{
		return undef;
	}
}

=item value_add_del_form (HASHREF)

returns the html code of the multi value delete add form with the aplly button ;)

example:

 value_add_del_form(
  {
   -input_name => 'domain',
   -del_name => 'del',
   -input_label => $main::text{lbl_append},
   -del_label => $main::text{lbl_delete},
   -content => \@tmp;
  }
 ),

=cut

sub value_add_del_form($) {
	my $h = shift;
	my @content;
	if ($h->{-content}) {
		@content = @{ $h->{-content} };
	}else {
		@content = @{ $h->{content} };
	}

	my $header = $h->{-header_name} || $h->{header_name} || ':-|';


	return (
			section(
					$header,
					$Cgi->table({-class=>"value_add_del_form"},
								small_form($h),
							   ),
				   )
		   );
}

=item small_form ( HASHREF )

Returns the html code of the above, but without
tables/sections/... and with less options.

  Usage:
    small_form ({
        input_label => $main::text{lbl_append},
        del_label => $main::text{lbl_delete},
        input_name	=> 'dns',
        input_value	=> '127.0.0.1',
        del_name	=> 'del_dns',
        content		=> \@servers,
	});

=cut

sub small_form($) {
    my $h = shift;

    # defaults
    my $input_name  = $h->{-input_name}  || $h->{input_name}   || 'add';
    my $del_name    = $h->{-del_name}    || $h->{del_name}     || 'del';
    my $header      = $h->{-header_name} || $h->{header_name}  || ':-|';
    my $del_label   = $h->{-del_label}   || $h->{del_label}    || "";
    my $input_label = $h->{-input_label} || $h->{input_label}  || "";
    my $input_value = $h->{-input_value} || $h->{input_value}  || "";
    my $hide_add = $h->{-hide_add} || $h->{hide_add} || 0;

    my @content;
    if ($h->{-content}) {
	@content = @{ $h->{-content} };
    } else {
	@content = @{ $h->{content} };
    }

    # 	$opt->{'input_name'} = 'add' unless $opt->{'input_name'};
    # 	$opt->{'input_value'} = '' unless $opt->{'input_value'};
    # 	$opt->{'del_name'} = 'del' unless $opt->{'del_name'};
    # 	$opt->{'content'} = [] unless $opt->{'content'};

    return (
	    $Cgi->Tr([
		      $Cgi->td([
				$input_label,
				$Cgi->textfield($input_name, $input_value),
				$hide_add ? undef : $Cgi->submit('submit', $main::text{lbl_add})
			       ]),
		     ]),
	   		 $Cgi->Tr(
		      $Cgi->td({-style => "vertical-align:top;", -colspan=>3},
			       [
				# if scalar @content
				#$del_label,
				$Cgi->table({-class=>"small_form"},
						scalar @content ?
					    map {
						$Cgi->Tr(
							 $Cgi->td([
							 	   $_,
								   $Cgi->div({-name=>$del_name, -value=>$_}, '')
								  ])
							),
						    } @content
						    : ""
					   )
			       ]
			     )
		       )
	   );
}

=item creating_cache_start ()

Printing "Creating cache ...". Usefull in TablePaging.

=cut

sub creating_cache_start() {
	return $Cgi->start_p({-id=>"cache"}).$main::text{lbl_create_cache}." ... ";
}

=item creating_cache_finish ()

Prints only "done", but if javascript is on than the creating_cache_start output will disappear.

=cut

sub creating_cache_finish() {
	my @ret;
	push @ret, $main::text{lbl_done};
	push @ret, $Cgi->end_p();
	push @ret, "<script type='text/javascript'>document.getElementById('cache').style.display='none';</script>";
	return @ret;
}

1;


=back

=head1 VARIABLES

=over

=item DEPRECATED: Print_inner_div

If Print_inner_div is set to 0, it removes inner DIV tags in section.

=item Convert_nl

If Convert_nl is set to 0, \\n won't be converted to $Cgi->br()

=back

=head2 NOTE

Don't forget to reset this if you don't need it anymore.

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
