#!/usr/bin/perl
package Yaffas::Module::Time;

use strict;
use warnings;

use Yaffas;
use Yaffas::Module;

use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::File::Config;
use Yaffas::Exception;
use Error qw(:try);
use File::Copy;

our @ISA = ("Yaffas::Module");

sub conf_dump () {
	my $timeserver = get_timeserver();
	set_timeserver_config($timeserver);
}

sub set_timeserver_config {
	my $timeserver = shift;
	my $bkc        = Yaffas::Conf->new();
	my $sec        = $bkc->section("time");
	my $func       = Yaffas::Conf::Function->new( "timeserver",
		"Yaffas::Module::Time::set_timeserver" );

	$func->add_param( { type => "scalar", param => $timeserver } );

	$sec->add_func($func);
	my $cronjob = get_cron_values();

	# if %cronjob is defined, there is a timeserver entry in crontab
	if ( defined($cronjob) ) {
		my $bkf = Yaffas::Conf::Function->new( "crontab",
			"Yaffas::Module::Time::set_crontab" );
		$bkf->add_param( { type => 'scalar', param => $cronjob->{hour} } );
		$bkf->add_param( { type => 'scalar', param => $cronjob->{minute} } );
		$bkf->add_param( { type => 'scalar', param => $cronjob->{command} } );
		$sec->add_func($bkf);
	}
	$bkc->save();
}

sub set_timeserver {
	my $timeserver = shift;

	my $configdir = Yaffas::Constant::DIR->{webmin_config} . "/time";
	if (! -d $configdir) {
		mkdir $configdir;
	}
	my $configfile = $configdir . "/config";
	my $bkc        = Yaffas::File::Config->new(
		$configfile,
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => '='
		}
	);
	unlink $configfile;
	my $hash = $bkc->get_cfg_values();

	$hash->{timeserver} = $timeserver;

	$bkc->write();

	Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{ntpdate},
		"-u", $timeserver );
}

sub get_timeserver {
	my $configfile = Yaffas::Constant::DIR->{webmin_config} . "/time/config";
	my $bkc        = Yaffas::File::Config->new($configfile);
	my $timeserver = $bkc->get_cfg_values()->{timeserver};
	return $timeserver;
}

sub set_crontab {
	my $hour       = shift;
	my $min        = shift;
	my $timeserver = shift;

	if ( defined($hour) || defined($min) ) {

		$hour = "*" if ( $hour eq "" );
		$min  = "*" if ( $min  eq "" );

		my $bkfile = Yaffas::File->new( Yaffas::Constant::FILE->{'crontab'} )
		  or throw Yaffas::Exception( "err_opening_file",
			Yaffas::Constant::FILE->{'crontab'} );
		my $cronline =
		    $min . " " 
		  . $hour
		  . " * * *\troot\t/usr/sbin/ntpdate -u "
		  . $timeserver
		  . "  2>&1 | logger";
		my $linenr = -1;
		if ( defined( $linenr = $bkfile->search_line("ntpdate") ) ) {
			$bkfile->splice_line( $linenr, 1, "$cronline" );
		}
		else {
			$bkfile->add_line("$cronline");
		}
		$bkfile->write()
		  or throw Yaffas::Exception( 'err_writing_file',
			Yaffas::Constant::FILE->{'crontab'} );
	}
}

sub rm_crontab {
	my $bkfile = Yaffas::File->new( Yaffas::Constant::FILE->{'crontab'} )
	  or throw Yaffas::Exception( "err_opening_file",
		Yaffas::Constant::FILE->{'crontab'} );
	my $linenr = -1;

	if ( defined( $linenr = $bkfile->search_line("ntpdate") ) ) {
		$bkfile->splice_line( $linenr, 1 );
	}

	$bkfile->write()
	  or throw Yaffas::Exception( 'err_writing_file',
		Yaffas::Constant::FILE->{'crontab'} );
}

##
# Returns the first ntpdate entry in /etc/crontab as a hash.
#
# $cronjob{hour}: Hour when ntpdate is executed
# $cronjob{minute}: Minute when ntpdate is executed
# $cronjob{command}: The actual executed command
#
# Other time options are ignored
# If no ntpdate entry is found, undef is returned
##
sub get_cron_values {
	open( DAT, Yaffas::Constant::FILE->{'crontab'} );
	while (<DAT>) {
		if (/ntpdate/) {
			my $line = $_;
			$line = /(.*?)\s(.*?)\s.*-u\s(.*)\s/;

			my %cronjob = ();
			$cronjob{hour}    = $2;
			$cronjob{minute}  = $1;
			$cronjob{command} = $3;
			close DAT;
			return \%cronjob;
		}
	}
	close DAT;
	return undef;
}

