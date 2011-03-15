#!/usr/bin/perl
package Yaffas::Conf;

use warnings;
use strict;

sub BEGIN {
	our (@ISA, @EXPORT_OK);
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(&DEFAULT);
}

use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Item;

use XML::LibXML;

use Yaffas::Product;
use Yaffas::Constant;

use Yaffas::Conf::Section;
use Yaffas::Conf::ADS_Conf;

use Yaffas::Exception;
use Error qw(:try);

use Exporter;
use MIME::Base64;
use Storable;
use Data::Dumper;

our $TESTDIR = "";

sub DEFAULT {Yaffas::Constant::FILE->{bitkit_config}};

our $DEBUG = 1;

=pod

=head1 NAME

Yaffas::Conf is a interface to the bitkit configuration file

=head1 SYNOPSIS

 use Yaffas::Conf
 use Yaffas::Conf::Function;

 my $config = Yaffas::Conf->new();
 my $section1 = $config->section("important section");
 my $section2 = $config->section("notsoimportant");

 $section2->add_require("important section");

 my $function1 = Yaffas::Conf::Function->new("veryimportant", "Yaffas::Module::Important::do_stuff");
 $function1->add_param({type => "scalar", param => "foo"});

 my $function2 = Yaffas::Conf::Function->new("funny things", "Yaffas::Module::Fun::do_stuff");
 $function2->add_param({type => "scalar", param => "bar"});

 ### note that you can make various choices for the type key:
 # scalar:	use this if you want to store a single scalar value.
 # mime:	use this if you want to store a file or binary values.
 # hash:	use this if you want to store a hash or array _reference_.

 $section1->add_func($function1);
 $section2->add_func($function2);

 $config->save();

=head1 DESCRIPTION

Yaffas::Conf  --todo--

=head1 CONSTANTS

=over

=item DEFAULT

this is the DEFAULT config file.

=back

=head1 FUNCTIONS

=over

=item new ( [FILE] )

if FILE is ommited, the DEFAULT is used

=cut

sub new {
    my $package = shift;
    my $file = shift;

    if ($file)
	{
		open TFILE, "<", $TESTDIR.$file or return undef;
		my @test = <TFILE>;
		close TFILE;
		return undef if ( ! grep(/<config>/, @test) );
	}

	$file = $TESTDIR.DEFAULT() unless $file;

    my $self = {};
    my ($parser, $xml, $doc);

    $self->{file} = $file;
    $xml = _read_file($file);

    $parser = XML::LibXML->new();
#    $parser->validation(1);

    if ($xml) {
        $doc = $parser->parse_string($xml);
    }else {
		# utf8 needed? utf8 is default
		# $doc = XML::LibXML::Document->createDocument( "1.0");
        $doc = XML::LibXML::Document->createDocument( "1.0", "ISO-8859-1");
		my $root = XML::LibXML::Element->new("config");
        $doc->setDocumentElement($root);
    }

    $self->{doc} = $doc;
	$self->{Errors} = Yaffas::Exception->new();

    bless $self, $package;
    return $self;
}


=item delete_section ( NAME )

deletes the section if exists.

=cut

sub delete_section {
    my $self = shift;
    my $name = shift;

    my $ret = Yaffas::Conf::Section->new($self, $name);
	$ret->delete();
    return $ret;
}

=item section ( NAME )

returns the Yaffas::Conf::Section. The section will be created
if it doesn't exist yet

=cut

sub section {
    my $self = shift;
    my $name = shift;

    my $ret = Yaffas::Conf::Section->new($self, $name);
    return $ret;
}

=item save ()

=item write ()

writes the config back to file

=cut

sub save {
    my $self = shift;
    my $doc  = $self->{doc};
    my $file = $self->{file};
    $doc->toFile($file, 0) or return undef;
    1;
}

*write = *save;

sub _read_file {
    my $file = shift;
    my $xml;

    return undef unless -f $file;

    local $/; # slurp
    undef $/;

    open FILE, "<", $file or return undef;
    $xml = <FILE>;
    close FILE;

    return $xml;
}


=item test_products

This tests if the current xml conaints only the installed bitkit products and nothing less.

=cut

sub test_products {
	my $self = shift;
	my $root = $self->{doc}->documentElement();
	my @node = $root->getChildrenByTagName("section");
	for (@node) {
		my $id = $_->getAttribute("id");
		next unless $id eq "product_version";
		return _test_products( _extract_comment($_) );
		last;
	}
}

