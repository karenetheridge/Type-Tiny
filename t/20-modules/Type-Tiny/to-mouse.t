=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny objects can be converted to Mouse type constraint objects.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { 'Mouse' => '1.00' };
use Test::TypeTiny;

use Type::Tiny;

my $Any = "Type::Tiny"->new(name => "Anything");
my $Int = $Any->create_child_type(
	name       => "Integer",
	constraint => sub { defined($_) and !ref($_) and $_ =~ /^[+-]?[0-9]+$/sm },
);

my $mAny = $Any->mouse_type;
my $mInt = $Int->mouse_type;

isa_ok($mAny, 'Mouse::Meta::TypeConstraint', '$mAny');
isa_ok($mInt, 'Mouse::Meta::TypeConstraint', '$mInt');
is($mInt->parent, $mAny, 'type constraint inheritance seems right');

should_pass(42, $mAny);
should_pass([], $mAny);
should_pass(42, $mInt);
should_fail([], $mInt);

done_testing;
