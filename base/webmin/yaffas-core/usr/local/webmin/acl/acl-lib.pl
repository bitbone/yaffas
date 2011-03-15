# acl-lib.pl
# Library for editing webmin users, passwords and access rights

do '../web-lib.pl';
&init_config();
do '../ui-lib.pl';
%access = &get_module_acl();
$access{'switch'} = 0 if (&is_readonly_mode());

# list_users()
# Returns a list of hashes containing user details
sub list_users
{
local(%miniserv, $_, @rv, %acl, %logout);
&read_acl(undef, \%acl);
&get_miniserv_config(\%miniserv);
foreach my $a (split(/\s+/, $miniserv{'logouttimes'})) {
	if ($a =~ /^([^=]+)=(\S+)$/) {
		$logout{$1} = $2;
		}
	}
open(PWFILE, $miniserv{'userfile'});
while(<PWFILE>) {
	s/\r|\n//g;
	local @user = split(/:/, $_);
	if (@user) {
		local(%user);
		$user{'name'} = $user[0];
		$user{'pass'} = $user[1];
		$user{'sync'} = $user[2];
		$user{'cert'} = $user[3];
		if ($user[4] =~ /^(allow|deny)\s+(.*)/) {
			$user{$1} = $2;
			}
		if ($user[5] =~ /days\s+(\S+)/) {
			$user{'days'} = $1;
			}
		if ($user[5] =~ /hours\s+(\d+\.\d+)-(\d+\.\d+)/) {
			$user{'hoursfrom'} = $1;
			$user{'hoursto'} = $2;
			}
		$user{'modules'} = $acl{$user[0]};
		$user{'lang'} = $gconfig{"lang_$user[0]"};
		$user{'notabs'} = $gconfig{"notabs_$user[0]"};
		$user{'skill'} = $gconfig{"skill_$user[0]"};
		$user{'risk'} = $gconfig{"risk_$user[0]"};
		$user{'rbacdeny'} = $gconfig{"rbacdeny_$user[0]"};
		$user{'theme'} = $gconfig{"theme_$user[0]"};
		$user{'readonly'} = $gconfig{"readonly_$user[0]"};
		$user{'ownmods'} = [ split(/\s+/,
					   $gconfig{"ownmods_$user[0]"}) ];
		$user{'logouttime'} = $logout{$user[0]};
		push(@rv, \%user);
		}
	}
close(PWFILE);
return @rv;
}

# list_groups()
# Returns a list of hashes, one per group.
# Group membership is stored in /etc/webmin/webmin.groups, and other attributes
# in the config file.
sub list_groups
{
local @rv;
open(GROUPS, "$config_directory/webmin.groups");
while(<GROUPS>) {
	s/\r|\n//g;
	local @g = split(/:/, $_);
	local $group = { 'name' => $g[0],
			 'members' => [ split(/\s+/, $g[1]) ],
			 'modules' => [ split(/\s+/, $g[2]) ],
			 'desc' => $g[3],
			 'ownmods' => [ split(/\s+/, $g[4]) ] };
	push(@rv, $group);
	}
close(GROUPS);
return @rv;
}

# list_modules()
# Returns a list of the dirs of all modules available on this system
sub list_modules
{
return map { $_->{'dir'} } &list_module_infos();
}

# list_module_infos()
# Returns a list of the details of all  modules available on this system
sub list_module_infos
{
local @mods = grep { &check_os_support($_) } &get_all_module_infos();
return sort { $a->{'desc'} cmp $b->{'desc'} } @mods;
}

