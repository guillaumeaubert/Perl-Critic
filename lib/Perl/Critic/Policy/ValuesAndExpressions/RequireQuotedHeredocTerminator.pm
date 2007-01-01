##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 1.00;

#-----------------------------------------------------------------------------

my $heredoc_rx = qr/ \A << ["|'] .* ['|"] \z /x;
my $desc       = q{Heredoc terminator must be quoted};
my $expl       = [ 62 ];

#-----------------------------------------------------------------------------

sub policy_parameters { return() }
sub default_severity { return $SEVERITY_MEDIUM      }
sub default_themes   { return qw(core pbp maintenance)    }
sub applies_to       { return 'PPI::Token::HereDoc' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem !~ $heredoc_rx ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator

=head1 DESCRIPTION

Putting single or double-quotes around your HEREDOC terminator make it obvious
to the reader whether the content is going to be interpolated or not.

  print <<END_MESSAGE;    #not ok
  Hello World
  END_MESSAGE

  print <<'END_MESSAGE';  #ok
  Hello World
  END_MESSAGE

  print <<"END_MESSAGE";  #ok
  $greeting
  END_MESSAGE

=head1 SEE ALSO 

L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
