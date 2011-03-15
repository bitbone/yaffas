#!/usr/bin/perl -w
package Yaffas::File::Config;
use strict;
use Yaffas::File;
use Config::General;

our @ISA = ("Yaffas::File");

## prototypes ##

=pod

=head1 NAME

Yaffas::File::Config - Reading and Writing Config Files.

=head1 SYNOPSIS

 use Yaffas::File::Config;

 my $bkc = Yaffas::File::Config->new($alias_file,
					{
						-SplitPolicy => 'custom',
						-SplitDelimiter => ':\s*',
						-StoreDelimiter => ': ',
					});

 my $hashref = $bkc->get_cfg_values();

 $hashref->{new_key} = $value;

 $bkc->write();


=head1 DESCRIPTION

Yaffas::File::Config provides some special config file methods.
Plsase do not use the CONTENT of Yaffas::File here, since its not really up to date.

=head1 METHODS

=over

=item new ( FILE, [OPTIONS, [CONTENT]] )

Adds Config::General functionallity to the Yaffas::File. so have a look at L<Config::General>.
OPTIONS is a hash with Config::General options.

The Options C<<< -String => join "", $self->{CONTENT} >>> automatically used.

=cut

sub new ($$;\%\[$@]){
    my $class = shift;
    my $file = shift;
    my $options = shift;
    my $content = shift;
    my $self = $class->SUPER::new($file, $content) or return undef;
    my $cfg = new Config::General(
                              -String => (join "\n", @{$self->{CONTENT}}),
                              %{$options},
                             );
	my %hash_content = $cfg->getall();
    $self->{CFG} = $cfg;
	$self->{HASH} = \%hash_content;
    bless $self, $class;
    return $self;
}

=item get_cfg ()

you should use this to work with L<Config::General>.

 $bkcfgfile->get_cfg->ANY_METHOD_OF_CONFIG::GENERAL();

=cut

sub get_cfg($){
    my $self = shift;
    return $self->{CFG};
}

=item get_cfg_values

returns a hashref representing the config file.
if you modify the hash and call C<< $your_instance->write() >>, this hash will writed down in your ocnfig-file.

=cut

sub get_cfg_values ($){
    my $self = shift;
	return $self->{HASH};
}

=item write ()

=item save ()

Writes the Yaffas::File::Config back to the file.

=cut

sub write {
	my $self = shift;
	my $cfg = $self->{CFG};
	my $hash = $self->{HASH};
	my $filename = $self->{FILE};
	$cfg->save_file($filename, $hash);
	$self->_apply_permissions();
}

*save = *write;


#sub get_content {
##	my $self = shift;
#	my $cfg = $self->{CFG};
#	use Data::Dumper;
#	my %foo  = $cfg->getall();
#	return Dumper  \%foo;
#}

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
