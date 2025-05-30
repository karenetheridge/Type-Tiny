=pod

=encoding utf-8

=head1 PURPOSE

Named parameter tests for modern Type::Params v2 API on Perl 5.8.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
	package Local::MyPackage;
	
	use strict;
	use warnings;
	
	use Types::Standard -types;
	use Type::Params -sigs;
	
	signature_for myfunc => (
		method => Object | Str,
		named  => [ arr => ArrayRef, int => Int ],
	);
	
	sub myfunc {
		my ( $self, $arg ) = @_;
		return $arg->arr->[ $arg->int ];
	}
	
	my $signature;
	sub myfunc2 {
		$signature ||= signature(
			method => 1,
			named  => [ arr => ArrayRef, int => Int ],
		);
		my ( $self, $arg ) = &$signature;
		
		return $arg->arr->[ $arg->int ];
	}
};

my $o   = bless {} => 'Local::MyPackage';
my @arr = ( 'a' .. 'z' );

is $o->myfunc( arr => \@arr, int => 2 ),  'c', 'myfunc (happy path)';
is $o->myfunc2( arr => \@arr, int => 4 ), 'e', 'myfunc2 (happy path)';

{
	my $e = exception {
		$o->myfunc( arr => \@arr, int => undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc (type exception)'
}

{
	my $e = exception {
		$o->myfunc2( arr => \@arr, int => undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc2 (type exception)'
}

{
	my $e = exception {
		$o->myfunc( arr => \@arr, int => 6, 'debug' );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc (param count exception)'
}

{
	my $e = exception {
		$o->myfunc2( arr => \@arr, int => 8, 'debug' );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc2 (param count exception)'
}


BEGIN {
	package Local::MyPackage2;
	
	use strict;
	use warnings;
	
	use Types::Standard -types;
	use Type::Params -sigs;
	
	signature_for test => (
		method => !!1,
		named  => [ foo => Optional, bar => Optional[Any] ],
	);
	
	sub test {
		my ( $self, $arg ) = @_;
		my $sum;
		$sum += $arg->foo if $arg->has_foo;
		$sum += $arg->bar if $arg->has_bar;
		return $sum;
	}
}

subtest 'Optional and Optional[Any] treated the same' => sub {
	my $o = bless {}, 'Local::MyPackage2';
	my $e = exception {
		is $o->test( foo => 2, bar => 5 ),      7;
		is $o->test(           bar => 5 ),      5;
		is $o->test( foo => 2           ),      2;
		is $o->test(                    ),  undef;
	};
	is $e, undef, 'No exception';
};

done_testing;
