use Yaffas::UI::Help;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::UI;
use Yaffas::UI::Webmin;
use Yaffas::File;
use Yaffas::Fax;
use strict;
use warnings;

sub theme_header() {
	my $cgi = $Cgi;

	my $module = shift;

	if ($module ne "login") {
		return;
	}

	my @css;
	if (!defined($ENV{REMOTE_USER}) or $ENV{'REMOTE_USER'} eq "") {
		my $file = Yaffas::File->new("yaffastheme/index.css");
		@css = $file->get_content();
		push @css, "body {display: block !important}";
	}
	
	my $notification = "";
	if($main::gconfig{product} eq "webmin" && Yaffas::Fax::is_NeedToTakeover() && $ENV{'SCRIPT_NAME'} ne '/session_login.cgi') {
		$notification = $main::text{lbl_faxtakeover};
	}

	my @js = qw(
		yahoo
		yahoo-dom-event/yahoo-dom-event.js
		element
		dom
		button
		utilities/utilities.js
		connection
		dragdrop
		accordionview
		container
		tabview
		animation
		event
		history
		menu
		paginator
		datatable
		datasource
		get
		json
		dragdrop
		resize
		layout
		treeview
	);
	my $js_type = "-min";
	
	my $scripts = [];
	my $css = [];
	
		$scripts = [
		   (map { {-language => "JAVASCRIPT", -src=>"/yui/".( (m#/#) ? $_ : "$_/${_}${js_type}.js") } } @js),
		   { -language=>"JAVASCRIPT", -src=>($main::remote_user) ? "/javascript/start.js" : "/javascript/theme-login.js" },
		   { -language=>"JAVASCRIPT", -src=>($main::remote_user) ? "/globals.cgi" : "" },
		   { -language=>"JAVASCRIPT", -src=>(! $main::remote_user) ? "/javascript/login.js" : "" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/helper.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/loading.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/ui.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/list.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/table.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/menu.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/confirm.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/lplt-paginator.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/prototype.js" },
		   { -language=>"JAVASCRIPT", -src=>"/javascript/natsort.js" },
		   ];
		   
		 $css = [
			"/yui/reset/reset-min.css",
			"/yui/assets/skins/yaffas/accordionview.css",
			"/yui/assets/skins/yaffas/tabview.css",
			"/yui/assets/skins/yaffas/container.css",
			"/yui/assets/skins/yaffas/button.css",
			"/yui/assets/skins/yaffas/paginator.css",
			"/yui/assets/skins/yaffas/datatable.css",
			"/yui/assets/skins/yaffas/menu.css",
			"/yui/assets/skins/yaffas/resize.css",
			"/yui/assets/skins/yaffas/treeview.css",
			"/yui/assets/skins/yaffas/layout.css",
			"/yui/base/base-min.css",
			"/index.css",
			];

	my $html_start = $cgi->start_html(
						   {
						   -title=>$main::gconfig{product} eq "usermin" ?
						   "yaffas user interface" : "yaffas administration interface",

						   -dtd=>["-//W3C//DTD XHTML 1.0 Strict//EN",
						   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"],

						   -style=>{
						   src=>$css
						   },

						   -script=>$scripts,

						   -head=>[
							   $cgi->meta(
								   {
									   -http_equiv => 'X-UA-Compatible',
									   -content    => 'IE=9',
								   }
							   ),
							   $cgi->meta(
								   {
									   -http_equiv => 'Content-Type',
									   -content    => 'text/html',
								   }
							   ),

						   ],
						   -class=>"yui-skin-yaffas"
						   }
						  );

#	my $dtd = '<!DOCTYPE html>';
#	$html_start    =~  s{<!DOCTYPE.*?>}{$dtd}s;
	print $html_start;

	if (defined($ENV{REMOTE_USER}) and $ENV{REMOTE_USER} ne "") {
		print '
			<iframe id="yui-history-iframe" src="/assets/blank.html"></iframe>
			<input id="yui-history-field" type="hidden">
		';

		my @modules = &get_available_module_infos();

		my %catnames;
		read_file("$main::config_directory/webmin.catnames", \%catnames);
		my @cats;
		my %cats;
		foreach my $m (@modules) {
			my $c = $m->{'category'};
			next if ($cats{$c});
			if (defined($catnames{$c})) {
				$cats{$c} = $catnames{$c};
			} elsif ($main::text{"category_$c"}) {
				$cats{$c} = $main::text{"category_$c"};
			} else {
				my %mtext = load_language($m->{'dir'});
				if ($mtext{"category_$c"}) {
					$cats{$c} = $mtext{"category_$c"};
				} else {
					$c = $m->{'category'} = "";
					$cats{$c} = $main::text{"category_$c"};
				}
			}
		}

		if (-r "$main::config_directory/categorys") {
			my $file = Yaffas::File->new("$main::config_directory/categorys");
			foreach ($file->get_content()) {
				chomp $_;
				push @cats, $_ if (defined($cats{$_}));
			}
		} else {
			@cats = sort { $b cmp $a } keys %cats;
		}

		my @hidden_modules = qw();

		my $mfile = Yaffas::File->new(Yaffas::Constant::DIR->{webmin_config}."/hidden_modules");
		@hidden_modules = $mfile->get_content() if (defined($mfile));

		my %smodules;

		my %description;

		foreach my $m (@modules) {
			next if grep { $_ eq $m->{dir} } @hidden_modules;

			push @{$smodules{$m->{category}}}, $m->{dir};
			$description{$m->{dir}} = $m->{desc};
		}

		foreach my $cat (keys %smodules) {
			## sort modules in each category alphabeticly
			@{$smodules{$cat}} = sort { $description{$a} cmp $description{$b} } @{$smodules{$cat}}
		}

		unless(defined($main::module_name)) {
			if ($ENV{SCRIPT_NAME} =~ /([^\/]+)\//) {
				$main::module_name = $1;
			}
		}

		if (!defined(%main::module_info) && !defined($main::in{'cat'})) {
			$main::in{'cat'} = $cats[0];
		}

		if (defined($main::in{'cat'}) && !$cats{$main::in{'cat'}}) {
			$main::in{'cat'} = $cats[0];
		}

		if (defined($main::module_info{'category'})) {
			$main::in{'cat'} = $main::module_info{'category'};
		}

		# Container Navigation
		print $cgi->comment("Container Navigation");
		print $cgi->start_ul( {-id=>"navigation"} );

		foreach my $c (@cats) {
				if (defined $smodules{$c} and scalar @{$smodules{$c}}) {
					print $cgi->li({ },
									$cgi->h3($cats{$c}),

									$cgi->div(map {
									my $m = $_;
									my $ret;
										$cgi->div($cgi->a( {
														   -onclick=>"javascript:Yaffas.ui.openPage('".$m."')",
														   -id=>"menuitem-$m"
														   }, $description{$m}).(($_ eq @{$smodules{$c}}[-1] ) ? "" : $cgi->hr()))

									} @{$smodules{$c}}),

					);
				}
		}

		print $cgi->end_ul();
	}

		print $cgi->div({-id => "tabbar"}, "");
		print $cgi->div({-id => "topbar"},$cgi->div({-id => "uimenubar"}, ""), $cgi->div({-id=>"topbar-background"}, ""), $cgi->div({-id=>"topbarlogo"}, ""));
		print $cgi->div({-id => "bottombar"}, $cgi->div({-id=>"logoyaffas-long"}, ""), $cgi->div( {-id=>"notification"}, $notification));

		print $cgi->div( {-id=>"error_dlg"}, "");
		print $cgi->div( {-id=>"confirmationdlg"}, "");
		print $cgi->div( {-id=>"response"}, "");
		print $cgi->div( {-id=>"wait"}, "");

		print $cgi->div( {-id=>"content"}, "");
}

sub theme_footer() {
	my $module = shift;

	if ($module ne "login") {
		return;
	}

	print "</body></html>\n";
	warningsToBrowser(1);
}
