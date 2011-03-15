#!/usr/bin/perl
package Yaffas::Module::Group;
use strict;
use warnings;

use Error qw(:try);
use Yaffas::Exception;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::UGM qw(group_exists add_group get_groups_name rm_group);
use Yaffas::Conf;
use Yaffas::Conf::Function;

use Yaffas::Module;
our @ISA = qw(Yaffas::Module);


sub add_groups($@) {
    my $bke = Yaffas::Exception->new();

    my $filetype = shift;
    unless (@_) {
	$bke->add('err_input','');
	throw $bke;
    }

    foreach my $group (@_) {
	$group =~ s/^\s*//;
	$group =~ s/\s*$//;
	my $check_ok = 1;

	unless (Yaffas::Check::groupname($group)) {
	    $bke->add("err_newgroup_name", $group);
	    $check_ok = 0;
	} elsif (group_exists($group)) {
	    $bke->add('err_group_already_exists', $group);
	    $check_ok = 0;
	}

	if ($check_ok) {
	    if( add_group($group) ) {
		Yaffas::UGM::mod_group_ftype({$group => $filetype}) 
			if (Yaffas::Product::check_product("fax"));
	    }else {
		# add group schlug fehl
		$bke->add('err_create', $group);
	    }
	}
    }
    throw $bke if $bke;
    return 1;
}

sub del_groups(@) {
    my $bke = Yaffas::Exception->new();
    unless (@_){
	$bke->add('err_input');
	throw $bke;
    }
    foreach (@_) {
	rm_group($_) or $bke->add('err_delete', $_);
    }
    throw $bke if $bke;
    return 1;
}

sub set_groups_filetype (\@\@) {
    my $group = shift;
    my $type = shift;

    my $bke = Yaffas::Exception->new();

    for (0..$#{$group}) {
	my $g = $group->[$_];
	unless (Yaffas::UGM::group_exists($g)) {
	    $bke->add('err_group_not_exist',$g);
	}
    }

    ## error melden
    throw $bke if $bke;

    for (0..$#{$group}) {
	my ($g, $f) = ($group->[$_], $type->[$_]);

	Yaffas::UGM::mod_group_ftype({$g => $f})
		if (Yaffas::Product::check_product("fax"));

    }
    return 1;
}

sub conf_dump {
    1;
}

1;
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
