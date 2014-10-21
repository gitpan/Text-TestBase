use strict;
use warnings;
use utf8;
use Test::Base::Less;

filters {
    input => [qw/uc/],
};

run_is input => 'expected';

done_testing;

__DATA__

===
--- input: x
--- expected: X
