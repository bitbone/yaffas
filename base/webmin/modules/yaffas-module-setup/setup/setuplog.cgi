#!/usr/bin/perl
use strict;
use warnings;
use Yaffas;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use JSON;
use Yaffas::Constant;

Yaffas::init_webmin();
ReadParse();
Yaffas::json_header();

my $status = 1;
my $log = "";

my $logfile = Yaffas::Constant::FILE->{postinst_log};

open(FILE, "<".$logfile);
while(<FILE>) {
    if($_ =~ m/all scripts finished/) {
        $log = "$main::text{'lbl_initial_conf'}";
        $status = 0;
    }
    elsif($_ =~ m#^executing.*/yaffas-([^/]*)/#) {
        $log = $1;
    }
}

print to_json( {"log" => "$main::text{'lbl_setup_execute'}: $log", "status" => $status});

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
