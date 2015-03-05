#!/usr/bin/perl -w
package Yaffas::Fax;
use strict;

use Yaffas::File;
use Yaffas::File::Config;
use Yaffas::Constant;
use Yaffas::Exception;
use Yaffas::Postgres;
use Yaffas::Check;
use Error qw(:try);
## prototypes ##
sub get_ctrl_mode($);
sub get_incoming_msn();
sub get_display_msn($);
sub get_user_msn($);
sub get_group_msn($);
sub get_all_group_msn();
sub get_hf_filetype($;$);
sub update_incoming_faxcapi();
sub update_incoming_faxcapi_section ($$);
sub exchangeFaxSectionLines ($$$$);
sub mod_p2p_capi_conf($$);
sub get_all_ctrl_msns($);
sub check_existing_conf_entry($);
sub add_msn($$$$;$);


# FIXME alle subs: eingabetypen pruefen!!!

=head1 NAME

Yaffas::Fax - Fax Functions

=head1 SYNOPSIS

use Yaffas::Fax

=head1 DESCRIPTION

Yaffas::Fax provides functions for yaffas/FAX

=head1 FUNCTIONS

=over


=item get_display_msn ( CTRL )

Returns array of MSNs configured on given CTRL.
Checks if ctrl is configured as separat or togther and
returns only msns, diplayed to user (virtual msns).
Not all msns really in the conf files.

This function is useless for eicon. No b channels are configured.

=cut