# create_user(&details, clone)
sub create_user
{
local(%user, %miniserv, @mods);
%user = %{$_[0]};

&lock_file($ENV{'MINISERV_CONFIG'});
&get_miniserv_config(\%miniserv);
if ($user{'theme'}) {
	$miniserv{"preroot_".$user{'name'}} = $user{'theme'};
	}
elsif (defined($user{'theme'})) {
	$miniserv{"preroot_".$user{'name'}} = "";
	}
if (defined($user{'logouttime'})) {
	local @logout = split(/\s+/, $miniserv{'logouttimes'});
	push(@logout, "$user{'name'}=$user{'logouttime'}");
	$miniserv{'logouttimes'} = join(" ", @logout);
	}
&put_miniserv_config(\%miniserv);
&unlock_file($ENV{'MINISERV_CONFIG'});

local @times;
push(@times, "days", $user{'days'}) if ($user{'days'} ne '');
push(@times, "hours", $user{'hoursfrom'}."-".$user{'hoursto'})
	if ($user{'hoursfrom'});
&lock_file($miniserv{'userfile'});
&open_tempfile(PWFILE, ">>$miniserv{'userfile'}");
&print_tempfile(PWFILE,
	"$user{'name'}:$user{'pass'}:$user{'sync'}:$user{'cert'}:",
	($user{'allow'} ? "allow $user{'allow'}" :
	 $user{'deny'} ? "deny $user{'deny'}" : ""),":",
	join(" ", @times),
	"\n");
&close_tempfile(PWFILE);
&unlock_file($miniserv{'userfile'});

&lock_file(&acl_filename());
@mods = &list_modules();
&open_tempfile(ACL, ">>".&acl_filename());
&print_tempfile(ACL, &acl_line(\%user, \@mods));
&close_tempfile(ACL);
&unlock_file(&acl_filename());

delete($gconfig{"lang_".$user{'name'}});
$gconfig{"lang_".$user{'name'}} = $user{'lang'} if ($user{'lang'});
delete($gconfig{"notabs_".$user{'name'}});
$gconfig{"notabs_".$user{'name'}} = $user{'notabs'} if ($user{'notabs'});
delete($gconfig{"skill_".$user{'name'}});
$gconfig{"skill_".$user{'name'}} = $user{'skill'} if ($user{'skill'});
delete($gconfig{"risk_".$user{'name'}});
$gconfig{"risk_".$user{'name'}} = $user{'risk'} if ($user{'risk'});
delete($gconfig{"rbacdeny_".$user{'name'}});
$gconfig{"rbacdeny_".$user{'name'}} = $user{'rbacdeny'} if ($user{'rbacdeny'});
delete($gconfig{"ownmods_".$user{'name'}});
$gconfig{"ownmods_".$user{'name'}} = join(" ", @{$user{'ownmods'}})
	if (@{$user{'ownmods'}});
delete($gconfig{"theme_".$user{'name'}});
$gconfig{"theme_".$user{'name'}} = $user{'theme'} if (defined($user{'theme'}));
$gconfig{"readonly_".$user{'name'}} = $user{'readonly'}
	if (defined($user{'readonly'}));
&write_file("$config_directory/config", \%gconfig);

if ($_[1]) {
	foreach $m ("", @mods) {
		local $file = "$config_directory/$m/$_[1].acl";
		local $dest = "$config_directory/$m/$user{'name'}.acl";
		if (-r $file) {
			local %macl;
			&read_file($file, \%macl);
			&write_file($dest, \%macl);
			}
		}
	}
}

