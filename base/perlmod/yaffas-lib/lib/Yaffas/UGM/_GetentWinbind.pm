#!/usr/bin/env perl

# This package aims to simulate the behaviour of the `getent` utility for winbind use cases.
# In other words, it provides access to winbind as if nss_winbind was configured
# on the system. It does not return any local (/etc/passwd) entries.
# Use this if nss_winbind does not work for some reason...
#
# By default, this wrapper will not be used by yaffas/bitkit.
# It must be enabled by symlinking it to /opt/yaffas/lib/perl5/Yaffas/UGM/GetentWinbind.pm
#
# Please also note, that currently this package is not used as a perl package, but
# rather as an external script as this simplifies compatibility with
# `getent`.

use strict;
use warnings;
package Yaffas::UGM::GetentWinbind;
use lib "/opt/yaffas/lib/perl5/";
use Error::Simple;
use Yaffas::Constant;

my $WBINFO = Yaffas::Constant::APPLICATION->{wbinfo};

sub new($$) {
	my $class = shift;
	my $db = shift;
	my %args;
	if ($db eq "passwd") {
		%args = (
			flag_list_entities => "--domain-users",
			flag_entity_info => "--user-info",
		);
	} elsif ($db eq "group") {
		%args = (
			flag_list_entities => "--domain-groups",
			flag_entity_info => "--group-info",
		);
	} else {
		throw Error::Simple("unsupported db $db");
	}
	return bless { %args }, $class;
}

sub get_entries($) {
	my $self = shift;
	my $db = shift;
	my @result = ();
	open(my $output, "-|", $WBINFO, $self->{flag_list_entities});
	while (my $entity = <$output>) {
		$entity =~ s/[\r\n]+\Z//;
		push(@result, $self->get_entry($entity));
	}
	close($output);
	return \@result;
}

sub get_entry($) {
	my $self = shift;
	my $entity = shift;
	open(my $output, "-|", $WBINFO, $self->{flag_entity_info}, $entity);
	my $result = <$output>;
	close($output);
	return $result if defined($result);
	return "";
}

sub help() {
	print STDERR "Usage: $0 [passwd|group] [[name]]\n";
}

sub main() {
	my $num_args = $#ARGV + 1;
	if ($num_args < 1) {
		help();
		exit(1);
	}

	my $db = __PACKAGE__->new($ARGV[0]);

	if ($num_args == 1) {
		print(@{$db->get_entries()});
	} elsif ($num_args == 2) {
		print($db->get_entry($ARGV[1]));
	} else {
		help();
		exit(3);
	}
}
__PACKAGE__->main unless caller;


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

