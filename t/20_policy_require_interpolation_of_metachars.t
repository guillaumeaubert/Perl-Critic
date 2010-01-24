#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw< pcritique >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.105_01';

#-----------------------------------------------------------------------------

plan tests => 2;

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

# This is in addition to the regular .run file.
my $policy = 'ValuesAndExpressions::RequireInterpolationOfMetachars';
my $has_email_address = eval {require Email::Address};

#-----------------------------------------------------------------------------

my $code = <<'END_PERL';

$simple  = 'me@foo.bar';
$complex = q{don-quixote@man-from.lamancha.org};

END_PERL

my $result = pcritique($policy, \$code);
is(
    $result,
    $has_email_address ? 0 : 2,
    "$policy exempts things that look like email addresses if Email::Address is installed.",
);


$code = <<'END_PERL';

$simple  = 'Email: me@foo.bar';
$complex = q{"don-quixote@man-from.lamancha.org" is my address};
send_email_to ('foo@bar.com', ...);

END_PERL

$result = pcritique($policy, \$code);
is(
    $result,
    $has_email_address ? 0 : 3,
    "$policy exempts things email addresses in the middle of larger strings if Email::Address is installed.",
);


#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
