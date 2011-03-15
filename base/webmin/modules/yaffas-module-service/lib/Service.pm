#!/usr/bin/perl
package Yaffas::Module::Service;

use strict;
use warnings;

use Yaffas;

use Yaffas::Conf;
use Yaffas::Conf::Function;

use Yaffas::Constant;
use Yaffas::File::Config;


our @ISA = ("Yaffas::Module");

sub watch($$$;$$$) {
	my (
		$service,        $bk_service,   $should_run,
		$check_attempts, $notification, $restart_tries
	  )
	  = @_;
	defined $check_attempts || ( $check_attempts = 5 );
	defined $notification   || ( $notification   = 1 );
	defined $restart_tries  || ( $restart_tries  = 2 );

	my $config_file = Yaffas::Constant::FILE->{'goggletyke_cfg'};
	my $bkfc        = Yaffas::File::Config->new($config_file);
	my $config      = $bkfc->get_cfg_values();

	$config->{$service}->{bk_service}     = $bk_service;
	$config->{$service}->{should_run}     = ( $should_run ? 1 : 0 );
	$config->{$service}->{check_attempts} = $check_attempts;
	$config->{$service}->{notification}   = $notification;
	$config->{$service}->{restart_tries}  = $restart_tries;

	$bkfc->write();
}

sub conf_dump(){
	open( CFG, '<', Yaffas::Constant::FILE->{"goggletyke_cfg"} ) or return undef;
	my @goggleconf = ();

	while( <CFG> ){
		my $line = $_;
		chomp( $line );
		push( @goggleconf, $line );
	}
	close( CFG );

	my $conf = Yaffas::Conf->new();
	$conf->delete_section( 'goggle_cfg' );

	my $section = $conf->section( 'goggle_cfg' );
	my $function    = Yaffas::Conf::Function->new( 'goggle_cfg', 'Yaffas::Module::Service::restore' );

	$function->add_param({type => 'hash', param => \@goggleconf});

	$section->add_func($function);
	$conf->save();

	return 1;
}


sub restore($){
 	        my $goggle_cfg = Yaffas::File->new( Yaffas::Constant::FILE->{'goggletyke_cfg'}, \@_ );
 	        $goggle_cfg->write();

		return 1;

}
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
