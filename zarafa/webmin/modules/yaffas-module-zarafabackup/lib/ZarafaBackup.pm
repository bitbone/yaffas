package Yaffas::Module::ZarafaBackup;

use strict;
use warnings;

use Data::Dumper;
use Error qw(:try);
use File::Find;
use File::Path qw(mkpath rmtree);
use POSIX;
use Yaffas;
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::UI::Webmin;

our $LOGFILE = "/var/log/zarafa-backup/tmp.restore.log";
our $PIDFILE = "/var/log/zarafa-backup/restore-running";
our $BACKUPDIR;
my $preserve_time;

BEGIN {
    my $file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'zarafa_backup_conf'}, {-SplitPolicy=>"equalsign"})
        or throw Yaffas::Exception("err_file_open", Yaffas::Constant::FILE->{'zarafa_backup_conf'});

    my $content = $file->get_cfg_values();

    if (exists($content->{backup_dir})) {
        $BACKUPDIR = $content->{backup_dir};
    }
    else {
        $BACKUPDIR = "/data/backup";
    }

    if (exists($content->{preserve_time})) {
        $preserve_time = $content->{preserve_time};
    }
    else {
        $preserve_time = 14;
    }

    if (not defined %main::text) {
        %main::text = Yaffas::UI::Webmin::get_lang("zarafabackup");
    }
}

sub run {
    my $type = shift;

    my $date = strftime("%Y%m%d", localtime());

    mkpath($BACKUPDIR);
    chdir $BACKUPDIR;

    if ($type eq "diff") {
        my $last = find_last_full();
        if ($last ne "") {
            my $old = $last."-F";
            my $new = $date."-".$last."-D";
            mkpath($new);
            chdir $new;

            find({ no_chdir => 1,
                    wanted => sub {
                        /.*\/(.*?\.zbk)$/ && symlink "../$old/$1", $1
                    }
                }, "../".$old);
        }
        else {
            # no backup available
            print $main::text{err_no_full_found};
            return;
        }
    }
    else {
        my $d = $date."-F";
        mkpath($d) or throw Yaffas::Exception("err_mkdir", $d);
        chdir $d or throw Yaffas::Exception("err_mkdir", $d);
    }

    print "Starting backup...\n";
    print Yaffas::do_back_quote("/bin/bash", "-c", "/usr/bin/zarafa-backup -a 2>&1");

    if ($type eq "full") {
        cleanup();
    }
    print "done\n";
}

sub find_last_full {
    opendir DIR, $BACKUPDIR;
    my @dirs = sort readdir DIR;
    close DIR;
    my $last;

    foreach my $d (@dirs) {
        if ($d =~ /-F$/) {
            $last = $d;
        }
    }
    $last =~ s/-F$//;
    return $last;
}

sub restore {
    my $ids = shift;

    open F, ">", $PIDFILE;
    print F $$;
    close F;

    open LOG, ">", $LOGFILE or throw Yaffas::Exception("err_file_open", $LOGFILE);

    my %r;
    foreach my $id (@{$ids}) {
        my $type = $id->{recursive} ? "folder" : "element";
        if (ref $r{$id->{day}}{$id->{store}}{$type} ne "ARRAY") {
            $r{$id->{day}}{$id->{store}}{$type} = [];
        }
        push @{ $r{$id->{day}}{ $id->{store} }{$type} }, { id => $id->{id}, label => $id->{label} };
    }

    foreach my $backup (keys %r) {
        foreach my $user (keys %{$r{$backup}}) {

            if (exists $r{$backup}{$user}{element}) {
                run_restore($backup, $r{$backup}{$user}{element}, $user, "element");
            }

            if (exists $r{$backup}{$user}{folder}) {
                run_restore($backup, $r{$backup}{$user}{folder}, $user, "folder");
            }
        }
    }

    close LOG;
    unlink $PIDFILE;
}

sub run_restore {
    my $backup = shift;
    my $elements = shift;
    my $user = shift;
    my $type = shift;

    my @cmd;

    my $dir = $BACKUPDIR."/".$backup;
    chdir $dir;

    my $label = join "\n", map { " - ".$_->{label} } @{$elements};
    my $text = $main::text{"lbl_run_restoring_".$type};
    $text =~ s/\$1/\n$label\n/;
    print $text;

    push @cmd, "/usr/bin/zarafa-restore", "-u", $user;
    if ($type eq "folder") {
        push @cmd, "-r";
    }
    push @cmd, map { $_->{id} } @{$elements};

    my $log = Yaffas::do_back_quote(@cmd);

    print $log;

    if ($? != 0) {
        print $main::text{lbl_failed}."\n";
    }
    else {
        print $main::text{lbl_done}."\n";
    }
}

