#!/usr/bin/perl
package Yaffas::Mail::Mailalias::LDAP;

use strict;
use warnings;
use Yaffas::LDAP;


sub BEGIN {
   use Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw/_read _write/;
   our @EXPORT_OK = qw(_read _write);
}

sub _write {
   my $mode = shift;
   my $data = shift;
   my $remove = shift;
   my $clean = {};

   while(my($k,$v) = each %{$data})
   {
       my @users = split(/\s*,\s*/, $v);
       push @{ $clean->{ $_} }, $k for @users;
   }

   while(my($k,$v) = each %{$remove})
   {
        Yaffas::LDAP::replace_entries($k, ['replace' => [ 'zarafaAliases' => [] ]] );
   }

   while(my($uid, $aref) = each %$clean)
   {
       my $changes = [];
       push @$changes, 'replace' => [ 'zarafaAliases' => [] ];

       foreach my $alias (@$aref)
       {
           push @$changes, 'add' => [ 'zarafaAliases' => $alias ] ;
       }

       Yaffas::LDAP::replace_entries($uid, $changes);
   }

   return 1;
}

sub _read {
   my $mode = shift;
   return {} if $mode && $mode eq 'DIR';

   my @users = Yaffas::LDAP::search_entry("objectClass=zarafa-user", "uid");
   my %ret;

   foreach my $user (@users)
   {
       my @aliases = Yaffas::LDAP::search_entry("&(objectClass=zarafa-user)(uid=$user)", "zarafaAliases");
       
       foreach my $a (@aliases)
       {
           if(exists($ret{$a}))
           {
               $ret{$a} = join(", ", $ret{$a}, $user);
           }
           else
           {
               $ret{$a} = $user;
           }
       }
   }

   return \%ret;
}

return 1;

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
