#!/usr/bin/perl
package Yaffas::Mail::Mailalias::File;

use strict;
use warnings;

use Yaffas::File::Config;
use Yaffas::Constant;

my %alias_file = (
    "USER" => Yaffas::Constant::FILE->{postfix_local_aliases},
    "MAIL" => Yaffas::Constant::FILE->{postfix_local_aliases},
    "DIR" => Yaffas::Constant::FILE->{postfix_transport_publicfolder},
	"DIR_virtual" => Yaffas::Constant::FILE->{postfix_publicfolder_aliases}
);
our $dir_transport = "zarafa-publicfolder:";
our $dir_domain_suffix = ".zarafa-publicfolder";

sub _write {
    my $mode = shift;
    my %data = %{shift()};

    my $bkc = Yaffas::File::Config->new($alias_file{$mode}, {
		-SplitPolicy => 'custom',
		-SplitDelimiter => '\s+',
		-StoreDelimiter => ' ',
	}, "");
	my %writedata;
	foreach my $key (keys %data) {
		if ($mode eq "DIR") {
			# prefix each target folder with our postfix transport:
			$writedata{$key . $dir_domain_suffix} = $dir_transport . @{$data{$key}}[-1];
		} else {
			$writedata{$key} = join(",", @{$data{$key}});
		}
	}
    $bkc->get_cfg()->save_file($alias_file{$mode}, \%writedata);

    Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{postmap}, $alias_file{$mode});

	if ($mode ne "DIR") {
		return 1;
	}

	# dir aliasing also needs a special virtual alias file,
	# which will now be updated:
	$mode = "DIR_virtual";
    $bkc = Yaffas::File::Config->new($alias_file{$mode}, {
		-SplitPolicy => 'custom',
		-SplitDelimiter => '\s+',
		-StoreDelimiter => ' ',
	});
	%writedata = ();
	foreach my $key (keys %data) {
		$writedata{$key} = $key . $dir_domain_suffix;
	}
    $bkc->get_cfg()->save_file($alias_file{$mode}, \%writedata);

    Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{postmap}, $alias_file{$mode});

    return 1;
}

sub _read {
    my $mode = shift || "USER";
    my $bkc = Yaffas::File::Config->new($alias_file{$mode},
        {
            -SplitPolicy => 'custom',
            -SplitDelimiter => '\s+',
            -StoreDelimiter => ' ',
        });
    my %data = %{$bkc->get_cfg_values()};
	my %returndata;
	for my $key (keys(%data)) {
		my @parts;
		if ($mode eq "DIR") {
			# remove the postfix transport from the folder name
			my $fullname = $data{$key};
			$fullname =~ s/^$dir_transport//;
			@parts = $fullname;
			$key =~ s/$dir_domain_suffix$//;
		} else {
			@parts = split(/\s*,\s*/, $data{$key});
		}
		$returndata{$key} = \@parts;
	}
	return \%returndata;
}

return 1;

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
