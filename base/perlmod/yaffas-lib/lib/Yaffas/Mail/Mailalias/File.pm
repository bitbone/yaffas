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
);
our $dir_transport = "zarafa-publicfolder:";


sub _write {
    my $mode = shift;
    my $data = shift;

    my $bkc = Yaffas::File::Config->new($alias_file{$mode}, {
		-SplitPolicy => 'custom',
		-SplitDelimiter => '\s+',
		-StoreDelimiter => ' ',
	});
	foreach my $key (keys $data) {
		if ($mode eq "DIR") {
			# prefix each target folder with our postfix transport:
			$data->{$key} = $dir_transport . @{$data->{$key}}[-1];
		} else {
			$data->{$key} = join(",", @{$data->{$key}});
		}
	}
    $bkc->get_cfg()->save_file($alias_file{$mode}, $data);

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
    my $data = $bkc->get_cfg_values();
	for my $key (keys($data)) {
		my @parts;
		if ($mode eq "DIR") {
			# remove the postfix transport from the folder name
			@parts = $data->{$key} =~ s/^$dir_transport//r;
		} else {
			@parts = split(/\s*,\s*/, $data->{$key});
		}
		$data->{$key} = \@parts;
	}
	return $data;
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
