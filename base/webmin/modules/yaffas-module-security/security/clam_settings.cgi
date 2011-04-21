#!/usr/bin/perl
use strict;
use warnings;
use Yaffas;
use Yaffas::Module::Security;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::UI qw(ok_box all_error_box);
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();

header();
ReadParse();

my $archive = $main::in{archive};
my $max_length  = $main::in{max_length};

try {
	throw Yaffas::Exception("Undefined value for archive") unless defined $archive;
	throw Yaffas::Exception("Undefined value for length") unless defined $max_length;

	throw Yaffas::Exception("Invalid value for archive") if $archive !~ m#^(true|false)\z#;
	throw Yaffas::Exception("Invalid value for length") if $max_length !~ m#^\d+\z#;

	if($archive eq 'false'){
		Yaffas::Module::Security::clam_scan_archive(0);
	} else {
		Yaffas::Module::Security::clam_scan_archive(1);
	}

	if(Yaffas::Module::Security::clam_max_length() != $max_length){
		Yaffas::Module::Security::clam_max_length($max_length);
	}

	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer();



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