# modify_user(old-name, &details)
sub modify_user
{
local(%user, %miniserv, @pwfile, @acl, @mods, $_, $m);
%user = %{$_[1]};

&lock_file($ENV{'MINISERV_CONFIG'});
&get_miniserv_config(\%miniserv);
delete($miniserv{"preroot_".$_[0]});
if ($user{'theme'}) {
	$miniserv{"preroot_".$user{'name'}} = $user{'theme'};
	}
elsif (defined($user{'theme'})) {
	$miniserv{"preroot_".$user{'name'}} = "";
	}
local @logout = split(/\s+/, $miniserv{'logouttimes'});
@logout = grep { $_ !~ /^$_[0]=/ } @logout;
if (defined($user{'logouttime'})) {
	push(@logout, "$user{'name'}=$user{'logouttime'}");
	}
$miniserv{'logouttimes'} = join(" ", @logout);
&put_miniserv_config(\%miniserv);
&unlock_file($ENV{'MINISERV_CONFIG'});

local @times;
push(@times, "days", $user{'days'}) if ($user{'days'} ne '');
push(@times, "hours", $user{'hoursfrom'}."-".$user{'hoursto'})
	if ($user{'hoursfrom'});
&lock_file($miniserv{'userfile'});
open(PWFILE, $miniserv{'userfile'});
@pwfile = <PWFILE>;
close(PWFILE);
&open_tempfile(PWFILE, ">$miniserv{'userfile'}");
foreach (@pwfile) {
	if (/^([^:]+):/ && $1 eq $_[0]) {
		&print_tempfile(PWFILE,
			"$user{'name'}:$user{'pass'}:",
			"$user{'sync'}:$user{'cert'}:",
			($user{'allow'} ? "allow $user{'allow'}" :
			 $user{'deny'} ? "deny $user{'deny'}" : ""),":",
			join(" ", @times),"\n");
		}
	else {
		&print_tempfile(PWFILE, $_);
		}
	}
&close_tempfile(PWFILE);
&unlock_file($miniserv{'userfile'});

&lock_file(&acl_filename());
@mods = &list_modules();
open(ACL, &acl_filename());
@acl = <ACL>;
close(ACL);
&open_tempfile(ACL, ">".&acl_filename());
foreach (@acl) {
	if (/^(\S+):/ && $1 eq $_[0]) {
		&print_tempfile(ACL, &acl_line($_[1], \@mods));
		}
	else {
		&print_tempfile(ACL, $_);
		}
	}
&close_tempfile(ACL);
&unlock_file(&acl_filename());

delete($gconfig{"lang_".$_[0]});
$gconfig{"lang_".$user{'name'}} = $user{'lang'} if ($user{'lang'});
delete($gconfig{"notabs_".$_[0]});
$gconfig{"notabs_".$user{'name'}} = $user{'notabs'} if ($user{'notabs'});
delete($gconfig{"skill_".$_[0]});
$gconfig{"skill_".$user{'name'}} = $user{'skill'} if ($user{'skill'});
delete($gconfig{"risk_".$_[0]});
$gconfig{"risk_".$user{'name'}} = $user{'risk'} if ($user{'risk'});
delete($gconfig{"rbacdeny_".$_[0]});
$gconfig{"rbacdeny_".$user{'name'}} = $user{'rbacdeny'} if ($user{'rbacdeny'});
delete($gconfig{"ownmods_".$_[0]});
$gconfig{"ownmods_".$user{'name'}} = join(" ", @{$user{'ownmods'}})
	if (@{$user{'ownmods'}});
delete($gconfig{"theme_".$_[0]});
$gconfig{"theme_".$user{'name'}} = $user{'theme'} if (defined($user{'theme'}));
delete($gconfig{"readonly_".$_[0]});
$gconfig{"readonly_".$user{'name'}} = $user{'readonly'}
	if (defined($user{'readonly'}));
&write_file("$config_directory/config", \%gconfig);

if ($_[0] ne $user{'name'}) {
	# Rename all .acl files if user renamed
	foreach $m (@mods, "") {
		local $file = "$config_directory/$m/$_[0].acl";
		if (-r $file) {
			&rename_file($file, "$config_directory/$m/$user{'name'}.acl");
			}
		}
	local $file = "$config_directory/$_[0].acl";
	if (-r $file) {
		&rename_file($file, "$config_directory/$user{'name'}.acl");
		}
	}

if ($miniserv{'session'} && $_[0] ne $user{'name'}) {
	# Modify all sessions for the renamed user
	&rename_session_user(\&miniserv, $_[0], $user{'name'});
	}
}

