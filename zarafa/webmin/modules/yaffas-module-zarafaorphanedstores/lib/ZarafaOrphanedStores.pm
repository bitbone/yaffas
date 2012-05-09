package Yaffas::Module::ZarafaOrphanedStores;

use strict;
use warnings;

use Yaffas::Exception;
use Error qw(:try);
use Switch;

use Yaffas::UGM;
use Yaffas::Module::Users;
use Yaffas::Module::Mailsrv::Postfix;
use Yaffas::Constant;

our @ISA = qw(Yaffas::Module);

=pod

=head1 NAME

Yaffas::Module::ZarafaOrphanedStores - Function for management of zarafa resources

=head1 SYNOPSIS

use Yaffas::Module::ZarafaOrphanedStores

=head1 DESCRIPTION

Yaffas::Module::ZarafaOrphanedStores provides fuctions for zarafa resource managment.

=head1 FUNCTIONS

=over

=item get_orphaned_stores ()

Returns an array of all orphaned stores.

=cut

sub get_orphaned_stores () {
	my @stores;
	my $columns = {};
	my @result = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '--list-orphans');
	foreach my $line(@result) {
		next if $line =~ m/^\s*$/;
		next if $line =~ m/^Stores without users:/;
		next if $line =~ m/^\s*----------/;
		next if $line =~ m/^$/;
		my @fields = split /\t+/, $line;
		if($line =~ m/Store guid\s+Guessed username\s+Last modified\s+Store size\s+Store type/) {
			for(my $i = 0; $i < @fields; $i++) {
				switch ($fields[$i]) {
					case "Store guid" { $columns->{'guid'} = $i }
					case "Guessed username" { $columns->{'username'} = $i }
					case "Last modified" { $columns->{'modified'} = $i }
					case "Store size" { $columns->{'size'} = $i }
					case "Store type" { $columns->{'type'} = $i }
				}
			}	
			next;
		}
		my $store = {
			'guid' => $fields[$columns->{'guid'}],
			'username' => $fields[$columns->{'username'}],
			'modified' => $fields[$columns->{'modified'}],
			'size' => $fields[$columns->{'size'}],
			'type' => $fields[$columns->{'type'}],
		};
		push @stores, $store;
	}
	return @stores;
}

sub attach_orphan {
	my $orphan = shift;
	_log_test("".localtime().": attach_orphan: $orphan\n");
}

sub public_orphan {
	my $orphan = shift;
	my $result = Yaffas::do_back_quote_2( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '--hook-store' , $orphan, '--copyto-public');
#	if($result =~ m/Unable to get the store information. store guid/) {
	unless($result =~ m/^$/) {
		throw new Yaffas::Exception("err_store_not_found", $result);
	}
}

sub delete_orphan {
	my $orphan = shift;
	my $result = Yaffas::do_back_quote_2( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '--remove-store', $orphan);
	if($result =~ m/Unable to remove store, object not found/) {
		throw new Yaffas::Exception("err_store_not_found");
	}
}

sub _log_test {
	my $message = shift;
	open(FILE, ">/tmp/orphans.log");
	print FILE $message;
	close FILE;
}

sub conf_dump() {
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