sub get_display_msn($) 
{
	my $ctrl = shift;
	my $faxtype = Yaffas::Check::faxtype();
	my @allmsns = ();

	if (check_existing_conf_entry($ctrl))
	{
		my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
		if (defined($dbh))
		{
			if ($faxtype eq "CAPI")
			{
				my $mode = get_ctrl_mode($ctrl);
				my $sqlq = "select msn, ctrl, channel from msn_avm where ctrl = '$ctrl'";
				my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
				Yaffas::Postgres::pg_disconnect($dbh);

				foreach my $i (@tmp)
				{
					if ($#$i == 2 && $$i[1] == $ctrl)
					{
						next if ($$i[2] == 2 && $mode eq "together");
						push @allmsns, "$$i[0]_$$i[1]_$$i[2]";
					}
				}
			}
			else
			{
				my $sqlq = "select msn, ctrl from msn_eicon where ctrl = '$ctrl'";
				my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
				Yaffas::Postgres::pg_disconnect($dbh);

				foreach my $i (@tmp)
				{
					if ($#$i == 1 && $$i[1] == $ctrl)
					{
						push @allmsns, "$$i[0]_$$i[1]";
					}
				}
			}
		}
	}

	return undef unless @allmsns;
    	return @allmsns;
}


=item drop_table_content( TABLE )

drops complete content of given TABLE

=cut

sub drop_table_content($)
{
	my $table = shift;
	my $ret = undef;
	
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
	if (defined($dbh))
	{
		my $sqlq = "delete from $table";
		$ret = Yaffas::Postgres::del_entry($dbh, $sqlq);

		Yaffas::Postgres::pg_disconnect($dbh);
	}

	return (defined($ret)) ? $ret : undef;
}

=item add_msn( UG TYPE MSN CTRL BC )

Add MSN to postgres

=cut

sub add_msn($$$$;$)
{
	my $ug = shift;
	my $type = shift;
	my $msn = shift;
	my $ctrl = shift;
	my $bc = shift;

	my $fax_type = Yaffas::Check::faxtype();
	my $ret = undef;
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

	if (defined($dbh))
	{
		# get id of ug
		my $sqlq = "select id from ug where ug = '$ug' and type = '$type'";
		my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
		my $id = $tmp[0][0];

		unless (defined($id))
		{
			# no user - insert user to db
			$sqlq = "insert into ug (ug, type) values ('$ug', '$type')";
			if (scalar (Yaffas::Postgres::add_entry($dbh, $sqlq) ) )
			{
				# get id of entry.
				$sqlq = "select id from ug where ug = '$ug' and type = '$type'";
				my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
				$id = $tmp[0][0];
			}
		}

		if (defined($id))
		{
			# insert msn for this id
			if ($fax_type eq "CAPI")
			{
				unless (defined($bc))
				{
					Yaffas::Postgres::pg_disconnect($dbh);
					return undef;
				}
				$sqlq = "insert into msn_avm (id, msn, ctrl, channel) values ($id, '$msn', $ctrl, $bc)";
			}
			else
			{
				$sqlq = "insert into msn_eicon (id, msn, ctrl) values ($id, '$msn', $ctrl)";
			}
			$ret = Yaffas::Postgres::add_entry($dbh, $sqlq);
		}

		Yaffas::Postgres::pg_disconnect($dbh);
	}

	defined ($ret) ? return $ret : return undef;
}


=item check_existing_conf_entry( CTRLNUMBER )

Checks if an entry in config.faxcapi exists for the given controllernumber.
For Eicon cards it checks if the configuration file exists
Returns 1 on success.

=cut

sub check_existing_conf_entry($)
{
	my $faxtype = Yaffas::Check::faxtype();
	my $ctrlnr = shift;
	throw Yaffas::Exception("err_only_nr") if ( $ctrlnr !~ m/^\d+$/ );
	if ($faxtype eq "CAPI") {
		my $cffc_f = Yaffas::Constant::FILE->{config_faxcapi};
		my $cffc = Yaffas::File->new($cffc_f) or throw Yaffas::Exception("err_file_read", $cffc_f);
		return defined ($cffc->search_line(qr!^\s*#\s*begin\s+card\s+$ctrlnr.*$!));
	} else {
		#get 1st modem of controller
		$ctrlnr = ($ctrlnr * 2) - 1;
		my $modem_file = Yaffas::Constant::FILE->{config_eiconfax}.(sprintf("%02d",$ctrlnr));
		if (-f $modem_file) {
			return 1;
		} else {
			return 0;
		}
	}
}

=item get_ctrl_mode( CTRL )

gets controller mode for given ctrl

=cut

sub get_ctrl_mode($)
{
	my $ctrl = shift;
	my $conff = Yaffas::Constant::DIR->{bkconfig} . "fax/faxconf/ctrl.mode";

	my $conf = Yaffas::File::Config->new($conff,
										 {
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => '\s*=\s*',
										 }
									);
	my $chash = $conf->get_cfg_values();
	my $mode = $chash->{$ctrl};
	# if no mode was found, return 'separat' for backward compatibility
	return (defined($mode)) ? $mode : 'separat';
}

=item get_incoming_msn ()

It returns array of MSNs. The MSNs are from the DB.

=cut

sub get_incoming_msn()
{
	my @msns = Yaffas::FaxDB::msn({type => "user"});
	my @groupmsns = Yaffas::FaxDB::msn({type => "group"});
	push @msns, @groupmsns;

	return @msns;
}

=item update_incoming_faxcapi ()

Does the same as update_incoming_faxcapi_section, but in a loop over all
existing faxcards.
 Returns 1 on success.

=cut

sub update_incoming_faxcapi() 
{
	my $faxcard_nr = Yaffas::Module::Faxsrv::get_number_fax_cards();
	for (my $fc = 1; $fc <= $faxcard_nr; $fc++)
	{
		if (check_existing_conf_entry($fc))
		{
			for (my $bc = 1; $bc <= 2; $bc++)
			{	
				eval
				{
					update_incoming_faxcapi_section($fc, $bc);
				};
				if ($@)
				{
					return 0;
				}
			}
		}
	}
	return 1;
}

=item update_incoming_faxcapi_section ( CONTROLLER B_CHANNEL )

It replaces the MSNs in /etc/hylafax/config.faxCAPI with new MSN from DB
in given right controller section. It uses get_incoming_msn(). 
It returns 1 on success, else 0.

=cut

sub update_incoming_faxcapi_section ($$) 
{
    my $controller = shift;
    my $bchannel = shift;
    my $in_msns = "";

    my @msns = get_incoming_msn();
    my $count = 0;

	if (check_existing_conf_entry($controller))
	{
		foreach my $msn (@msns)
		{
			my @msn = @{$msn};
			if ($msn[1] == $controller && ($bchannel == 0 || $msn[2] == $bchannel))
			{
				$in_msns .= "$msn[0] ";
				if ($count > 5)
				{
					$in_msns .= " \\\n";
					$count = 0;
				}
				else
				{
					$count++;
				}
			}
		}
		$in_msns =~ s/\s*\\\n\s*$//s; 

		eval
		{
			exchangeFaxSectionLines($controller, $bchannel, 
									'^\s*IncomingMSNs.*', "\t\tIncomingMSNs:\t$in_msns") or die "$!";
			exchangeFaxSectionLines($controller, $bchannel, 
									'^\s*IncomingDDIs.*', "\t\tIncomingDDIs:\t$in_msns") or die "$!";
		};
		if ($@)
		{
			throw Yaffas::Exception("err_update_hyla_conf");
			return 0;
		}
	}
    return 1;
}

=item exchange_fax_section_ines ( CONTROLLER, CHANNEL, SEARCH_REGEX, REPLACEMENT )

It allows to change Lines in the /etc/hylafa/xconfig.facCAPI for a specified CONTROLLER
and CHANNEL.

=cut

## wenn das generalisiert werden kann müsst es bestimmt in Yaffas::File?!
sub exchangeFaxSectionLines ($$$$){
    my $controller = shift;
    my $channel = shift;
    my $sLine = shift;
    my $rLine = shift;
    my $faxcapi = Yaffas::Constant::FILE->{config_faxcapi};

    my $file = Yaffas::File->new($faxcapi);
	throw Yaffas::Exception("err_open_file") if ( ! defined($file) );
    my $sub_beg = $file->search_line( qr/^\s*#\s*begin\s+card\s+$controller\s*,\s*channel\s+$channel.*$/);
    my $sub_end = $file->search_line( qr/^\s*#\s*end\s+card\s+$controller\s*,\s*channel\s+$channel.*$/);

    my $match_line_nr = $file->search_line($sLine, $sub_beg, $sub_end);
	if ( defined($match_line_nr) && defined($sub_beg) && defined($sub_end) )
	{
		my $match_line = $file->get_content($match_line_nr);
		my $next_line_nr = $match_line_nr + 1;
		while ($match_line =~ m/\\\s*$/)
		{
			my $tmp_line = $file->get_content($next_line_nr);
			$match_line .= "\n" . $tmp_line;
			$next_line_nr++;
		}
		$match_line =~ s/$sLine/$rLine/s;

		$file->splice_line($match_line_nr, $next_line_nr-$match_line_nr, $match_line);
		throw Yaffas::Exception("err_write_file") if (! $file->write());
	}
	elsif (check_existing_conf_entry($controller))
	{
		throw Yaffas::Exception("err_line_not_found"); 
	}
	return 1;
}

=item get_user_msn ( USER )

This routine returns msn_controller_channel for the given user or undef
if there is no msn.

=cut

sub get_user_msn($)
{
	my @msns = ();
	my $user = shift;

	my $fax_type = Yaffas::Check::faxtype();
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
	if (defined($dbh))
	{
		# get id of user
		my $sqlq = "select id from ug where ug = '$user' and type = 'u'";
		my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
		my $id = $tmp[0][0];
		
		# get msns of id
		if ( defined($id) )
		{
			if ($fax_type eq "CAPI")
			{
				$sqlq = "select msn, ctrl, channel from msn_avm where id = '$id'";
				@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

				foreach my $i (@tmp)
				{
					if ($#$i == 2)
					{
						push @msns, "$$i[0]_$$i[1]_$$i[2]";
					}
				}
			}
			else
			{
				$sqlq = "select msn, ctrl from msn_eicon where id = '$id'";
				@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

				foreach my $i (@tmp)
				{
					if ($#$i == 1)
					{
						push @msns, "$$i[0]_$$i[1]";
					}
				}
			}

			Yaffas::Postgres::pg_disconnect($dbh);
		}
	}

	return @msns;
}

=item get_group_msn ( GROUP )

This routine returns msn_controller_channel for the given group or undef
if there is no msn.

=cut

sub get_group_msn($)
{
	my @msns = ();
	my $group = shift;
	my $fax_type = Yaffas::Check::faxtype();
        my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
 
	if (defined($dbh))
	{
		# get id of group 
		my $sqlq = "select id from ug where ug = '$group' and type = 'g'";
		my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
		my $id = $tmp[0][0];
		
		# get msns of id
		if ( defined($id) )
		{
			if ( $fax_type eq "CAPI" )
			{
				$sqlq = "select msn, ctrl, channel from msn_avm where id = '$id'";
				@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

				foreach my $i (@tmp)
				{
					if ($#$i == 2)
					{
						push @msns, "$$i[0]_$$i[1]_$$i[2]";
					}
				}
			}
			else
			{
				$sqlq = "select msn, ctrl from msn_eicon where id = '$id'";
				@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

				foreach my $i (@tmp)
				{
					if ($#$i == 1)
					{
						push @msns, "$$i[0]_$$i[1]";
					}
				}
			}

			Yaffas::Postgres::pg_disconnect($dbh);
		}
	}

	return @msns;
}

=item get_all_ctrl_msns ( CTRL )

Returns all msn, configured on given CTRL

=cut

sub get_all_ctrl_msns($)
{
	my $ctrl = shift;
	my @msns = ();
	my $fax_type = Yaffas::Check::faxtype();
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
	if (defined($dbh))
	{
		if ( $fax_type eq "CAPI" )
		{
			my $sqlq = "select msn, ctrl, channel from msn_avm where ctrl = $ctrl";
			my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 2)
				{
					push @msns, "$$i[0]_$$i[1]_$$i[2]";
				}
			}
		}
		else
		{
			my $sqlq = "select msn, ctrl from msn_eicon where ctrl = $ctrl";
			my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 1)
				{
					push @msns, "$$i[0]_$$i[1]";
				}
			}
		}

		Yaffas::Postgres::pg_disconnect($dbh);
	}

	return @msns;
}

=item get_owner_of_msn ( LONGMSN )

Returns owner and [user|group] of the LONGMSN

=cut

sub get_owner_of_msn($)
{
	my $ldap_msn = shift;
	my @return = ();

	my $fax_type = Yaffas::Check::faxtype();
	my $msn = undef;
	my $ctrl = undef;
	my $bc = undef;

	if (Yaffas::Check::ldap_msn($ldap_msn))
	{
		if ($fax_type eq "CAPI")
		{
			($msn, $ctrl, $bc) = split(/_/, $ldap_msn);
		}
		else
		{
			($msn, $ctrl) = split(/_/, $ldap_msn);
		}
		my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
		if (defined($dbh))
		{
			my $sqlq = "";
			# get id of msn
			if ($fax_type eq "CAPI")
			{
				unless (defined($bc))
				{
					Yaffas::Postgres::pg_disconnect($dbh);
					return undef;
				}
				$sqlq = "select id from msn_avm where msn = '$msn' and ctrl = $ctrl and channel = $bc";
			}
			else
			{
				$sqlq = "select id from msn_eicon where msn = '$msn' and ctrl = $ctrl";
			}
			my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			my $id = $tmp[0][0];

			# search for ug and type of id
			if (defined($id))
			{
				$sqlq = "select ug, type from ug where id = $id";
				my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

				my $type = undef;
				if ($tmp[0][1] eq 'g')
				{
					$type = "group";
				}
				else
				{
					$type = "user";
				}
				push @return, $tmp[0][0], $type;
			}

			Yaffas::Postgres::pg_disconnect($dbh);
		}
	}

	return (scalar @return) ? @return : undef;
}

=item get_all_user_msn ( )

This routine returns all user msn_controller_channel in db or undef
if there is no msn.

=cut

sub get_all_user_msn()
{
	my @msns = ();

	my $fax_type = Yaffas::Check::faxtype();
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

	if (defined($dbh))
	{
		my $sqlq = "";
		my @tmp = ();
		if ($fax_type eq "CAPI")
		{
			$sqlq = "select msn, ctrl, channel from msn_avm where id in (select id from ug where type = 'u')";
			@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 2)
				{
					push @msns, "$$i[0]_$$i[1]_$$i[2]";
				}
			}
		}
		else
		{
			$sqlq = "select msn, ctrl from msn_eicon where id in (select id from ug where type = 'u')";
			@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 1)
				{
					push @msns, "$$i[0]_$$i[1]";
				}
			}
		}
		Yaffas::Postgres::pg_disconnect($dbh);
	}

	return @msns;
}

=item get_all_group_msn ( )

This routine returns all group msn_controller_channel in ldap or undef
if there is no msn.

=cut

sub get_all_group_msn()
{
	my @msns = ();
	my $sqlq = "";
	my @tmp = ();
	my $fax_type = Yaffas::Check::faxtype();
        my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

	if (defined($dbh))
	{
		if ($fax_type eq "CAPI")
		{
			$sqlq = "select msn, ctrl, channel from msn_avm where id in (select id from ug where type = 'g')";
			@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 2)
				{
					push @msns, "$$i[0]_$$i[1]_$$i[2]";
				}
			}
		}
		else
		{
			$sqlq = "select msn, ctrl from msn_eicon where id in (select id from ug where type = 'g')";
			@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			foreach my $i (@tmp)
			{
				if ($#$i == 1)
				{
					push @msns, "$$i[0]_$$i[1]";
				}
			}
		}

		Yaffas::Postgres::pg_disconnect($dbh);
	}

	return @msns;
}

=item get_msn_users( LONGMSN )

This routine does the same thing above the other way. You'll tell us
msn_controller_channel, we'll tell you the user.

=cut

sub get_msn_user($)
{
	my $longmsn = shift;
	my @users = ();
	my $msn = undef;
	my $ctrl = undef;
	my $bc = undef;

	my $fax_type = Yaffas::Check::faxtype();

	if (Yaffas::Check::ldap_msn($longmsn))
	{
		if ($fax_type eq "CAPI")
		{
			($msn, $ctrl, $bc) = split(/_/, $longmsn);
		}
		else
		{
			($msn, $ctrl) = split(/_/, $longmsn);
		}
		my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

		if (defined($dbh))
		{
			my $sqlq = "";
			# get id of longmsn
			if ($fax_type eq "CAPI")
			{
				unless (defined($bc))
				{
					Yaffas::Postgres::pg_disconnect($dbh);
					return undef;
				}
				$sqlq = "select id from msn_avm where msn = $msn and ctrl = $ctrl and channel = $bc";
			}
			else
			{
				$sqlq = "select id from msn_eicon where msn = $msn and ctrl = $ctrl";
			}
			my @tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);
			my $id = $tmp[0][0];

			# get user of id
			$sqlq = "select ug from ug where id = $id";
			@tmp = Yaffas::Postgres::search_entry_rows($dbh, $sqlq);

			Yaffas::Postgres::pg_disconnect($dbh);

			foreach my $i (@tmp)
			{
				push @users, $$i[0]
			}
		}
	}

	return (scalar @users) ? @users: undef;
}

