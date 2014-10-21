package Test::Base::Less;
use strict;
use warnings;
use utf8;

use parent qw/Test::Builder::Module Exporter/;
use Test::More;
use Data::Section::TestBase ();
use Carp ();

our @EXPORT = (@Test::More::EXPORT, qw/filters blocks register_filter/);

our %FILTER_MAP;
our %FILTERS;

sub register_filter($&) {
    my ($name, $code) = @_;
    $FILTERS{$name} = $code;
}

sub filters($) {
    my $data = shift;
    for my $key (keys %$data) {
        $FILTER_MAP{$key} ||= [];
        push @{$FILTER_MAP{$key}}, @{$data->{$key}};
    }
    return;
}

sub blocks() {
    my $sec = Data::Section::TestBase->new(package => scalar(caller));
    my @blocks = $sec->blocks();
    for my $block (@blocks) {
        for my $section_name ($block->get_section_names) {
            my @data = $block->get_section($section_name);
            if (my $filter_names = $FILTER_MAP{$section_name}) {
                for my $filter_name (@$filter_names) {
                    my $filter = $FILTERS{$filter_name};
                    unless ($filter) {
                        Carp::croak "Unknown filter name: $filter";
                    }
                    @data = $filter->(@data);
                }
            }
            $block->set_section($section_name => @data);
        }
    }
    return @blocks;
}

package Test::Base::Less::Filter;

Test::Base::Less::register_filter(eval => \&_eval);

sub _eval {
    my $src = shift;
    no warnings;
    my @return = CORE::eval $src;
    return $@ if $@;
    return @return;
}

Test::Base::Less::register_filter(chomp => \&_chomp);
sub _chomp {
    map { CORE::chomp; $_ } @_;
}

1;
__END__

=head1 NAME

Test::Base::Lite - Limited version of Test::Base.

=head1 SYNOPSIS

    use Test::Base::Less;

    filters {
        input => [qw/eval/],
    };

    for my $block (blocks) {
        is($block->input, $block->expected);
    }
    done_testing;

    __DATA__

    ===
    --- input: 4*2
    --- expected: 8

=head1 DESCRIPTION

This is a less clever version of Test::Base.

=head1 FUNCTIONS

This module exports all Test::More's exportable functions, and following functions:

=over 4

=item filters(+{ } : HashRef);

    filters {
        input => [qw/eval/],
    };

Set a filter for the section name.

=item blocks()

Get a list of Text::TestBase::Block as filtered.

=item register_filter($name: Str, $code: CodeRef)

Register a filter for $name using $code.

=back

=head1 DEFAULT FILTERS

This module provides only few filters. If you want to add more filters, pull-reqs welcome.
(I only merge a patch using no dependend modules)

=over 4

=item eval

eval() the code.

=item chomp

chomp() the arguments.

=back
