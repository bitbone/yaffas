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
my %types = map { $_ => "lbl_".$_ } @known_types;

my @known_colors = qw(silver white);
my %colors = map { $_ => "lbl_".$_ } @known_colors;

my $theme_color = "THEME_COLOR";

my $filename = Yaffas::Constant::FILE->{webaccess_config};

sub set_config_value {
	my $type = shift;
	my $value = shift;

	throw Yaffas::Exception("err_undefined_type") unless exists($types{$type}) or ($type eq $theme_color);
	
	my $file = Yaffas::File->new($filename);

	throw Yaffas::Exception("err_webaccess_config") unless defined $file;

	my $rex = qr/define\(["']$type["'],\s*["']{0,1}(\w+)["']{0,1}\);/;
	my $linenr = $file->search_line($rex);
	
	if(defined $linenr) {
		my $delim = ($value eq "true" || $value eq "false") ? "" : "'";
		my $newline = "\tdefine('$type', $delim$value$delim);";
		$file->splice_line($linenr, 1, $newline);
		$file->write();
	}
}

sub get_config_value {
	my $type = shift;

	my $file = Yaffas::File->new($filename);

	throw Yaffas::Exception("err_webaccess_config") unless defined $file;

	my $value;
	my $rex = qr/define\(["']$type["'],\s*["']{0,1}(\w+)["']{0,1}\);/;
	my $linenr = $file->search_line($rex);
	
	if(defined $linenr) {
		my $line = $file->get_content($linenr);
		$line =~ m/$rex/;
		$value = $1;	
	}

	return $value;
}

sub get_webaccess_values {
	my $options = {};	
	foreach my $type (keys %types) {
		$options->{$type} = get_config_value($type);
	}

	return $options;
}

sub set_theme_color {
	my $color = shift;

	throw Yaffas::Exception("err_undefined_color") unless exists($colors{$color});

	set_config_value($theme_color, $color);
}

sub get_theme_color {
	my $color = get_config_value("THEME_COLOR");
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
	my @conf_types;
	push @conf_types, @known_types;
	push @conf_types, $theme_color;
	for my $type (@conf_types) {
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