=item mod_p2p_capi_conf ( CTRL SWITCH )

Modifies P2P optins in capi.conf.
 CTRL is the controller number
 SWITCH can be ( on | off | status ).
 Status return OPTION value in capi.conf (most P2P).
 Throws exception on error.

=cut

sub mod_p2p_capi_conf($$)
{
	my $controller = shift;
	my $switch = shift;
	my $capiconf = Yaffas::Constant::FILE->{capi_conf};
	my $change = 0;
	
	my $caco = Yaffas::File->new($capiconf);
	throw Yaffas::Exception("err_open_file") if ( ! defined($caco) );
	my @fileArray = $caco->get_content();

	# search and substitued line(s) in array
	for (my $i = 0; $i <= $#fileArray; $i++)
	{
		my $line = $fileArray[$i];
		if ($line =~ m/^\s*([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+$controller\s*(.*)$/)
		{
			my $newline = undef;
			if ( $switch eq "on" )
			{
				$newline = "$1\t$2\t$3\t$4\t$5\t$6\t$controller\tP2P";
				throw Yaffas::Exception("err_cant_replace_line") if
					( ! $caco->splice_line($i, 1, $newline));
				$change = 1;
			}
			elsif ( $switch eq "off" )
			{
				$newline = "$1\t$2\t$3\t$4\t$5\t$6\t$controller";
				throw Yaffas::Exception("err_cant_replace_line") if
					( ! $caco->splice_line($i, 1, $newline));
				$change = 1;
			}
			else
			{
				my $option = $7;
				$option =~ s/^\s*//; $option =~ s/\s*$//;
				if ( defined($option) )
				{
					return $option;
				}
				else
				{
					return undef;
				}
			}
		}
	}

	if ($change == 1)
	{
		throw Yaffas::Exception("err_write_file") if (! $caco->write());
	}
}

=item rm_msn( MSNHASH )

Removes all MSNs in hash.
 Throws exception on error.

=cut

sub rm_msn (@)
{
	my $msns = shift;
	my $exception = Yaffas::Exception->new();
	my $throw_ex = 0;
	my $ret = undef;

	my $fax_type = Yaffas::Check::faxtype();
	my $msn = undef;
	my $controller = undef;
	my $bchannel = undef;

	set_NeedToTakeover_flag();

	foreach my $ldapmsn (@{$msns})
	{
		if ($fax_type eq "CAPI")
		{
			($msn, $controller, $bchannel) = split(/_/, $ldapmsn);
		}
		else
		{
			($msn, $controller) = split(/_/, $ldapmsn);
		}

		$exception->add("err_msn_nr", " ($ldapmsn)") unless (Yaffas::Check::ldap_msn($ldapmsn));
		throw $exception if ($throw_ex == 1);

		my $cmode = get_ctrl_mode($controller);
		my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

		if (defined($dbh))
		{
			if ($fax_type eq "CAPI")
			{
				if ("$cmode" eq "separat")
				{
					unless (defined($bchannel))
					{
						Yaffas::Postgres::pg_disconnect($dbh);
						return undef;
					}
					my $sqlq = "delete from msn_avm where msn = '$msn' and ctrl = $controller and channel = $bchannel";
					$ret = Yaffas::Postgres::del_entry($dbh, $sqlq);
				}
				else
				{
					my $sqlq = "delete from msn_avm where msn = '$msn' and ctrl = $controller";
					$ret = Yaffas::Postgres::del_entry($dbh, $sqlq);
				}
			}
			else
			{
				my $sqlq = "delete from msn_eicon where msn = '$msn' and ctrl = $controller";
				$ret = Yaffas::Postgres::del_entry($dbh, $sqlq);
			}

			Yaffas::Postgres::pg_disconnect($dbh);
		}
	}

	# call function to update faxcapi with incoming msn's
	if ($fax_type eq "CAPI")
	{
		# CAPI conf update
		throw Yaffas::Exception("err_update_hyla_conf") if
			(! update_incoming_faxcapi() );
	}
	else
	{
		# EICON conf update
		# will be done on 'take over'...
	}

	return defined($ret) ? $ret : undef;
}


=item msn_configured( MSN CTRL (BCHANNEL)? )

Returns 1 if MSN is already configured on CTRL (and B-Channel). Else undef.

=cut

sub msn_configured ($$;$)
{
	my $msn = shift;
	my $ctrl = shift;
	my $bchannel = shift;

	my $fax_type = Yaffas::Check::faxtype();

	throw Yaffas::Exception("err_msn_nr") if ( $msn !~ m/^\d+$/ );
	throw Yaffas::Exception("err_ctrl_nr") if ( $ctrl !~ m/^\d+$/ );
	my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");

	if (defined($dbh))
	{
		my $sqlq = "";
		if ($fax_type eq "CAPI")
		{
			unless (defined($bchannel))
			{
				Yaffas::Postgres::pg_disconnect($dbh);
				return undef;
			}
			$sqlq = "select id from msn_avm where msn = '$msn' and ctrl = $ctrl and channel = $bchannel";
			return 1 if ( scalar (Yaffas::Postgres::search_entry_rows($dbh, $sqlq)) );
		}
		else
		{
			$sqlq = "select id from msn_eicon where msn = '$msn' and ctrl = $ctrl";
			return 1 if ( scalar (Yaffas::Postgres::search_entry_rows($dbh, $sqlq)) );
		}

		Yaffas::Postgres::pg_disconnect($dbh);
	}

	return undef;
}



=item set_NeedToTakeover_flag()

=item remove_NeedToTakeover_flag()

=item is_NeedToTakeover()

sets and removes a flag, that indicates that we need to do a "takeover" to apply the settings.

=cut

sub is_NeedToTakeover{
    my $TakeoverFlag = Yaffas::Constant::FILE->{need_takeover_flag_file};
    return(-f $TakeoverFlag);
}

sub set_NeedToTakeover_flag{
    my $TakeoverFlag = Yaffas::Constant::FILE->{need_takeover_flag_file};
    my $bkf = Yaffas::File->new($TakeoverFlag, "");
    $bkf->write();
}

sub remove_NeedToTakeover_flag{
    my $TakeoverFlag = Yaffas::Constant::FILE->{need_takeover_flag_file};
    unlink $TakeoverFlag;
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