# delete_user(name)
# Delete some user from the ACL and password files
sub delete_user
{
local($_, @pwfile, @acl, %miniserv);

&lock_file($ENV{'MINISERV_CONFIG'});
&get_miniserv_config(\%miniserv);
delete($miniserv{"preroot_".$_[0]});
local @logout = split(/\s+/, $miniserv{'logouttimes'});
@logout = grep { $_ !~ /^$_[0]=/ } @logout;
$miniserv{'logouttimes'} = join(" ", @logout);
&put_miniserv_config(\%miniserv);
&unlock_file($ENV{'MINISERV_CONFIG'});

&lock_file($miniserv{'userfile'});
open(PWFILE, $miniserv{'userfile'});
@pwfile = <PWFILE>;
close(PWFILE);
&open_tempfile(PWFILE, ">$miniserv{'userfile'}");
foreach (@pwfile) {
	if (!/^([^:]+):/ || $1 ne $_[0]) {
		&print_tempfile(PWFILE, $_);
		}
	}
&close_tempfile(PWFILE);
&unlock_file($miniserv{'userfile'});

&lock_file(&acl_filename());
open(ACL, &acl_filename());
@acl = <ACL>;
close(ACL);
&open_tempfile(ACL, ">".&acl_filename());
foreach (@acl) {
	if (!/^([^:]+):/ || $1 ne $_[0]) {
		&print_tempfile(ACL, $_);
		}
	}
&close_tempfile(ACL);
&unlock_file(&acl_filename());

delete($gconfig{"lang_".$_[0]});
delete($gconfig{"notabs_".$_[0]});
delete($gconfig{"skill_".$_[0]});
delete($gconfig{"risk_".$_[0]});
delete($gconfig{"ownmods_".$_[0]});
delete($gconfig{"theme_".$_[0]});
delete($gconfig{"readonly_".$_[0]});
&write_file("$config_directory/config", \%gconfig);

# Delete all module .acl files
&unlink_file(map { "$config_directory/$_/$_[0].acl" } &list_modules());
&unlink_file("$config_directory/$_[0].acl");

if ($miniserv{'session'}) {
	# Delete all sessions for the deleted user
	&delete_session_user(\%miniserv, $_[0]);
	}
}

# create_group(&group, [clone])
# Add a new webmin group
sub create_group
{
&lock_file("$config_directory/webmin.groups");
open(GROUP, ">>$config_directory/webmin.groups");
print GROUP &group_line($_[0]),"\n";
close(GROUP);
&unlock_file("$config_directory/webmin.groups");

if ($_[1]) {
	foreach $m ("", &list_modules()) {
		local $file = "$config_directory/$m/$_[1].gacl";
		local $dest = "$config_directory/$m/$_[0]->{'name'}.gacl";
		if (-r $file) {
			local %macl;
			&read_file($file, \%macl);
			&write_file($dest, \%macl);
			}
		}
	}
}

# modify_group(name, &group)
# Update a webmin group
sub modify_group
{
&lock_file("$config_directory/webmin.groups");
local $lref = &read_file_lines("$config_directory/webmin.groups");
foreach $l (@$lref) {
	if ($l =~ /^([^:]+):/ && $1 eq $_[0]) {
		$l = &group_line($_[1]);
		}
	}
&flush_file_lines();
&unlock_file("$config_directory/webmin.groups");

if ($_[0] ne $_[1]->{'name'}) {
	# Rename all .gacl files if group renamed
	foreach $m (@{$_[1]->{'modules'}}, "") {
		local $file = "$config_directory/$m/$_[0].gacl";
		if (-r $file) {
			&rename_file($file,
				     "$config_directory/$m/$_[1]->{'name'}.gacl");
			}
		}
	}
}

# delete_group(name)
# Delete a webmin group
sub delete_group
{
&lock_file("$config_directory/webmin.groups");
local $lref = &read_file_lines("$config_directory/webmin.groups");
@$lref = grep { !/^([^:]+):/ || $1 ne $_[0] } @$lref;
&flush_file_lines();
&unlock_file("$config_directory/webmin.groups");
&unlink_file(map { "$config_directory/$_/$_[0].gacl" } &list_modules());
}

# group_line(&group)
sub group_line
{
return join(":", $_[0]->{'name'},
		 join(" ", @{$_[0]->{'members'}}),
		 join(" ", @{$_[0]->{'modules'}}),
		 $_[0]->{'desc'},
		 join(" ", @{$_[0]->{'ownmods'}}) );
}

# acl_line(&user, &allmodules)
# Internal function to generate an ACL file line
sub acl_line
{
local(%user);
%user = %{$_[0]};
return "$user{'name'}: ".join(' ', @{$user{'modules'}})."\n";
}

