package Yaffas::Module::ZarafaBackup::Set;

use strict;
use warnings;

use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Module::ZarafaBackup;
use File::Find;
use Data::Dumper;

my $dir = $Yaffas::Module::ZarafaBackup::BACKUPDIR;

sub getDates {
    my @ret;

    opendir(DIR, $dir) or return [];

    my @dir_content = readdir(DIR) or Yaffas::Exception("err_read_dir", $dir);

    foreach (@dir_content) {
        next if ($_ eq "." or $_ eq "..");
        if (-d $dir."/".$_) {
            push @ret, $_;
        }
    }

    closedir(DIR);

    return [ reverse sort {$a->{name} cmp $b->{name}} map { {name=>name($_), value=>$_} } @ret ];
}

sub name {
    my $n = shift;

    if ($n =~ /^(\d\d\d\d)(\d\d)(\d\d)-.*?D$/) {
        return "$1-$2-$3";
    }
    if ($n =~ /^(\d\d\d\d)(\d\d)(\d\d)-F$/) {
        return "$1-$2-$3";
    }
}

sub content {
    my $date = shift;
    my @found = ();

    find(sub { /(.*)\.index\.zbk$/ && push @found, $1 }, $dir."/".$date);

    return sort @found;
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

