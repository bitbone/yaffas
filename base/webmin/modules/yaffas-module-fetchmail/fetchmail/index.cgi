#!/usr/bin/perl

use Yaffas;

Yaffas::init_webmin();
require "forms.pl";

header();

show_polls();
show_edit(1);

footer();