# can_edit_user(user, [&groups])
sub can_edit_user
{
return 1 if ($access{'users'} eq '*');
if ($access{'users'} eq '~') {
	return $base_remote_user eq $_[0];
	}
local $u;
local $glist = $_[1] ? $_[1] : [ &list_groups() ];
foreach $u (split(/\s+/, $access{'users'})) {
	if ($u =~ /^_(\S+)$/) {
		foreach $g (@$glist) {
			return 1 if ($g->{'name'} eq $1 &&
				     &indexof($_[0], @{$g->{'members'}}) >= 0);
			}
		}
	else {
		return 1 if ($u eq $_[0]);
		}
	}
return 0;
}

# open_session_db(\%miniserv)
sub open_session_db
{
local $sfile = $_[0]->{'sessiondb'} ? $_[0]->{'sessiondb'} :
	       $_[0]->{'pidfile'} =~ /^(.*)\/[^\/]+$/ ? "$1/sessiondb"
						      : return;
eval "use SDBM_File";
dbmopen(%sessiondb, $sfile, 0700);
eval { $sessiondb{'1111111111'} = 'foo bar' };
if ($@) {
	dbmclose(%sessiondb);
	eval "use NDBM_File";
	dbmopen(%sessiondb, $sfile, 0700);
	}
else {
	delete($sessiondb{'1111111111'});
	}
}

# delete_session_id(\%miniserv, id)
# Deletes one session from the database
sub delete_session_id
{
return 1 if (&is_readonly_mode());
&open_session_db($_[0]);
local $ex = exists($sessiondb{$_[1]});
delete($sessiondb{$_[1]});
dbmclose(%sessiondb);
return $ex;
}

# delete_session_user(\%miniserv, user)
# Deletes all sessions for some user
sub delete_session_user
{
return 1 if (&is_readonly_mode());
&open_session_db($_[0]);
foreach my $s (keys %sessiondb) {
	local ($u,$t) = split(/\s+/, $sessiondb{$s});
	if ($u eq $_[1]) {
		delete($sessiondb{$s});
		}
	}
dbmclose(%sessiondb);
}

# rename_session_user(\%miniserv, olduser, newuser)
# Changes the username in all sessions for some user
sub rename_session_user
{
return 1 if (&is_readonly_mode());
&open_session_db(\%miniserv);
foreach my $s (keys %sessiondb) {
	local ($u,$t) = split(/\s+/, $sessiondb{$s});
	if ($u eq $_[1]) {
		$sessiondb{$s} = "$_[2] $t";
		}
	}
dbmclose(%sessiondb);
}

# update_members(&allusers, &allgroups, &modules, &members)
# Update the members users and groups of some group
sub update_members
{
local $m;
foreach $m (@{$_[3]}) {
	if ($m !~ /^\@(.*)$/) {
		# Member is a user
		local ($u) = grep { $_->{'name'} eq $m } @{$_[0]};
		if ($u) {
			$u->{'modules'} = [ @{$_[2]}, @{$u->{'ownmods'}} ];
			&modify_user($u->{'name'}, $u);
			}
		}
	else {
		# Member is a group
		local $gname = substr($m, 1);
		local ($g) = grep { $_->{'name'} eq $gname } @{$_[1]};
		if ($g) {
			$g->{'modules'} = [ @{$_[2]}, @{$g->{'ownmods'}} ];
			&modify_group($g->{'name'}, $g);
			&update_members($_[0], $_[1], $g->{'modules'},
					$g->{'members'});
			}
		}
	}
}

# copy_acl_files(from, to, &modules)
# Copy all .acl files from some user to another in a list of modules
sub copy_acl_files
{
local $m;
foreach $m (@{$_[2]}) {
	&unlink_file("$config_directory/$m/$_[1].acl");
	local %acl;
	if (&read_file("$config_directory/$m/$_[0].acl", \%acl)) {
		&write_file("$config_directory/$m/$_[1].acl", \%acl);
		}
	}
}

