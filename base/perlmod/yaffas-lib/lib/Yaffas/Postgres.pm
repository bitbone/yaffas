#!/usr/bin/perl -w
package Yaffas::Postgres;
use strict;

use vars qw($Error);

use Data::Dumper;
use DBI;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Exception;
use Error qw(:try);
use strict;
use warnings;

## prototypes ##
sub connect_db($);
sub pg_disconnect($);
sub search_entry_rows($$);
sub replace_entry($$);
sub add_entry($$);
sub del_entry($$);

=head1 NAME

Yaffas::Postgres - Postgres Functions

=head1 SYNOPSIS

use Yaffas::Postgres

=head1 DESCRIPTION

Yaffas::Postgres provides functions to access Postgres DB

=head1 FUNCTIONS

=over


=item search_entry_rows (DBHANDLE, SQL)

searches in Postgres DB.

DBHANDLE from connect_db
SQL statement

Returns array of arrays.

e.g. 
my $dbh = Yaffas::Postgres::connect_db("bbfaxconf");
if (defined($dbh))
{
	my @dbc = Yaffas::Postgres::search_entry_rows($dbh, "select * from ug_msn");
	foreach my $i (@dbc) { print "-@$i-\n"; }
	print $dbc[0][0];
	Yaffas::Postgres::pg_disconnect($dbh);
}

=cut

sub search_entry_rows($$)
{
	my $dbh = shift;
	my $sql = shift;

	throw Yaffas::Exception("err_db_connect") unless(defined($dbh));

	my @dbrv = ();

	my $sth = $dbh->prepare($sql) or return undef;
	#throw Yaffas::Exception("err_db_prep", "($DBI::err):$DBI::errstr");

	my $rv = $sth->execute or return undef;
	#throw Yaffas::Exception("err_db_execute", "($DBI::err):$DBI::errstr");

	if ($rv >= 1)
	{
		my @rows = undef;
		while (@rows = $sth->fetchrow_array)
		{
			push @dbrv, [ @rows ];
		}
	}

	return @dbrv;
}

=item search_ug_table( TYPE )

returns all users or groups from ug table in bbfaxconf

TYPE can either be u for user or g for group

=cut

sub search_ug_table($)
{
	my $dbname = "bbfaxconf";
	my $dbh = Yaffas::Postgres::connect_db($dbname);
	my $type = shift;
	if ($type ne "u" && $type ne "g") {
		throw Yaffas::Exception("err_invalid_type", $type);
	}
	my $sql = "select ug from ug where type = '$type'";

	throw Yaffas::Exception("err_db_connect",$dbname) unless(defined($dbh));

	my $sth;
	eval {
		$sth = $dbh->prepare($sql) or die $dbh->errstr();
		$sth->execute() or die $dbh->errstr();
	};
	if ($@) {
		throw Yaffas::Exception("err_db_query",$sql);
	}

	return map { $_->[0] } @{$sth->fetchall_arrayref};
}

=item replace_entry ( DBH SQL )

Replaces (executes SQL) in Postgres db.
Returns replaced entrys. else undef on error.

e.g.
<connect db>
replace_entry($dbh, "update ug_msn set ug='blub', type='g' where ug='lala'");

=cut

sub replace_entry($$) 
{
	add_entry(shift, shift);
}

=item add_entry ( DBHANDLE SQL )

Adds (executes SQL) to Postgres db.
Returns added entrys. else undef on error.

e.g.
<connect db>
add_entry($dbh, "insert into ug_msn (ug, type, msn, ctrl, channel) values ('georg', 'u', 69, 1, 1)")

=cut

sub add_entry($$)
{
	my $dbh = shift;
	my $sql = shift;

	throw Yaffas::Exception("err_db_connect") unless(defined($dbh));

	my $sth = $dbh->prepare($sql) or return undef;
	#throw Yaffas::Exception("err_db_prep", "($DBI::err):$DBI::errstr");

	my $rv = $sth->execute or return undef;
	#throw Yaffas::Exception("err_db_execute", "($DBI::err):$DBI::errstr");

	return $rv;
}

=item del_entry ( DBHANDLE SQL )

Deletes (executes SQL) entry from Postgres db.
Returns del'ed entrys. else undef on error.

e.g.
del_entry($dbh, "delete from ug_msn where ug = 'user1' and msn = 69") )

=cut

sub del_entry ($$) 
{
	add_entry(shift, shift);
}

=item pg_disconnect ( DBHANDLE )

Disconnects DBHANDLE from database;

=cut

sub pg_disconnect($)
{
	my $dbh = shift;
	$dbh->disconnect;
}


=item connect_db ( DB )

Coonects with given DB on localhost

=cut

sub connect_db($)
{
	my $dbase = shift;

	my $user = 'bitkit';
	my $password = get_pg_bitkit_pass();
	my $host = '127.0.0.1';
	my $port = 5432;
	my $driver = "dbi:Pg:dbname=" . $dbase . ';host=' . $host . ';port=' . $port;
	my $dbh = DBI->connect($driver, $user, $password) or throw Yaffas::Exception("err_db_connect");
	return $dbh;
}

=item get_pg_bitkit_pass ()

	Returns password for bitkit user of postgres db_

=cut

sub get_pg_bitkit_pass()
{
	my $file = Yaffas::Constant::FILE->{bk_pass};
	my $pass = `cat $file`;
	chomp $pass;
	
	return (defined ($pass)) ? $pass : undef;
}

=back

=cut

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
