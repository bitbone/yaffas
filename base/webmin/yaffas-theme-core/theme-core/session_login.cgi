#!/usr/bin/perl
# session_login.cgi
# Display the login form used in session login mode

$pragma_no_cache = 1;
#$ENV{'MINISERV_INTERNAL'} || die "Can only be called by miniserv.pl";
require './web-lib.pl';
use Yaffas::UI;
use JSON;
use strict;
init_config();
ReadParse();

my $cgi = $Cgi;
if ($main::gconfig{'loginbanner'} && $ENV{'HTTP_COOKIE'} !~ /banner=1/ &&
		!$main::in{'logout'} && !$main::in{'failed'} && !$main::in{'timed_out'}) {
	# Show pre-login HTML page
	print "Set-Cookie: banner=1; path=/\r\n";
	&PrintHeader();
	my $url = $main::in{'page'};
	open(BANNER, $main::gconfig{'loginbanner'});
	while(<BANNER>) {
		s/LOGINURL/$url/g;
		print;
	}
	close(BANNER);
	return;
}

if ($main::in{'logout'}) {
	$ENV{'REMOTE_USER'} = "";
}


my $sec = uc($ENV{'HTTPS'}) eq 'ON' ? "; secure" : "";
print "Set-Cookie: banner=0; path=/$sec\r\n" if ($main::gconfig{'loginbanner'});
print "Set-Cookie: user=x; path=/$sec\r\n" if ($main::in{'logout'});
print "Set-Cookie: testing=1; path=/$sec\r\n";

header("login");

my %problems;

if (defined($main::in{'timed_out'})) {
	$problems{timeout} = 1;
}

if ($main::logged_in ne "1") {
	$problems{session_replaced} = 1;
}

if (keys %problems) {
	print $cgi->div({-id=>"problems", -class=>"hidden"}, to_json(\%problems, {latin1 => 1}));
}

# print lang to browser, because globals.cgi doesn't work here
print $cgi->div({-id=>"lang", class=>"hidden"}, to_json({global => {map {$_ => $main::text{$_}} qw(lbl_yes lbl_no lbl_error lbl_loading)}}));

if ($main::logged_in eq "1") {
		print $cgi->div({-id=>"response"}, $cgi->start_form(-method => 'post', -action => 'admin.cgi', -style => "display: block;"),
		  $cgi->div({class=>"section", style=>"margin-left: 5px;margin-right: 5px;"},
								$cgi->h1({class => 'warning'}, $main::lang{'admin_warning'}),
								$cgi->div(
										  $cgi->p($main::logged_in_ip ? main::text('admin_text_ip', $main::logged_in_ip) : $main::text{'admin_text'}),
										  $cgi->p($main::lang{'admin_ask'})
										 )
							   ),
		  $cgi->div({class=>"section_button", style=>"margin-left: 5px;margin-right: 5px;"}, $cgi->submit('force',$main::lang{'admin_submit'})),
		  $cgi->end_form);
}

if (defined($main::in{'failed'})) {
	print $cgi->div({-class=>"error"}, $main::text{'session_failed'});
}

print $cgi->start_div( {-id=>"login", -style=>'text-align:center'} );
print $cgi->div({-class=>"hd"}, "Login");
print $cgi->start_div({-class=>"bd"});
print $cgi->startform( {-action=>"$main::gconfig{'webprefix'}/session_login.cgi", -method=>"post"} );
print $cgi->table( {-class=> "section", -style=>"margin-left: auto; margin-right:auto;"},
				   $cgi->Tr([
							$cgi->td( {}, [
									  $main::text{'session_user'},
									  $cgi->input(
												  {
												  -id=>"user",
												  -type=>"text",
												  -name=>"user",
												  -size=>"20",
												  }
												 )
									  ]),
							$cgi->td( {}, [
									  $main::text{'session_pass'},
									  $cgi->input( {-id=>"password", -type=>"password", -name=>"pass", -size=>"20"} )
									  ] )
							])
				 );
print $cgi->end_form();
print $cgi->end_div();
print $cgi->end_div();

footer("login");
return 1;