# copy_group_acl_files(from, to, &modules)
# Copy all .acl files from some group to another in a list of modules
sub copy_group_acl_files
{
local $m;
foreach $m (@{$_[2]}) {
	&unlink_file("$config_directory/$m/$_[1].gacl");
	local %acl;
	if (&read_file("$config_directory/$m/$_[0].gacl", \%acl)) {
		&write_file("$config_directory/$m/$_[1].gacl", \%acl);
		}
	}
}
# copy_group_user_acl_files(from, to, &modules)
# Copy all .acl files from some group to a user in a list of modules
sub copy_group_user_acl_files
{
local $m;
foreach $m (@{$_[2]}) {
	&unlink_file("$config_directory/$m/$_[1].acl");
	local %acl;
	if (&read_file("$config_directory/$m/$_[0].gacl", \%acl)) {
		&write_file("$config_directory/$m/$_[1].acl", \%acl);
		}
	}
}

# set_acl_files(&allusers, &allgroups, module, &members, &access)
# Recursively update the ACL for all sub-users and groups of a group
sub set_acl_files
{
local $m;
foreach $m (@{$_[3]}) {
	if ($m !~ /^\@(.*)$/) {
		# Member is a user
		local ($u) = grep { $_->{'name'} eq $m } @{$_[0]};
		if ($u) {
			local $aclfile =
				"$config_directory/$_[2]/$u->{'name'}.acl";
			&lock_file($aclfile);
			&write_file($aclfile, $_[4]);
			chmod(0640, $aclfile);
			&unlock_file($aclfile);
			}
		}
	else {
		# Member is a group
		local $gname = substr($m, 1);
		local ($g) = grep { $_->{'name'} eq $gname } @{$_[1]};
		if ($g) {
			local $aclfile =
				"$config_directory/$_[2]/$g->{'name'}.gacl";
			&lock_file($aclfile);
			&write_file($aclfile, $_[4]);
			chmod(0640, $aclfile);
			&unlock_file($aclfile);
			&set_acl_files($_[0], $_[1], $_[2], $g->{'members'}, $_[4]);
			}
		}
	}
}

# get_ssleay()
# Returns the path to OpenSSL or equivalent
sub get_ssleay
{
if (&has_command($config{'ssleay'})) {
	return &has_command($config{'ssleay'});
	}
elsif (&has_command("openssl")) {
	return &has_command("openssl");
	}
elsif (&has_command("ssleay")) {
	return &has_command("ssleay");
	}
else {
	return undef;
	}
}

# encrypt_password(password, [salt])
sub encrypt_password
{
local ($pass, $salt) = @_;
if ($gconfig{'md5pass'}) {
	$salt ||= substr(time(), -8);
	return crypt($pass, '$1$'.$salt);
	}
else {
	&seed_random();
	$salt ||= chr(int(rand(26))+65).chr(int(rand(26))+65);
	return &unix_crypt($pass, $salt);
	}
}

# get_unixauth(\%miniserv)
# Returns a list of Unix users/groups/all and the Webmin user that they
# authenticate as
sub get_unixauth
{
local @rv;
local @ua = split(/\s+/, $_[0]->{'unixauth'});
foreach my $ua (@ua) {
	if ($ua =~ /^(\S+)=(\S+)$/) {
		push(@rv, [ $1, $2 ]);
		}
	else {
		push(@rv, [ "*", $ua ]);
		}
	}
return @rv;
}

# save_unixauth(\%miniserv, &authlist)
# Updates %miniserv with the given Unix auth list
sub save_unixauth
{
local @ua;
foreach my $ua (@{$_[1]}) {
	if ($ua->[0] ne "*") {
		push(@ua, "$ua->[0]=$ua->[1]");
		}
	else {
		push(@ua, $ua->[1]);
		}
	}
$_[0]->{'unixauth'} = join(" ", @ua);
}

# delete_from_groups(user|@group)
# Removes the specified user from all groups
sub delete_from_groups
{
local ($user) = @_;
foreach my $g (&list_groups()) {
	local @mems = @{$g->{'members'}};
	local $i = &indexof($user, @mems);
	if ($i >= 0) {
		splice(@mems, $i, 1);
		$g->{'members'} = \@mems;
		&modify_group($g->{'name'}, $g);
		}
	}
}

1;

