#!/usr/bin/perl -w

require './fetchmail-lib.pl';

use strict;
use warnings;

use Yaffas;
use Yaffas::Constant;
use JSON;

Yaffas::init_webmin();

Yaffas::json_header();

$main::config{'config_file'} = Yaffas::Constant::FILE->{'fetchmailrc'};
#$main::config{'daemon_user'} = 'root';

my @conf = &parse_config_file( $main::config{'config_file'} );
@conf = grep { $_->{'poll'} } @conf;

my $cfgfile    = $main::config{'config_file'};
my $daemonuser = $main::config{'daemon_user'};

my @content = ();
my $i = 0;

foreach my $p (@conf) {
	my @users = ();
	
	foreach my $u ( @{ $p->{'users'} } ) {
		if (not $u->{'is'}) {
			$u->{'is'} = [];
		}
		push @users, sprintf "%s -> %s<br>\n", &html_escape( $u->{'user'} ),
		  &html_escape(
			@{ $u->{'is'} }
			? join( " ", @{ $u->{'is'} } )
			: $daemonuser
		  );
	}
	
	push @content, {
		"index" => $p->{"index"},
		server => $p->{poll},
		active => $p->{skip} ? 0 : 1,
		proto => $p->{proto},
		users => join "", @users
	};
	$i++;
}

print to_json({Response => \@content});
