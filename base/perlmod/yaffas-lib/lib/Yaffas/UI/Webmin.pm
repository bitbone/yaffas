package Yaffas::UI::Webmin;

use strict;
use warnings;

use Yaffas::Constant;
use Yaffas::File::Config;

=head1 NAME

Yaffas::UI::Webmin - Our webmin functions

=head1 FUNCTION

=over

=item get_category_name ( $main::module_info{category}, $main::gconfig{product} )

B<Dirty Hack> sorry, didnt want to include the web-lib.pl. so give me pls these 2 informations.

This returns the real name of the current category, but it
doesn't work for translated modules names (e.g. net -> Netzwerk -> Network)
It returns undef on error.

maybe this should be done bie Yaffas::Conf, since it I<only> handles a simple config file?

=cut

sub get_category_name ($$) {
    my $name = shift;
    my $product = shift;
    my %catnames;
    local $_;

    if (open FH, "<", "/etc/$product/webmin.catnames") {
        while (<FH>) {
            my($n, $v) = split /=/, $_, 2;
            if ($n eq $name) {
                return $v;
            }
        }
        return undef;
    } else {
        return undef;
    }
}

=item lang get_lang_name (void)

returns the curretn active language

=cut

sub get_lang_name () {
	my $bkcfgfile;
	my $lang;

	if ($main::gconfig{product} eq "webmin") {
		return $main::gconfig{lang} if defined $main::gconfig{lang};
	} else {
		return $main::gconfig{"lang_".$ENV{REMOTE_USER}} if defined $main::gconfig{"lang_".$ENV{REMOTE_USER}};
		return $main::gconfig{lang} if defined $main::gconfig{lang};
	}
	return "en";
}

=item get_lang ( MODULE )

This reads the language file of the webmin/usermin MODULE. therefor it looks in your /etc/webmin/config
to determine which language you're using.
Returns a Hash for all entries, or undef on error.

=cut

sub get_lang ($) {
	my $webmin_module = shift;
	return undef unless defined $webmin_module;

	my $lang = get_lang_name();
	my $langfile;
	my $glob_langfile;

	if (defined $lang && -e Yaffas::Constant::DIR->{webmin}."$webmin_module/lang/$lang" ) {
		$langfile = Yaffas::Constant::DIR->{webmin}.$webmin_module . "/lang/$lang";
		$glob_langfile = Yaffas::Constant::DIR->{webmin}."lang/$lang";
	} else {
		$langfile = Yaffas::Constant::DIR->{webmin}.$webmin_module . "/lang/en";
		$glob_langfile = Yaffas::Constant::DIR->{webmin}."lang/en";
	}

	my %ret;

	if ( -r $glob_langfile ) {
		my $lg = Yaffas::File::Config->new($glob_langfile, {-SplitPolicy => 'equalsign'});
		%ret = $lg->get_cfg->getall();
	} else {
		warn "can't open $glob_langfile";
		return undef;
	}

	if ( -r $langfile ) {
		my $lg = Yaffas::File::Config->new($langfile, {-SplitPolicy => 'equalsign'});
		%ret = (%ret, $lg->get_cfg->getall());
	} else {
		warn "can't open $langfile";
		return undef;
	}

	return %ret;
}

=item load_modules_lang ()

Loads language files for all loaded bitkit modules.

=cut

sub load_modules_lang () {
	my $lang = get_lang_name();
	foreach (keys %INC) {
		if (/^(Yaffas.*)\.pm$/) {
			my $file = Yaffas::Constant::DIR->{module_lang}.$1."/".$lang;
			if (-r $file) {
				my $lg = Yaffas::File::Config->new($file, {-SplitPolicy => 'equalsign'});
				%main::text = (%main::text, $lg->get_cfg->getall());
			}
		}
	}
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
