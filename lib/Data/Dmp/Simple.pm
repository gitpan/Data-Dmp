package Data::Dmp::Simple;

our $DATE = '2014-12-28'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp ();
use Scalar::Util qw(looks_like_number blessed reftype refaddr);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dd dmp);

# for when dealing with circular refs
our %_seen_refaddrs;
our %_subscripts;

*_double_quote = \&Data::Dmp::_double_quote;

sub _dump {
    my ($val, $subscript) = @_;

    my $ref = ref($val);
    if ($ref eq '') {
        if (!defined($val)) {
            return "undef";
        } elsif (looks_like_number($val)) {
            return $val;
        } else {
            return _double_quote($val);
        }
    }
    my $refaddr = refaddr($val);
    $_subscripts{$refaddr} //= $subscript;
    if ($_seen_refaddrs{$refaddr}++) {
        return "...";
    }

    my $class;
    if (blessed $val) {
        $class = $ref;
        $ref = reftype($val);
    }

    my $res;
    if ($ref eq 'ARRAY') {
        $res = "[";
        my $i = 0;
        for (@$val) {
            $res .= ", " if $i;
            $res .= _dump($_, "$subscript\[$i]");
            $i++;
        }
        $res .= "]";
    } elsif ($ref eq 'HASH') {
        $res = "{";
        my $i = 0;
        for (sort keys %$val) {
            $res .= ", " if $i++;
            my $k = /\W/ ? _double_quote($_) : $_;
            my $v = _dump($val->{$_}, "$subscript\{$k}");
            $res .= "$k=>$v";
        }
        $res .= "}";
    } elsif ($ref eq 'SCALAR') {
        $res = "\\"._dump($$val, $subscript);
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $subscript);
    } else {
        die "Sorry, I can't dump $val (ref=$ref) yet";
    }

    $res = "bless($res, "._double_quote($class).")" if defined($class);
    $res;
}

our $_is_dd;
sub _dd_or_dmp {
    local %_seen_refaddrs;
    local %_subscripts;

    my $res;
    if (@_ > 1) {
        $res = "(" . join(", ", map {_dump($_, '')} @_) . ")";
    } else {
        $res = _dump($_[0], '');
    }

    if ($_is_dd) {
        say $res;
        return @_;
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dmp(@_) }
sub dmp { goto &_dd_or_dmp }

1;
# ABSTRACT: Dump Perl data structures (simpler version)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dmp::Simple - Dump Perl data structures (simpler version)

=head1 VERSION

This document describes version 0.05 of Data::Dmp::Simple (from Perl distribution Data-Dmp), released on 2014-12-28.

=head1 SYNOPSIS

 use Data::Dmp::Simple; # exports dd() and dmp()
 my $data = [1, 2]; push @$data, $data; # circular
 dd $data; # => "[1, 2, ...]"

=head1 DESCRIPTION

This module is like L<Data::Dmp> except it does I<not> necessarily produce a
valid Perl code. In the case of circular references, it just dumps as C<"...">
(like in Python or Ruby).

=head1 FUNCTIONS

=head2 dd($data, ...) => $data ...

Exported by default. Like Data::Dump's dd, print one or more data to STDOUT.
Unlike Data::Dump's dd, it I<always> prints and return I<the original data>
(like L<XXX>), making it convenient to insert into expressions.

=head2 dmp($data, ...) => $str

Exported by default. Return dump result as string.

=head1 SEE ALSO

L<Data::Dmp>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