sub add_cronjob {
    my $type = shift;
    my $days = shift;
    my $hour = shift;
    my $min = shift;

    throw Yaffas::Exception("err_days") unless (ref $days eq "ARRAY");

    if (scalar @{$days}) {
        throw Yaffas::Exception("err_time") if ($hour eq "" || $hour > 24 || $hour < 0);
        throw Yaffas::Exception("err_time") if ($min eq "" || $min > 24 || $min < 0);
    }

    my $file = Yaffas::File->new( Yaffas::Constant::FILE->{'crontab'} )
        or throw Yaffas::Exception( "err_file_open",
        Yaffas::Constant::FILE->{'crontab'} );

    my $cronline = "$min $hour * * ".(join ",", @{$days})." root /opt/yaffas/webmin/zarafabackup/backup-$type.sh";
    my $ret = 1;

    my $linenr = -1;
    if ( defined( $linenr = $file->search_line("zarafabackup/backup-$type.sh") ) ) {
        if (scalar @{$days}) {
        print "replace line";
            $file->splice_line( $linenr, 1, "$cronline" );
        }
        else {
        print "remove line $linenr";
            $file->splice_line( $linenr, 1 );
            $ret = 0;
        }
    }
    else {
        print "add line";
        if (scalar @{$days}) {
            $file->add_line("$cronline");
        }
    }
    $file->save();
    return 1;
}

sub get_cronjob {
    my $type = shift;

    my $file = Yaffas::File->new( Yaffas::Constant::FILE->{'crontab'} )
        or throw Yaffas::Exception( "err_file_open",
        Yaffas::Constant::FILE->{'crontab'} );

    my $linenr = -1;
    my $line;
    if ( defined( $linenr = $file->search_line("backup-$type.sh") ) ) {
        $line = ($file->get_content())[$linenr];
        my @values = split /\s/, $line;

        return {hour => $values[1], min => $values[0], days => [split /,/, $values[4]]};
    }
    else {
        return {hour => "", min => "", days => []};
    }
}

sub set_backupdir {
    my $dir = shift;

    my $file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'zarafa_backup_conf'}, {-SplitPolicy=>"equalsign"})
        or throw Yaffas::Exception("err_file_open", Yaffas::Constant::FILE->{'zarafa_backup_conf'});

    my $content = $file->get_cfg_values();
    $content->{backup_dir} = $dir;
    $file->save();
}

sub set_preserve_time {
    my $t = shift;

    my $file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'zarafa_backup_conf'}, {-SplitPolicy=>"equalsign"})
        or throw Yaffas::Exception("err_file_open", Yaffas::Constant::FILE->{'zarafa_backup_conf'});

    chomp($t);
    throw Yaffas::Exception("err_preserve_time") unless ($t =~ /^\d+$/);

    my $content = $file->get_cfg_values();
    $content->{preserve_time} = $t;
    $file->save();
}

sub settings {
    my $settings = shift;

    my @days_full = qw(0);
    my @days_diff = qw(1 2 3 4 5 6);
    my ($hour_full, $min_full) = qw(0 30);
    my ($hour_diff, $min_diff) = qw(0 30);

    if (defined $settings) {
        my @diff;
        foreach my $d (@{$settings->{diff}->{days}}) {
            if (not grep {$_ eq $d} @{$settings->{full}->{days}}) {
                push @diff, $d;
            }
        }

        my $ret = add_cronjob("full", $settings->{full}->{days}, $settings->{full}->{hour}, $settings->{full}->{min});
        if ($ret == 1 && scalar @diff) {
            # full backup job was added
            add_cronjob("diff", \@diff, $settings->{diff}->{hour}, $settings->{diff}->{min});
        }
        else {
            add_cronjob("diff", [], $settings->{diff}->{hour}, $settings->{diff}->{min});
        }
        set_backupdir($settings->{global}->{backup_dir});
        set_preserve_time($settings->{global}->{preserve_time});
    }
    else {
        return {
            "full" => get_cronjob("full"),
            "diff" => get_cronjob("diff"),
            "global" => {
                "dir" => $BACKUPDIR,
                "preserve_time" => $preserve_time,
            }
        };
    }
}

sub cleanup {
    my @to_remove;

    opendir DIR, $BACKUPDIR or throw Yaffas::Exception("err_open_dir", $BACKUPDIR);;
    my @dirs = sort readdir DIR;
    close DIR;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $date = mktime(0, 0, 0, $mday, $mon, $year) - ($preserve_time * 86400);
    $date = int strftime("%Y%m%d", localtime($date));

    foreach my $d (@dirs) {
        my $tmp = $d;
        next unless $tmp =~ /-F$/;
        $tmp =~ s/-F$//;
        next if ($d eq "." or $d eq "..");
        if (int($tmp) <= $date) {
            push @to_remove, $tmp;
        }
    }

    foreach my $d (@dirs) {
        if (grep {"$_-F" eq $d || $d =~ /.*-$_-D$/ } @to_remove) {
            print $main::text{lbl_clean_dir}." $d\n";
            rmtree($BACKUPDIR."/".$d);
        }
    }
}

1;

=pod

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

