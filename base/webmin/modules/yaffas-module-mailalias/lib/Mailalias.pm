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
	my %aliases = list_alias();
	my $aliases;

	for my $mode (qw(DIR USER)) {
		$aliases = Yaffas::Mail::Mailalias->new($mode);
		_save_config($mode, $aliases->get_all);
	}
}

sub _save_config {
	my $mode = shift;
	my %data = @_;
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailalias");
	my $func = Yaffas::Conf::Function->new("mailalias-$mode", "Yaffas::Mail::Mailalias::_write");
	$func->add_param({type => "scalar", param => $mode});
	$func->add_param({type => "hash", param => \%data});
	$sec->del_func("mailalias-$mode");
	$sec->add_func($func);
	$bkc->save();
	return 1;
}

sub add_edit_alias {
	my $from    = $main::in{from};
	my @to      = split /\s*\0\s*/, $main::in{to};
	my @del     = split /\0/, $main::in{del_to};
	my @folders = split /\0/, $main::in{folders};

	my $e           = Yaffas::Exception->new();
	my $sf          = Yaffas::Constant::MISC()->{sharedfolder};
	my $useralias   = Yaffas::Mail::Mailalias->new();
	my $folderalias = Yaffas::Mail::Mailalias->new("DIR");

	Yaffas::Check::alias($from) or $e->add( "err_check_alias", $from );

	if ( scalar @to > 0 and scalar @folders > 0 ) {

		# both are selected
		$e->add("err_select_only_one");
	}

	my %user = $useralias->get_all();
	my @useraliases = grep /^$from$/, keys %user;

	if ( @useraliases and @folders and ( scalar @del ne scalar @useraliases ) )
	{

		# on edit: no @to is given, but @folders
		$e->add("err_select_only_one");
	}

	foreach my $to (@to) {
		unless ( Yaffas::UGM::user_exists($to)
				 or Yaffas::Check::username($to)
				 or Yaffas::Check::email($to) )
		{
			$e->add( "err_check_alias", $to );
		}
	}

	if ( Yaffas::Product::check_product("zarafa") ) {

		# convert all mailbox names to iso
		my $converter = Text::Iconv->new( "utf-8", "iso-8859-15" );
		@folders = map { $converter->convert($_) } @folders;
	}

	foreach (@folders) {
		unless ( Yaffas::Mail::check_mailbox($_) ) {
			$e->add( "err_check_alias_folder", $_ );
		}
	}

	if ($e) {
		print Yaffas::UI::all_error_box($e);
	}
	else {
		my @err;
		try {

			$useralias->remove( $from, $_ ) for (@del);
			$useralias->add( $from, $_ ) for (@to);
			$useralias->write();

			$folderalias->remove($from);
			$folderalias->add( $from, $_ ) for (@folders);
			$folderalias->write();

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
