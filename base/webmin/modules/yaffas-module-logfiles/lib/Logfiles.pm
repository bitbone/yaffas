#!/usr/bin/perl
package Yaffas::Module::Logfiles;

use strict;
use warnings;

use Yaffas::Constant;

our @ISA = qw(Yaffas::Module);

sub conf_dump {
	return 1;
}

sub get_filenames() {
	return (
			"/var/log/exim4/mainlog",
			"/var/log/exim4/rejectlog",
			"/var/log/fetchmail.log",
			"/var/log/syslog",
			"/var/log/messages",
			"/var/log/cups/access_log",
			"/var/log/mail.err",
			"/var/log/mail.info",
			"/var/log/mail.log",
			"/var/log/maillog",
			"/var/log/auth.log",
			"/var/log/mail.warn",
			( Yaffas::Constant::OS eq 'Ubuntu' ? "/var/log/samba/log.nmbd" : "/var/log/samba/nmbd.log" ),
			( Yaffas::Constant::OS eq 'Ubuntu' ? "/var/log/samba/log.smbd" : "/var/log/samba/smbd.log" ),
			( Yaffas::Constant::OS eq 'Ubuntu' ? "/var/log/samba/log.winbind" : "/var/log/samba/winbindd.log" ),
			"/var/log/mysql.err",
			"/var/log/daemon.log",
			"/data/fax/hylafax/log/capi4hylafax",
			"/var/log/postgresql/postgresql-8.3-main.log",
			"/var/log/zarafa/gateway.log",
			"/var/log/zarafa/dagent.log",
			"/var/log/zarafa/ical.log",
			"/var/log/zarafa/monitor.log",
			"/var/log/zarafa/server.log",
			"/var/log/zarafa/spooler.log",
		   );
}

sub get_old_filenames() {
	my @files = get_filenames();
	my $dir;
	my @old_files = ();
	foreach my $file ( @files ) {
		$dir = $file;
		my @tmp = split /\//, $dir;
		$file = pop @tmp;
		$dir = join '/', @tmp;
		opendir( DIR, $dir );
		while( my $old_file = readdir( DIR ) ) {
			push( @old_files, "$dir/$old_file" ) if $old_file =~ m/$file\.(\d+|gz)(\.gz)?/;
		}
		closedir( DIR );
	}
	return @old_files;
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
