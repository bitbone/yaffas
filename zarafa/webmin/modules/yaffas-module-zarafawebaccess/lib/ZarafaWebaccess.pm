package Yaffas::Module::ZarafaWebaccess;

use strict;
use warnings;

sub BEGIN {
    use Exporter;
    our (@ISA, @EXPORT_OK);
    @ISA = qw(Exporter Yaffas::Module);
    @EXPORT_OK = qw(&get_config_value &set_config_value &get_webaccess_values &get_theme_color &set_theme_color &get_color_labels &get_option_label);
}


use Yaffas::File;
use Yaffas::Exception;
use Yaffas::Constant;
use Error qw(:try);

my @known_types = qw(DISABLE_FULL_GAB ENABLE_GAB_ALPHABETBAR ENABLE_PUBLIC_FOLDERS DISABLE_DELETE_IN_RESTORE_ITEMS FCKEDITOR_SPELLCHECKER_ENABLED);
my $theme_color = "THEME_COLOR";

my %types = map { $_ => "lbl_".$_ } @known_types;

my @known_colors = qw(silver white);
my %colors = map { $_ => "lbl_".$_ } @known_colors;

my $conf_file = Yaffas::Constant::FILE->{webaccess_config};

sub set_config_value {
	my $type = shift;
	my $value = shift;

	throw Yaffas::Exception("err_undefined_type") unless exists($types{$type}) or ($type eq $theme_color);
}

sub get_config_value {
	my $type = shift;
	my $value;


	return $value;
}

sub get_webaccess_values {
	my $options = {};	
	foreach my $type (keys %types) {
		$options->{$type} = "true";
	}

	return $options;
}

sub set_theme_color {
	my $color = shift;

	throw Yaffas::Exception("err_undefined_color") unless exists($colors{$color});

	set_config_value($theme_color, $color);
}

sub get_theme_color {
	my $color;
	return $color;
}

sub get_color_label {
	my $color = shift;
	return $colors{$color};
}

sub get_color_labels {
	return \%colors;
}

sub get_option_label {
	my $type = shift;
	return $types{$type};
}

sub conf_dump() {
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("zarafawebaccess");
	my $func;
	for my $type (qw(DISABLE_FULL_GAB ENABLE_GAB_ALPHABETBAR ENABLE_PUBLIC_FOLDERS DISABLE_DELETE_IN_RESTORE_ITEMS FCKEDITOR_SPELLCHECKER_ENABLED THEME_COLOR)) {
		$func = Yaffas::Conf::Function->new("webaccess-config-$type", "Yaffas::Module::ZarafaWebaccess::set_config_value");
		$func->add_param({type => "scalar", param => $type});
		$func->add_param({type => "scalar", param => get_config_value($type)});
		$sec->del_func("webaccess-config-$type");
		$sec->add_func($func);
	}

	$bkc->save();
	return 1;
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
