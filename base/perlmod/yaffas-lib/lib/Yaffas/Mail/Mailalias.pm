#!/usr/bin/perl
package Yaffas::Mail::Mailalias;

use strict;
use warnings;

sub BEGIN {
	use Exporter;
	our (@ISA, @EXPORT_OK);
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(&list_alias &rm_alias &add_alias);
}

use Yaffas::File::Config;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::Check;
use Yaffas::UGM;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Yaffas::Mail::Mailalias::File;
use Yaffas::Mail::Mailalias::LDAP;

## prototypes ##
sub rm_alias($);
sub add_alias($$);
sub rm_alias_conf($);
sub add_alias_conf($$);
sub list_alias(;$);

=pod

=head1 NAME

Yaffas::Mail::Mailalias

=head1 DESCRIPTION

This Module provides functions for Webmin module bbmailalias.

=head1 EXAMPLE

 my $a = new Yaffas::Mail::Mailalias->new();
 $a->add("alias", "user");
 $a->remove("rmalias");
 $a->write();

=head1 OBJECT-ORIENTED FUNCTIONS

=over

=item new

Creates a new instance of this Class

=cut

sub new {
	my $class = shift;
	my $mode = shift;
	my $self = {};

	$mode = "USER" unless (defined $mode && ($mode eq "DIR"));

	my $bkc = Yaffas::File::Config->new(Yaffas::Constant::DIR->{bkfiles}.'alias.cfg', {
			-SplitPolicy => 'custom',
			-SplitDelimiter => '=\s*',
			-StoreDelimiter => '=',
		});
	my $c = $bkc->get_cfg_values();

	if($c->{'method'} && $c->{'method'} =~ m#^ldap\z#i)
	{
		*_write = *Yaffas::Mail::Mailalias::LDAP::_write;
		*_read = *Yaffas::Mail::Mailalias::LDAP::_read;
	}
	else
	{
		*_write = *Yaffas::Mail::Mailalias::File::_write;
		*_read = *Yaffas::Mail::Mailalias::File::_read;
	}


	$self->{ALIAS} = _read($mode);
	$self->{MODE} = $mode;
	bless $self, $class;
	return $self;
}

=item add ( ALIAS, DESTINATION )

Adds a alias

=cut

sub add {
	my $self = shift;
	my $from = shift;
	my $to = shift;
	throw Yaffas::Exception("err_alias_name", $from) unless (Yaffas::Check::alias($from));
	throw Yaffas::Exception("err_alias_name", $to) if ($to =~ /[|>]+/);

	if (defined($self->{ALIAS}->{$from})) {
		# test if the alias is allready in the list.
		my @to = split /, /, $self->{ALIAS}->{$from};#
		if (grep {$_ eq $to} @to) {
			# schon vorhanden
			throw Yaffas::Exception("err_already_exists", $from . " -> " . $to);
		} else {
			# noch nicht vorhanden.
			$self->{ALIAS}->{$from} .= ", $to";
		}
	}
	else {
		$self->{ALIAS}->{$from} = $to;
	}
}

=item remove ( ALIAS, DESTINATION )

Removes given alias. If DESTINATION is ommitted than the whole ALIAS is removed.

=cut

sub remove {
	my $self = shift;
	my $from = shift;
	my $to = shift;

	return undef unless $from;

	my @names;
	if ($to) {
		@names = split /\s*,\s*/, $self->{ALIAS}->{$from};
		@names = grep {$_ ne $to} @names;
	}

	if (@names) {
		$self->{ALIAS}->{$from} = join ", ", @names;
	} else {
		delete $self->{ALIAS}->{$from};
	}
}

=item get_user_aliases ( USER )

Returns a list of aliases of given USER

=cut

sub get_user_aliases {
	my $self = shift;
	my $to = shift;

	return undef unless $to;
	my @ret;

	foreach my $alias (keys %{$self->{ALIAS}}) {
		foreach my $n (split /\s*,\s*/, $self->{ALIAS}->{$alias}) {
			if ($n eq $to) {
				push @ret, $alias;
			}
		}
	}
	return @ret;
}

=item get_alias_destination ( ALIAS )

Returns all destinations for the given ALIAS

=cut

sub get_alias_destination {
	my $self = shift;
	my $alias = shift;

	return split /\s*,\s*/, ($self->{ALIAS}->{$alias} || return() );

}

=item get_all

Returns a hash of all aliases

=cut

sub get_all {
	my $self = shift;
	return %{$self->{ALIAS}};
}

=item forward( USER, [ FORWARDS ] )

Creates a forward for USERs e-mails to the given FORWARDS.
If no FORWARDS are given, return the current ones.

=cut

sub forward {
	my $self = shift;
	my $user = shift;
	my @fw = @_;

	return undef unless $self->{MODE} eq "USER";

	if (@fw > 0) {
		# set mode
		my $bke = Yaffas::Exception->new();
		foreach (@fw) {
			$bke->add("err_user_or_mail", $_) unless (Yaffas::Check::email($_) or Yaffas::UGM::user_exists($_));
		}
		throw $bke if $bke;

		$self->{ALIAS}->{$user} = join ", ", $user, @fw;
	}
	else {
		# get mode
		my $forward = "";
		if (defined $self->{ALIAS}->{$user}) {
			my @forwards = split /\s*,\s*/, $self->{ALIAS}->{$user};

			if(grep {$_ eq $user} @forwards) {
				$forward = join ", ", grep {$_ ne $user} @forwards;
			}
		}
		return $forward;
	}
}

=item forward_delete ( USER )

Deletes the forward alias for USER.

=cut

sub forward_delete {
	my $self = shift;
	my $user = shift;

	delete $self->{ALIAS}->{$user} if defined($self->{ALIAS}->{$user});
}

=item write

Saves all settings

=cut

sub write {
	my $self = shift;
	_write($self->{MODE}, %{$self->{ALIAS}});
}


=head1 PROCEDURAL FUNCTIONS

=over

=item rm_alias ()

=cut

sub rm_alias ($) {
	my $from = shift;

	my $aliases = Yaffas::Mail::Mailalias->new();
	$aliases->remove($from);
	$aliases->write();
}

=item list_alias ([MODE])

returns a hash of all USER-aliases if MODE is omitted.
MODE can be USER or DIR.

=cut

sub list_alias(;$) {
	my $mode = shift || "USER";
	my $aliases = Yaffas::Mail::Mailalias->new($mode);
	return $aliases->get_all();
}

=item add_alias ( FROM TO)

=cut

sub add_alias($$) {
	my $from = shift;
	my $to = shift;;

	my $aliases = Yaffas::Mail::Mailalias->new();
	$aliases->add($from, $to);
	$aliases->write();
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
