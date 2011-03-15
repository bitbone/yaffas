#!/usr/bin/perl -w
package Yaffas::Conf::Section;
use strict;
use Data::Dumper;

=head1 METHODS

=cut

=over

=item new

dont use it! only for internal use.

=cut

sub delete {
	my $self = shift;
	my $id = shift;
    my ($doc, $root, $cfg, $child );

	$cfg = $self->{cfg};
	$doc = $cfg->{doc};
	$root = $doc->documentElement();
	$child = $self->{section};

	if ($child){
		# exists - so delete
		$root->removeChild($child);
	}
}

sub new {
    my $package = shift;
    my $cfg = shift;
	my $id = shift;
    my ($self, $doc, $root, $new_section );

    $self->{cfg} = $cfg;

    $doc = $cfg->{doc};
    $root = $doc->documentElement();

    ## check if section allrady exists.
    my @children = $root->getChildrenByTagName("section");
    my $child;
    foreach (@children) {
            $child = $_ if ($_->getAttribute('id') eq $id);
    }

    unless ($child) {
        ## doesnt exist jet.
        $child = XML::LibXML::Element->new("section");
        $child->setAttribute("id", $id);
        $child = $root->appendChild($child);
    }

    $self->{section} = $child;
    bless $self, $package;
    return $self;
}

=item add_comment ( COMMENT )

Adds a COMMENT to the Section, whereas COMMENt is a Yaffas::Conf::Comment object.
Returns 1 on success, repalces the comment, if ther is allreay one with the same key.

See also L<del_comment>

=cut

sub add_comment {
	my $self = shift;
	my $comment = shift; # Yaffas::Conf::Comment

	my $section_element = $self->{section};

	my @comments = $section_element->getChildrenByTagName("comment");
	my @comment_keys = map {$_->getAttribute("key")} @comments;


	del_comment($self, $comment->{key})  if( grep({$comment->{key} eq $_} @comment_keys ));

    my $new_comment_element = XML::LibXML::Element->new("comment");
    $new_comment_element->setAttribute("key", $comment->{key});
	$new_comment_element->appendText($comment->{value});
	$section_element->appendChild($new_comment_element);

	1;

}

=item del_comment ( Comment-name )

deletes a Function with the function id.

=cut

sub del_comment {
	my $self = shift;
	my $c_name = shift;

	my $section_element = $self->{section};
	my @comments = $section_element->getChildrenByTagName("comment");
	for (@comments) {
		if ($_->getAttribute("name") eq $c_name) {
			## del and return
			$section_element->removeChild($_);
			return 1;
		}
	}
	return undef;
}


=item add_func ( FUNCTION ) 

Adds FUNCTION to the Section, whereas FUNCTION is a Yaffas::Conf::Function object.
Returns 1 on success, replaces the function, if there is allready one with the same id.

See also L<del_func>

=cut

sub add_func {
    my $self = shift;
    my $func = shift; ## Yaffas::Conf::Func ref

    my $section_element = $self->{section};

	my @functions = $section_element->getChildrenByTagName("function");
	my @f_ids = map {$_->getAttribute("id")} @functions;

	del_func($self, $func->{id})  if (grep( {$func->{id} eq $_} @f_ids ));

    my $new_func_element = XML::LibXML::Element->new("function");
    $new_func_element->setAttribute("id", $func->{id});
	$section_element->appendChild($new_func_element);

	my $name_element = XML::LibXML::Element->new("name");
	$name_element->appendText($func->{name});
	$new_func_element->appendChild($name_element);


    for (@{$func->{params}}) {
		my $new_param = XML::LibXML::Element->new("param");
        $new_param->setAttribute("type", $_->{type});
        $new_param->appendText($_->{param});
        $new_func_element->appendChild($new_param);
    }
	1;
}

=item del_func ( FUNCTION-ID )

deletes a Function with the function id.

=cut

sub del_func {
	my $self = shift;
	my $f_id = shift;

	my $section_element = $self->{section};
	my @functions = $section_element->getChildrenByTagName("function");
	for (@functions) {
		if ($_->getAttribute("id") eq $f_id) {
			## del and return
			$section_element->removeChild($_);
			return 1;
		}
	}
	return undef;
}

=item del_require

deletes a requirenment.

=cut

sub del_require {
    my $self = shift;
    my @del_requirements = @_;

    my $section_element =  $self->{section};
	my @present_requirements = $section_element->getChildrenByTagName("requires");

    for my $r_node (@present_requirements) {
		if (grep {defined $_ and
				  defined $r_node and
				  defined $r_node->textContent() and 
				  $r_node->textContent() eq $_ } @del_requirements) {
			$section_element->removeChild($r_node);
		}
    }
}


=item add_require

adds a requirenment.

=cut

sub add_require {
    my $self = shift;
    my @new_requirements = @_;

    my $section_element =  $self->{section};

	my @present_requirements = $section_element->getChildrenByTagName("requires");
	@present_requirements = map {$_->textContent()} @present_requirements;


    for my $requirement (@new_requirements) {
		unless (grep { defined $_ and $_ eq $requirement } @present_requirements  ) { ## gibts schon.
			my $new_req = XML::LibXML::Element->new("requires");
			$new_req->appendText($requirement);
			$section_element->appendChild($new_req);
		}
    }
}

1;

=back

=head1 COYPRIGHT

bitbone AG Wuerzburg, 2005
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
