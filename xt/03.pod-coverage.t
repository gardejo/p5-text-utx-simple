#!perl -T

# Devel::Cover and Attribute::Protected and Test::Pod::Coverage
# are incompatible!

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok();
