package Yaffas::Module::ZarafaResources;

use strict;
use warnings;

use Yaffas::Exception;
use Error qw(:try);

use Yaffas::UGM;
use Yaffas::Module::Users;
use Yaffas::Module::Mailsrv::Postfix;
use Yaffas::Constant;

our @ISA = qw(Yaffas::Module);

=pod

=head1 NAME

Yaffas::Module::ZarafaResources - Function for management of zarafa resources

=head1 SYNOPSIS

use Yaffas::Module::ZarafaResources

=head1 DESCRIPTION

Yaffas::Module::ZarafaResources provides fuctions for zarafa resource managment.

=head1 FUNCTIONS

=over

=item get_resources ()

Returns an array of all resources.

=cut

sub get_resources () {
	return map {chomp($_); $_} grep {
		my @tmp =
		  Yaffas::do_back_quote(
			Yaffas::Constant::APPLICATION->{'zarafa_admin'},
			'--details', $_ );
		my $is_resource = 0;
		foreach (@tmp) {
			next unless $_ =~ m/^Auto-accept meeting req:\s*(yes|no)/;
			$is_resource = 1 if $1 eq 'yes';
		}
		$is_resource == 1;
	} Yaffas::UGM::get_user_entries();
}

=item create_resource ( RESOURCE, DESCRIPTION, EMAIL, DECLINE_CONFLICT, DECLINE_RECURRING )

Creates a new resource.

=cut

sub create_resource ($$$$) {
	throw Yaffas::Exception("err_no_local_auth") unless  Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP || Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES;

	my ( $resource, $description, $decline_conflict,
		$decline_recurring ) = @_;

	# 'resource' as givenname for all resources:
	# a givenname is required and none need to be set
	# DO NOT USE AS IDENTIFIER FOR RESOURCES! SEE 'get_resources'

	my @domains = Yaffas::Module::Mailsrv::Postfix::get_accept_domains();

	if (scalar @domains == 0) {
		throw Yaffas::Exception("err_no_domains");
	}

	my $email = $resource.'@';
	for my $domain (@domains) {
		unless($domain =~ m/^localhost$/) {
			$email .= $domain;
			last;
		}
	}

	Yaffas::UGM::add_user( $resource, $email, 'resource', $description );
	modify_resource( $resource, $description, $decline_conflict, $decline_recurring );
}

=item delete_resource ( RESOURCE )

Deletes a resource.

=cut

sub delete_resource ($) {
	throw Yaffas::Exception("err_no_local_auth") unless  Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP || Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES;

	my $resource = shift;
	chomp($resource);
	Yaffas::UGM::rm_user($resource);
}

=item modify_resource ( RESOURCE, DESCRIPTION, DECLINE_CONFLICT, DECLINE_RECURRING )

Modifies an existing resource.

=cut

sub modify_resource ($$$$) {
	my ( $resource, $description, $decline_conflict, $decline_recurring ) = @_;

	if (Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP || Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES) {
		Yaffas::Module::Users::set_zarafa_shared( $resource, 1 );
		Yaffas::UGM::gecos( $resource, 'resource', $description );
		my $pass = map{("a".."z","A".."Z",0..9)[int(rand(62))]}(1..26);
		Yaffas::UGM::password($resource, $pass);
		Yaffas::UGM::set_suppl_groups($resource, "");
	}

	system( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '-u', $resource, '--mr-accept', '1' );
	system( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '-u', $resource, '--mr-decline-conflict', $decline_conflict );
	system( Yaffas::Constant::APPLICATION->{'zarafa_admin'}, '-u', $resource, '--mr-decline-recurring', $decline_recurring );
}

=item get_resource_details ( RESOURCE )

Returns details of a resource as a hash.

The keys of the Hash are: "description", "email", "decline_conflict", "decline_recurring"

=cut

sub get_resource_details ($) {
	my $resource = shift;
	my %details  = (
		description       => '',
		email             => '',
		decline_conflict  => 0,
		decline_recurring => 0
	);

	# filter out givenname ('resources ')
	$details{description} = Yaffas::UGM::gecos($resource);
	$details{description} = $1 if $details{description} =~ /^resource\s(.*)$/;

	$details{email} = Yaffas::UGM::get_email($resource);
	my @zarafa_admin_details =
	  Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{zarafa_admin},
		'--details', $resource );
	foreach my $line (@zarafa_admin_details) {
		if ( $line =~ m/^Decline dbl meetingreq:\s*(yes|no)/ ) {
			$details{decline_conflict} = ( $1 eq 'yes' ? 1 : 0 );
		}
		elsif ( $line =~ m/^Decline recur meet\.req:\s*(yes|no)/ ) {
			$details{decline_recurring} = ( $1 eq 'yes' ? 1 : 0 );
		}
	}

	return %details;
}

sub conf_dump() {
	my $bkconf  = Yaffas::Conf->new();
	my $section = $bkconf->section('bbzarafaresources');
	foreach my $resource ( get_resources() ) {
		$section->del_func( 'modify_resource_' . $resource );
		my $func = Yaffas::Conf::Function->new( 'modify_resource_' . $resource,
			'Yaffas::Module::ZarafaResources::modify_resource' );
		my %details = get_resource_details($resource);
		$func->add_param( { type => 'scalar', param => $resource } );
		$func->add_param(
			{ type => 'scalar', param => $details{description} } );
		$func->add_param(
			{ type => 'scalar', param => $details{decline_conflict} } );
		$func->add_param(
			{ type => 'scalar', param => $details{decline_recurring} } );
		$section->add_func($func);
	}
	$bkconf->save();
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