=item eicon_defined

This tests if the current xml conaints config for eicon or avm type.

=cut


sub eicon_defined {
        my $self = shift;
        my $root = $self->{doc}->documentElement();
        my @node = $root->getChildrenByTagName("section");
        if($#node == 0) {
		throw Yaffas::Exception("err_conf_file");
	}
	for (@node) {
                my $id = $_->getAttribute("id");
                next unless $id eq "divas_cfg";
               	return 1;
        }
	return undef;
}

sub _test_products($) {
	my $hash = shift;
	for my $prod (keys %{$hash}) {
		my $value = $hash->{$prod};
		## dirty hack. downwards compatible
		if($prod eq "base"){ $prod = "framework" };
		my $c = Yaffas::Product::get_version_of($prod);
		return 0 unless Yaffas::Product::get_version_of($prod) >= ($value?1:0); ## change me in bug #911
	}
	1;
}


# gets a $node tests if it is a comment
# and returns the comment hashref
sub _extract_comment($){
	my $parent = shift;
	my $hash = {};
	my @node = $parent->getChildrenByTagName("comment");
	for (@node) {
		my $key = $_->getAttribute("key");
		my $value = $_->textContent();
		$hash->{ decode_base64($key) } = decode_base64($value);
	}
	return $hash;
}

=item test_faxtype

This tests if the current xml conaints config for eicon or avm type.

=cut

sub test_faxtype {
	my $self = shift;
	my $root = $self->{doc}->documentElement();
	my @node = $root->getChildrenByTagName("section");
	for (@node) {
		my $id = $_->getAttribute("id");
		next unless $id eq "faxconf_general";
		my $faxtype = _extract_comment($_);
		return  $faxtype->{"faxtype"};

	}
}

=item apply

Applys the Config file to the system. That means the Functions of the Configfile will be executed
with its parameters ...

=cut

sub apply {
	my $self = shift;
	my $force = shift;

	my $root = $self->{doc}->documentElement();

	# befüllen
	my $list = Yaffas::Conf::ADS_Conf->new();
	my @node = $root->getChildrenByTagName("section");
	for (@node) {
		my $id = $_->getAttribute("id");
		my @req = $_->getChildrenByTagName("requires");
		my @req_name = map {$_->textContent()} @req;
		my $item = Algorithm::Dependency::Item->new($id, @req_name);
		$list->add_item($item);
	}

	my $ado = Algorithm::Dependency::Ordered->new(
													source => $list,
													ignore_orphans => 1, ## only for testing
												   );

	unless (defined $ado ) {
		die "$!";
	}

	my $sched_list = $ado->schedule_all();

	# process all items of @$sched;
	for (@$sched_list) {
		_process($self,$_);
	}
}

sub _process($$) {

	if ($DEBUG) {
		open(DEBUG_FH, ">>", "/tmp/conf.pm.debug");
	}
	my $self = shift;
	my $section_id = shift;

	my $section_to_apply;

	my $root = $self->{doc}->documentElement();
	my @node = $root->getChildrenByTagName("section");

	# find correct section to apply.
	for (@node) {
		if ($_->getAttribute("id") eq $section_id) {
			$section_to_apply = $_;
			last;
		}
	}

	return undef unless $section_to_apply;

	@node = $section_to_apply->getChildrenByTagName("function");

	print DEBUG_FH "\n" . localtime(time()) ." applying settings of $section_to_apply to the system\n" if $DEBUG;

	for (@node) {
		# get subroutine.
		my $subroutine = (($_->getChildrenByTagName("name"))[0])->textContent();

		# extract the package.
		my $package = $subroutine;
		$package =~ s/::[^:]+$//;

		# get its parameters.
		my @param;
		my @node = $_->getChildrenByTagName("param");

		print DEBUG_FH localtime(time()) . " function: $subroutine\n" if $DEBUG;

		# convert types
		if (@node) {

			@param = map {
				my $type = $_->getAttribute("type");
				my $param = $_->textContent();

				{ type => $type, param => $param }
			} @node;


			@param = _decode($self, @param);

			if ($DEBUG) {
				print DEBUG_FH localtime(time()) . " converted parameters:\n";
				print DEBUG_FH map { "\t" . Dumper($_) . "\n" } @param;
			}

			if ($self->{convert_error}) {
				$self->{Errors}->add("err_parse", "Parameter Error in configfile");
				next;
			}

		}

		# falls einer ein Signal handler für DIE installiert hat, so möchte er sicher nicht,
		# das dieser aufgerufen wird, wenn hier das config geladen wird.
		#local $SIG{__DIE__};

		print DEBUG_FH localtime(time()) . " executing now!!\n" if $DEBUG;
		try {
			eval "use $package";
			die $@ if $@;
			no strict "refs";
			&{$subroutine}( @param );
			use strict;

		} catch Yaffas::Exception with {
			my $e = shift;
			print DEBUG_FH localtime(time()) . " Exception thrown: " . Dumper ($e) . "\n"  if $DEBUG;
			$self->{Errors}->append($e);
		} otherwise {
			print DEBUG_FH localtime(time()) . " Error msg: $@\n" if $DEBUG;
			print DEBUG_FH localtime(time()), @_ if $DEBUG;
			$self->{Errors}->add("err_syntax", shift);
		};
	}
	if ($DEBUG) {
		close DEBUG_FH;
	}
}

