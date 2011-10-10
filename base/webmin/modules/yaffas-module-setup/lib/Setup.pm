package Yaffas::Module::Setup;

use strict;
use warnings;

use Data::Dumper;
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::Service qw/ZARAFA_SERVER RESTART/;
use Yaffas::File::Config;

sub hide() {
    my $f = Yaffas::Constant::FILE->{webmin_acl};
    unlink $f;
    symlink $f."-global", $f;
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
