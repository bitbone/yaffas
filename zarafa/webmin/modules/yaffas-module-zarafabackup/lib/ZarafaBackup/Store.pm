package Yaffas::Module::ZarafaBackup::Store;

use Data::Dumper;
use Error qw(:try);
use Yaffas::Module::ZarafaBackup;
use Yaffas::Exception;
use Yaffas::Constant;
use POSIX;
use Storable;
use CGI;

my $dir = $Yaffas::Module::ZarafaBackup::BACKUPDIR;

sub new {
    my $class = shift;
    my $day = shift;
    my $user = shift;

    my $self = {DAY => $day, USER => $user};

    bless $self, $class;
    return $self;
}

sub getFolders {
    my $self = shift;
    my $parent = shift;

    my $ret = {};

    my $cache_file = "$dir/".$self->{DAY}."/".$self->{USER}."-folder.cache";
    if (-f $cache_file) {
        $ret = retrieve($cache_file);
    }
    else {
        my $file = "$dir/".$self->{DAY}."/".$self->{USER}.".index.zbk";

        open FILE, "<", $file or throw Yaffas::Exception("err_file_read", $file);

        foreach my $line (<FILE>) {
            my @items = split ":", $line;

            if ($items[0] eq "C" || $items[0] eq "R") {
                chomp(my $parent = $items[2]);
                chomp(my $id = $items[4]);
                chomp(my $name = $items[11]);

                $name = "root" unless defined $name;

                if ($items[0] eq "R") {
                    $ret = [ { id => $parent, children => [], label => $self->{USER} } ];
                }
                else {
                    chomp(my $record = $items[6]);
                    chomp(my $size = $items[7]);
                    chomp(my $type = $items[9]);
                    my $e = findparent($ret, $parent);
                    #$e->{$id} = {name => $name, record => $record, size => $size};
                    push @{$e}, { id => $id, children => [], type => $type, restorekey => $record, label => $name };
                }
            }
        }
        close FILE;
        store $ret, $cache_file;
    }
    return $ret;
}

sub findparent {
    my $tree = shift;
    my $parent = shift;

    my $ret;

    return unless ref $tree eq "ARRAY";

    foreach my $k (@{$tree}) {
        if ($parent eq $k->{id}) {
            if (ref $k->{children} ne "ARRAY") {
                $k->{children} = [];
            }
            return $k->{children};
        }
        $ret = findparent($k->{children}, $parent);
    }
    return $ret;
}

sub getElements {
    my $self = shift;
    my $folder = shift;

    my $ret = [];

    my $cache_file = "$dir/".$self->{DAY}."/".$self->{USER}."-".$folder.".cache";

    if (-f $cache_file) {
        $ret = retrieve($cache_file);
    }
    else {
        my $file = "$dir/".$self->{DAY}."/".$self->{USER}.".index.zbk";
        open FILE, "<", $file or throw Yaffas::Exception("err_file_read", $file);

        foreach my $line (<FILE>) {
            my @items = split ":", $line, 11;

            if ($items[0] eq "M") {
                chomp(my $type = $items[6]);

                chomp(my $parent = $items[2]);
                chomp(my $date = $items[5]);
                chomp(my $sender = $items[9]);

                if ($parent eq $folder) {
                    chomp(my $id = $items[4]);

                    if ($type eq "IPM.Appointment") {
                        my @items = split ":", $line, 12;
                        chomp(my $start = $items[9]);
                        chomp(my $end = $items[10]);
                        chomp(my $subject = $items[11]);

                        push @{$ret}, {
                            restorekey => $id,
                            subject => $subject,
                            date => strftime("%Y-%m-%d %H:%M", localtime($date)),
                            start => strftime("%Y-%m-%d %H:%M", localtime($start)),
                            end => strftime("%Y-%m-%d %H:%M", localtime($end)),
                        };
                    }
                    else {
                        chomp(my $subject = $items[10]);
                        push @{$ret}, { sender => $sender, restorekey => $id, subject => CGI::escapeHTML($subject), date => strftime("%Y-%m-%d %H:%M", localtime($date)) };
                    }
                }
            }
        }
        close FILE;

        store $ret, $cache_file;
    }

    return $ret;
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

