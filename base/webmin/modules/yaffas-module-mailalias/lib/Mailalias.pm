#!/usr/bin/perl
package Yaffas::Module::Mailalias;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our (@ISA, @EXPORT_OK);
	@ISA = qw(Exporter Yaffas::Module);
	@EXPORT_OK = qw(&list_alias &rm_alias &add_alias);
}

use Yaffas::Conf;
use Yaffas::Conf::Section;
use Yaffas::Conf::Function;
use Yaffas::Mail::Mailalias;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Yaffas::UI;
use Error qw(:try);
use Yaffas::Exception;


=pod

=head1 NAME

Yaffas::Module::Mailalias

=head1 DESCRIPTION

This Module no longer provides functions for Webmin module bbmailalias.

=head1 EXAMPLE

 my $a = new Yaffas::Module::Mailalias->new();
 $a->add("alias", "user");
 $a->remove("rmalias");
 $a->write();

=head1 OBJECT-ORIENTED FUNCTIONS

=over

=item B<new>

Creates a new instance of Yaffas::Mail::Mailalias

=cut

sub new {
	return Yaffas::Mail::Mailalias->new();
}


=back

=head1 PROCEDURAL FUNCTIONS

=over

=item rm_alias ()

=cut

sub rm_alias ($) {
	Yaffas::Mail::Mailalias::rm_alias(shift);
}

=item list_alias ()

returns a hash of all aliases.

=cut

sub list_alias() {
	Yaffas::Mail::Mailalias::list_alias();
}

=item add_alias ( FROM TO)

=cut

sub add_alias($$) {
	my($from, $to) = @_;
	Yaffas::Mail::Mailalias::add_alias($from, $to);
}

## -------------------------------------------------------------------------- ##

sub conf_dump() {
	return 1;
}

sub add_edit_alias {
	my $from    = $main::in{from};
	my @to;
    my $type    = uc $main::in{type};

	my $e           = Yaffas::Exception->new();
	my $alias;

    if ($type eq "USER") {
        @to = split /\s*\0\s*/, $main::in{to};
    }
    elsif ($type eq "MAIL") {
        @to = split /\s*,\s*/, $main::in{recipient};
    }
	elsif ($type eq "DIR") {
		@to = $main::in{dir};
	}
    else {
        $e->add( "err_unknown_type", $type);
    }

	Yaffas::Check::alias($from) or $e->add( "err_check_alias", $from );

    foreach my $to (@to) {
        if ($type eq "user") {
            if (Yaffas::UGM::user_exists($to) and Yaffas::Check::username($to)) {
                next;
            }
            $e->add( "err_check_alias", $to );
        }
        elsif($type eq "manual") {
            if ($type eq "manual" and Yaffas::Check::email($to)) {
                next;
            }
            $e->add( "err_check_alias", $to );
        }
		elsif ($type eq "dir") {
			if (!$to || $to =~ /[\r\n]/) {
				$e->add("err_check_folder");
			}
			# no further checks here, we accept any folder name
		}
    }

	if ($e) {
		print Yaffas::UI::all_error_box($e);
		return;
	}
	my @err;
	# remove all previous occurences and re-add the new alias
	try {
		for my $tmptype ("USER", "MAIL", "DIR") {
			$alias = Yaffas::Mail::Mailalias->new($tmptype);
			$alias->remove( $from );
			if ($tmptype eq $type) {
				$alias->add( $from, $_ ) for (@to);
			}
			$alias->write();
		}
	}
	catch Yaffas::Exception with {
		push @err, [ shift, $from ];
	}
	otherwise {
		print Yaffas::UI::error_box(shift);
	};

	if (@err) {
		print Yaffas::UI::all_error_box( $_->[0] ) for @err;
	}
	else {
		print Yaffas::UI::ok_box();
	}
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
