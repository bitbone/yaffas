#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Product qw(check_product);
use Sort::Naturally;
use Yaffas::Constant;
use Yaffas::Module::Mailq;
use Text::Iconv;
use JSON;

Yaffas::json_header();

my $mailq = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{mailq} );
my $entries = Yaffas::Module::Mailq::parse_mailq($mailq);

my @return_array;

if (ref $entries eq "ARRAY") {

    foreach my $line (@{$entries}) {
        my @recv = grep {!/\(.*\)/} @{$line->{remaining_rcpts}};
        my @err = grep {/\(.*\)/} @{$line->{remaining_rcpts}};
        push @return_array, {
            id => $line->{queue_id},
            sender => $line->{sender},
            receiver => \@recv,
            size => $line->{size},
            "time" => $line->{date},
            status => join "\n", @err, $line->{error_string},
        };
    }
}

print to_json({"Response" => \@return_array});

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