sub _push (\@$$) {
	my $ref = shift;
	my $type = shift;
	my $param = shift;
	push @$ref, {type => $type , param => $param};
}

sub _encode {
	my $self = shift;
	my @param = @_;
	my @rv;

	foreach (@param) {
		my $type = $_->{type};
		my $param = $_->{param};

# 		if ($type eq "scalar" ) {
# 			_push @rv, $type, $param;

# alterntavie type handling!
#		}elsif ($tpye eq "storable") {
#		}elsif ($tpye eq "gzip") {
#		}elsif ($tpye eq "bzip2") {
#		}elsif ($tpye eq "rsa") {

		if ($type eq "hash" or $type eq "array") {
			my $dumper = Dumper $param;
			_push @rv, $type, encode_base64($dumper);

		} elsif ($type eq "mime" || $type eq "scalar") {
			_push @rv, $type, encode_base64($param);

		}else {
			$self->{convert_error} = 1;
			return undef; #huh!?!
		}

	}
	return @rv;

}

sub _decode {
	my $self = shift;
	my @param = @_;
	my @rv;

	foreach (@param) {
		my $type = $_->{type};
		my $param = $_->{param};

# 		if ($type eq "scalar" ) {
# 			push @rv,  $param;

# alterntavie type handling!
#		}elsif ($tpye eq "storable") {
#		}elsif ($tpye eq "gzip") {
#		}elsif ($tpye eq "bzip2") {
#		}elsif ($tpye eq "rsa") {

		if ($type eq "hash" or $type eq "array") {
			my $dumper = decode_base64($param);
			my $eval = eval "my ". $dumper;
			push @rv, @{$eval} if (ref $eval eq "ARRAY");
			push @rv, %{$eval} if (ref $eval eq "HASH");

		} elsif ($type eq "mime" || $type eq "scalar") {
			push @rv, decode_base64($param);

		}else {
			$self->{convert_error} = 1;
			return undef; #huh!?!
		}

	}
	return @rv;
}

=item B<confdumper( [ SECTION [,FUNCTION] ] )>

This routine returns the requested information as a hashref.
If you don't pass the optional parameters, it will return 
a complete dump of bitkit.xml

=cut

sub confdumper
{
	my ($self, $want_section, $want_function) = @_;
	
	my $root	= $self->{doc}->documentElement();
	my $ref		= {};
	
	foreach my $s ($root->getChildrenByTagName("section"))
	{
		my $section = $s->getAttribute("id");

		foreach my $f ($s->getChildrenByTagName("function"))
		{
			my $function	= (($f->getChildrenByTagName("name"))[0])->textContent();
			my $fname		= $f->getAttribute("id");
			
			next unless $function && $section;
			@{ $ref->{$section}->{$function}->{$fname} } = map 
			{
				my $type = $_->getAttribute("type");
				my $param = $_->textContent();

				{ type => $type, param => $param }
			} $f->getChildrenByTagName("param");

			@{ $ref->{$section}->{$function}->{$fname} } = _decode($self, @{ $ref->{$section}->{$function}->{$fname} });
		}
	}

	return $ref unless $want_section;
	return $ref->{$want_section} unless $want_function;
	return $ref->{$want_section}->{$want_function};
}

1;

=back

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
