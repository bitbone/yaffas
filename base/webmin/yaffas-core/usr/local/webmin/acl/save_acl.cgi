#!/usr/local/bin/perl
# save_acl.cgi
# Save access control options for some module

require './acl-lib.pl';
&ReadParse();
if ($in{'_acl_group'}) {
	$access{'groups'} || &error($text{'acl_egroup'});
	$who = $in{'_acl_group'};
	}
else {
	foreach $u (&list_users()) {
		$me = $u if ($u->{'name'} eq $base_remote_user);
		}
	@mcan = $access{'mode'} == 1 ? @{$me->{'modules'}} :
		$access{'mode'} == 2 ? split(/\s+/, $access{'mods'}) :
				       ( &list_modules(), "" );
	&indexof($in{'_acl_mod'}, @mcan) >= 0 || &error($text{'acl_emod'});
	&can_edit_user($in{'_acl_user'}) || &error($text{'acl_euser'});
	$who = $in{'_acl_user'};
	}

$aclfile = $in{'_acl_group'} ? "$config_directory/$in{'_acl_mod'}/$who.gacl"
			     : "$config_directory/$in{'_acl_mod'}/$who.acl";
if ($in{'reset'}) {
	# Just remove the .acl file
	&unlink_logged($aclfile);
	$in{'moddesc'} = $minfo{'desc'};
	&webmin_log("reset", undef, $who, \%in);
	}
else {
	# Validate and store ACL settings
	&error_setup($text{'acl_err'});
	$maccess{'noconfig'} = $in{'noconfig'};
	if ($in{'rbac'}) {
		# RBAC overrides everything
		$maccess{'rbac'} = 1;
		}
	elsif (-r "../$in{'_acl_mod'}/acl_security.pl") {
		# Use user inputs
		$maccess{'rbac'} = 0 if (defined($in{'rbac'}));
		&foreign_require($in{'_acl_mod'}, "acl_security.pl");
		if ($in{'_acl_mod'}) {
			local $pkg = $in{'_acl_mod'};
			$pkg =~ s/[^A-Za-z0-9]/_/g;
			eval "\%${pkg}::in = \%in";
			}
		else {
			%global::in = %in;
			}
		&foreign_call($in{'_acl_mod'}, "acl_security_save",
			      \%maccess, \%in);
		}
	&lock_file($aclfile);
	&write_file($aclfile, \%maccess);
	chmod(0640, $aclfile);
	&unlock_file($aclfile);
	%minfo = $in{'_acl_mod'} ? &get_module_info($in{'_acl_mod'})
				 : ( 'desc' => $text{'index_global'} );

	if ($in{'_acl_group'}) {
		# Recursively update the ACL for all member users and groups
		@ulist = &list_users();
		@glist = &list_groups();
		($group) = grep { $_->{'name'} eq $in{'_acl_group'} } @glist;
		&set_acl_files(\@ulist, \@glist, $in{'_acl_mod'},
			       $group->{'members'}, \%maccess);
		}

	$in{'moddesc'} = $minfo{'desc'};
	&webmin_log("acl", undef, $who, \%in);
	}
if ($config{'display'}) {
	if ($in{'_acl_group'}) {
		&redirect("edit_group.cgi?group=$in{'_acl_group'}");
		}
	else {
		&redirect("edit_user.cgi?user=$in{'_acl_user'}&readwrite=1");
		}
	}
else {
	&redirect("");
	}


