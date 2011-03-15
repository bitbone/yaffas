#!/usr/bin/perl
package Yaffas::Printer;

use warnings;
use strict;

sub BEGIN
{
	use Exporter;
	our @ISA = qw(Exporter Yaffas::Module);
	our @EXPORT_OK = qw(get_default_printer
						set_default_printer
						enable_printer
						disable_printer
						get_printer_status);
}

use Yaffas qw(do_back_quote);
use Yaffas::Constant;
use Yaffas::Exception;


## prototypes ##Service.pm

=pod

=head1 NAME

Yaffas::Conf --todo--

=head1 SYNOPSIS

use Yaffas::Printer

=head1 DESCRIPTION

Yaffas::Printer  --todo--

=head1 FUNCTIONS

=over

=item check_new_printer_allowed ()

returns 1 if you can install one more printer else 0.

=cut

sub check_new_printer_allowed () {
	throw Yaffas::Exception('err_deprecated', "Yaffas::Printer::check_new_printer_allowed()");
	# chomp( my $max = &get_licenseinfo_pdf("printernr"));
	# my @configured_printers = get_printer_list();
	# return ($max >= scalar @configured_printers);
}

=item get_printer_list ( )

returns array of existing printers

=cut

sub get_printer_list () {
	throw Yaffas::Exception('err_deprecated', "Yaffas::Printer::get_printer_list()");
       # my $dir = "/etc/samba/smbprinters/";
       # opendir(DIR, "$dir");
       # my(@files) =  grep !/^\./,readdir(DIR);
       # closedir(DIR);
       # return @files;
}

=item check_existing_printer ( NAME )

It checks if printername already exists. returns 1 if the printer exists, else undef.

=cut

sub check_existing_printer ($) {
	throw Yaffas::Exception('err_deprecated', "Yaffas::Printer::check_existing_printer()");
      #  my $name = shift;
      #  my @printers = get_printer_list();
      #  foreach (@printers) {
      #         return 1 if ($_ eq $name);
      #  }
      #  return undef;
}

=item change_printername( OLDNAME, NEWNAME )

renames a printer from OLDNAME to NEWNAME. REturns 1 und success, else undef.

=cut

sub change_printername($$) {
	throw Yaffas::Exception('err_deprecated', "Yaffas::Printer::change_printername()");
  #  my $orgpname = shift;
  #  my $newpname = shift;
  #  return undef unless ( checkFaxPrinterName($newpname) );
  #  return undef unless ( checkFaxPrinterName($orgpname) );

  #  my $path = "/etc/samba/smbprinters/";

  #  my $orgpath = $path . $orgpname;
  #  my $newpath = $path . $newpname;

    # change name of dir
  #  if (move($orgpath, $newpath)) {
  #      # change name of include value in smb.conf
  #      my $smbconf = Yaffas::File->new("/etc/samba/smb.conf");
  #      my $smbp = "/etc/samba/smbprinters/";
  #      my $oldinc = "include=" . $smbp  . $orgpname ."/printer";
  #      my $newinc = "include=" . $smbp  . $newpname ."/printer";
   #     my $off = $smbconf->search_line(qr($oldinc));
   #     $smbconf->splice_lines( $off, 1, $newinc);

   #     if ( $smbconf->write() ) {
   #         # change real printer name in smb-printer file
   #         my $faxincprinter = Bitkti::File->new( $smbp . $newpname . "/printer" );
   #         my $off2 = $faxincprinter->serach_lines( qr(\^\.\*\\[$orgpname\\]\.\*));
    #        $faxincprinter->splice_lines($off2, 1, "\[$newpname\]");

    #        if ( $faxincprinter->write() ) {
    #            # return 1 if all was ok
    #            return 1;
    #        } else {
    #            #undo
    #            $smbconf->splice_lines( $off, 1, $oldinc);
    #        }
    #    } else {
    #        #undo
    #        move($newpath, $orgpath);
    #    }
    #}
    #return undef;
}


=item check_fax_printer_name ( PRINTERNAME )

checks if the PRINTERNAME is valid or not.

=cut

sub check_fax_printer_name($)
{
	throw Yaffas::Exception('err_deprecated', "Yaffas::Printer::change_fax_printer_name()");
      #  my $faxpname = shift;
      #  ($faxpname =~ m/^[a-zA-Z0-9_\-.]+$/) ? return 1 : return 0;
}


=cut

=item get_default_printer ()

returns the name of the default cups printer. or undef, if noone is configured

=cut

sub get_default_printer(){

    my $cmd = Yaffas::Constant::APPLICATION->{lpstat};
    my $printer = Yaffas::do_back_quote($cmd, "-d");
    chomp($printer);
    $printer =~ s/.*?(\S+)$/$1/;
    if($printer eq "Standardziel" or $printer eq "destination"){
	return undef;
    }
    return $printer;
}

=item set_default_printer (PRINTERNAME)

sets the default printer. return 1 on success, undef in errorcase.

=cut

sub set_default_printer($){
    my $printer = shift;
    my $cmd = Yaffas::Constant::APPLICATION->{lpadmin};
    my $r = Yaffas::do_back_quote($cmd, "-d", $printer);

    if($r eq "") {
        return 1;
    } else {
        return undef;
    }
}

=item enable_printer(<NAME>)

Enables printer B<NAME> via 'cupsenable'.

=cut

sub enable_printer ($) {
	my $printer = shift;
	my $cmd = Yaffas::Constant::APPLICATION->{'cupsenable'};
	my $r = Yaffas::do_back_quote($cmd, $printer);

	if($r =~ /^$/) {
		return 1;
	}
	else {
		return undef;
	}
}

=item disable_printer(<NAME>)

Disables printer B<NAME> via 'cupsdisable'.

=cut

sub disable_printer ($) {
	my $printer = shift;
	my $cmd = Yaffas::Constant::APPLICATION->{'cupsdisable'};
	my $r = Yaffas::do_back_quote($cmd, $printer);

	if($r =~ /^$/) {
		return 1;
	}
	else {
		return undef;
	}
}

=item get_printer_status(<NAME>)

Returns the state of the printer B<NAME>. 0 means disabled, 1 enabled.

=cut

sub get_printer_status($) {
	my $printer = shift;
	my $lpstat =  Yaffas::Constant::APPLICATION->{'lpstat'};

	my $r = Yaffas::do_back_quote($lpstat, "-p", $printer);
	my $status;
	if($r =~ /gesperrt/ || $r =~ /disabled/) {
		$status = 0;
	}
	elsif($r =~ /freigegeben/ ||$r =~ /enabled/) {
		$status = 1;
	}

	return $status;
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