sub set_time {
	my $in = shift;
	my @format;

	for my $i (qw(month date year hour minute second)) {
		throw Yaffas::Exception("err_time_format") if ( $in->{$i} !~ /^\d+$/ );
	}

    set_timezone($main::in{timezone});

	$in->{'year'} = substr( $in->{'year'}, 2, length( $in->{'year'} ) );

	push @format, "--set",
	    "--date="
	  . $in->{'month'} . "/"
	  . $in->{'date'} . "/"
	  . $in->{'year'} . " "
	  . $in->{'hour'} . ":"
	  . $in->{'minute'} . ":"
	  . $in->{'second'} . "";

	system("/sbin/hwclock", @format) == 0 or
		throw Yaffas::Exception("err_cannot_set_time");
	system("/sbin/hwclock", "--hctosys") == 0 or
		throw Yaffas::Exception("err_cannot_set_time");
}

sub get_time {
	my %hw_date;
	for my $cmd ("hwclock", "date '+%a %b %e %H:%M:%S %Y '") {
		my $rawhwdate = `$cmd`;
		if ( $rawhwdate =~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)\s+/ )
		{
			$hw_date{'day'}    = $1;
			$hw_date{'month'}  = $2;
			$hw_date{'date'}   = $3;
			$hw_date{'hour'}   = $4;
			$hw_date{'minute'} = $5;
			$hw_date{'second'} = $6;
			$hw_date{'year'}   = $7;
			last;
		}
		elsif ( $rawhwdate =~
			/^(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(am|pm)\s+/i )
		{
			$hw_date{'day'}    = $1;
			$hw_date{'month'}  = $3;
			$hw_date{'date'}   = $2;
			$hw_date{'hour'}   = $5;
			$hw_date{'minute'} = $6;
			$hw_date{'second'} = $7;
			$hw_date{'year'}   = $4;
			$hw_date{'hour'} += 12 if ( $8 eq 'pm' );
			last;
		}
	}
	if (!exists $hw_date{'year'}) {
		throw Yaffas::Exception("err_hwclock_format");
	}

	return %hw_date;
}

sub get_current_timezone {
    if (Yaffas::Constant::OS eq "Ubuntu" || Yaffas::Constant::OS eq "Debian") {
        my $file = Yaffas::File->new(Yaffas::Constant::FILE->{timezone})
            or throw Yaffas::Exception("err_file_not_found", Yaffas::Constant::FILE->{timezone});

        my $zone = $file->get_content();

        return $zone;
    }
    else {
        my $file = Yaffas::File->new(Yaffas::Constant::FILE->{sysconfig_clock})
            or throw Yaffas::Exception("err_file_not_found", Yaffas::Constant::FILE->{sysconfig_clock});

        my @content = $file->get_content();

        foreach my $line (@content) {
            if ($line =~ /^ZONE="(.*)"$/) {
                return $1;
            }
        }
    }
}

sub set_timezone {
    my $zone = shift;

    my @zones = get_timezones();

    if (! grep $zone, @zones) {
        throw Yaffas::Exception("err_invalid_timezone", $zone);
    }

    if (Yaffas::Constant::OS eq "Ubuntu" || Yaffas::Constant::OS eq "Debian") {
        my $file = Yaffas::File->new(Yaffas::Constant::FILE->{timezone}, $zone);
        $file->save();
    }
    else {
        my $file = Yaffas::File->new(Yaffas::Constant::FILE->{sysconfig_clock});
        my $line = $file->search_line(qr/^ZONE=/);
        if ($line >= 0) {
            $file->splice_line($line, 1, "ZONE=\"$zone\"");
        }
        else {
            $file->add_line("ZONE=\"$zone\"");
        }
        $file->save();
    }

    if (-l "/etc/localtime") {
        unlink "/etc/localtime";
    }
    my $dir = Yaffas::Constant::DIR->{zoneinfo};
    copy($dir."/posix/".$zone, "/etc/localtime");
}

sub get_timezones {
    my @zones = `find /usr/share/zoneinfo/posix/ -type f | cut -d/ -f6- | sort`;

    foreach (@zones) {
        chomp($_);
    }

    return @zones;
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
