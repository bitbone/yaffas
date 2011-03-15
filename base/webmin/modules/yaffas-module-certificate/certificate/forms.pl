#!/usr/bin/perl -w
use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

use Yaffas::UI qw($Cgi section error_box section_button start_table end_table table);
use Yaffas::Module::Certificate qw(list_certs import_cert validate_gencert create_certificate);

use Error qw(:try);
use Yaffas::Exception;
use Sort::Naturally;

my @services = Yaffas::Module::Certificate::get_services();

sub show_generate_cert(){
    ## this is a rewrite of print_cert_forms with CGI.pm
    ## default werte aus dem inhash nehmen! wenn der leer is dann auch leer reinschreiben :)
    ## das is echt cool so, so bekommt man nach n fehler seine alten eingeaben angezeigt!

    print $Cgi->start_form(-action => "gencert.cgi",
			   -method => 'POST');

	print section(
				  $main::text{'gencert_header'},
				  $Cgi->start_table(),
				  $Cgi->Tr([
							$Cgi->td([ $main::text{'gencert_service'}.":",
									   $Cgi->scrolling_list(-name => 'service',
															-values => \@services,
															-default => $main::in{'service'},
															-size => 1)]),
							$Cgi->td([ $main::text{'keysize'}.":",
									   $Cgi->table({-width=>"100%"}, [
																	  $Cgi->Tr(
																			   $Cgi->td([
																						 $Cgi->radio_group(
																										   "keysize",
																										   [1024, 2048],
																										   $main::in{'keysize'} || 1024
																										  ),
																						])
																			  )
																	 ]
												  )
									 ]),
							$Cgi->td([ $main::text{'gencert_days'}.":",	## main::in is entweder "" oder im fehler fall wird der wert wieder übernommen.
									   $Cgi->textfield("days", $main::in{'days'}, 40) ]),
							$Cgi->td([ $main::text{'cn'}.":",
									   $Cgi->textfield("cn", $main::in{'cn'},  40) ]),
							$Cgi->td([ $main::text{'o'}.":",
									   $Cgi->textfield("o", $main::in{'o'}, 40) ]),
							$Cgi->td([ $main::text{'ou'}.":",
									   $Cgi->textfield("ou", $main::in{'ou'}, 40) ]),
							$Cgi->td([ $main::text{'l'}.":",
									   $Cgi->textfield("l", $main::in{'l'}, 40) ]),
							$Cgi->td([ $main::text{'st'}.":",
									   $Cgi->textfield('st', $main::in{'st'}, 40) ]),,
							$Cgi->td([ $main::text{'c'}.":",
									   $Cgi->textfield('c', $main::in{'c'}, 2, 2) ]),,
							$Cgi->td([ $main::text{'emailAddress'}.":",
									   $Cgi->textfield('emailAddress', $main::in{'emailAddress'}, 40) ]),
						   ]),
				  $Cgi->end_table(),
				 );


	print section_button(
						 $Cgi->submit('submit', $main::text{'gencert_generate'}),
						);

    print $Cgi->end_form();
}

sub show_errors_or_okee_gen_cert() {
	try {
		validate_gencert(\%main::in);
		create_certificate(\%main::in);
		print Yaffas::UI::ok_box();
	} catch Yaffas::Exception with {
		print Yaffas::UI::all_error_box(shift);
		show_generate_cert();
	};
}


sub _del_checkbox($){
	# show it only if $_ ne default.
	my $v = shift;
	if ($v eq "default.crt") {
		return $Cgi->td($Cgi->checkbox(-name => "del",
									   -value => $_,
									   -label => "",
									   -disabled => "disabled"
									  )
					   );
	}else {
		return $Cgi->td($Cgi->checkbox(-name => "del",
									   -value => $_,
									   -label => ""
									  )
					   );
	}
}

# Druckt eine Tabelle mit allen vorhandenen Zertifikaten.
sub show_cert(){

	my %certs = list_certs();
	print $Cgi->start_form(-action => "view.cgi",
						   -method => 'post');
	$Yaffas::UI::Print_inner_div = 0;
	print section(
				  $main::text{view_header},
				  start_table(),
				  $Cgi->Tr(
						   $Cgi->th({style => "width: 20px"}),
						   $Cgi->th({style => "width: 120px"}, $main::text{'view_name'}),
						   $Cgi->th([
									 $main::text{'view_begin'},
									 $main::text{'view_end'},
									])
						  ),
				  (
				   map{
					   if ($certs{$_}) {
						   $Cgi->Tr(
									_del_checkbox($_),
									$Cgi->td($_),
									$Cgi->td($certs{$_}->[0]),
									$Cgi->td($certs{$_}->[1]),
								   )
					   }else {
						   $Cgi->Tr(
									_del_checkbox($_),
									$Cgi->td($_),
									$Cgi->td({colspan=> 2},  $main::text{'view_cert_not_valid'})
								   )
					   }
				   } nsort keys %certs,
				   ## end map
				  ),
				  end_table(),

				 );
	print section_button(
						 $Cgi->submit('submit', $main::text{'view_delete'})
						);
	print $Cgi->end_form();
}

sub show_import(){
	print $Cgi->start_multipart_form(-action => "import.cgi?dest=1",
									 -method => 'post');

	print section($main::text{'import_upload_cert'},
				  $Cgi->table(
							  $Cgi->Tr(
									   [
										$Cgi->td([
												  $main::text{'import_cert_file'},
												  $Cgi->filefield('cert_file_upload', "", 48),
												 ]),
										$Cgi->td([
												  $main::text{'import_cert_service'},
												  $Cgi->scrolling_list(-name =>"service",
																	   -values => \@services,
																	   -multiple=>0,
																	   -size=>1,
																	  )
												 ]),
									   ]
									  )
							 ),
				 );
	print section_button(
						 $Cgi->submit('btnsubmit', $main::text{'import_upload_cert_s'})
						);
	print $Cgi->end_form();
}

sub show_import_ok_err(){
  my $service = $main::in{'service'};
  my $upload = $main::in{'cert_file_upload'};

  import_cert($upload, $service);
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
