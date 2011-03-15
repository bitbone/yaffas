#!/usr/bin/perl
package Yaffas::Exception;
use Error;
use Carp qw(cluck);
use Yaffas::Constant;
use Log::Log4perl qw/:easy/;
use warnings;
use strict;


our @ISA = qw(Error);

use overload (
			  'bool' => sub { 
				  my $self = shift;
				  return keys %{$self->{-errors}} ? 1 : 0;
			  },
			 );

=head1 NAME

Yaffas::Exception

=head1 SYNOPSIS

use Yaffas::Exception

=head1 DESCRIPTION

Yaffas::Exception is a Module to catch all your errors. For proper use see L<Error>.

=over

=item new ( KEY, VALUE, TEXT )

Create a new Exception object.

=cut

sub new {
    my $package  = shift;
	my $key   = shift;
    my $value = shift;
    my $text  = shift;

	my @args = ("-text", $text) if (defined($text));

    local $Error::Depth = $Error::Depth + 1;
	my $self = $package->SUPER::new(@args);

	add($self, $key, $value) if $key;

	bless $self, $package;

	Log::Log4perl->easy_init({level => $INFO, file => ">>".Yaffas::Constant::FILE->{'exception_log'}});
	my $log = get_logger();

	if(ref($self->{'-errors'}) && ref($self->{'-errors'} eq 'ARRAY'))
	{
		foreach my $key (@{ $self->{'-errors'} })
		{
			$log->info($key);
		}
	}
	elsif(ref($self->{'-errors'}) && ref($self->{'-errors'} eq 'HASH'))
	{
		foreach my $key (keys %{ $self->{'-errors'} })
		{
			$log->info($key);
		}
	}
	else
	{
		$log->info($self->stringify());
	}

	return $self;
}

sub stringify {
    my $self = shift;
    my $text = $self->SUPER::stringify;
    $text .= sprintf(" at %s line %d.\n", $self->file, $self->line) unless($text =~ /\n$/s);
    $text;
}

=item add( KEY, VALUE )

Adds a value to a KEY. If KEY doesn't exists a new KEY with VALUE is created.

Note: If you use the same key here and in lang file you can use function to create error messages (see Yaffas::UI)

=cut

sub add {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	unless(defined($key)) {
		cluck "no key specified!";
		return undef;
	}

	if (ref($value) eq "ARRAY") {
		push @{$self->{-errors}->{$key}}, @$value;
	}elsif (defined $value) {
		push @{$self->{-errors}->{$key}}, $value;
	}else {
		unless ($self->{-errors}->{$key}) {
			$self->{-errors}->{$key} = [];
		}
	}

	return 1;
}

=item get_errors

Returns a hashref with all keys and values.

=cut

sub get_errors {
	my $self = shift;
	return $self->{-errors};
}

=item append (EXCEPTION)

Appends a Exception to this Exception.

=cut

sub append {
	my $self = shift;
	my $other = shift;

	return unless $other;

	for (keys %{$other->{-errors}}) {
		push @{$self->{-errors}->{$_}}, @{ $other->{-errors}->{$_} };
	}
}

1;

=back

=cut
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
