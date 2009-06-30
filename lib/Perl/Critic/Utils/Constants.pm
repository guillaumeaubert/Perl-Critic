##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::Constants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ $EMPTY hashify };

use base 'Exporter';

our $VERSION = '1.099_002';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    $PROFILE_STRICTNESS_WARN
    $PROFILE_STRICTNESS_FATAL
    $PROFILE_STRICTNESS_QUIET
    $PROFILE_STRICTNESS_DEFAULT
    %PROFILE_STRICTNESSES
    $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
    $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
    $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
    $DOCUMENT_TYPE_SCRIPT
    $DOCUMENT_TYPE_MODULE
    $DOCUMENT_TYPE_AUTO
    %DOCUMENT_TYPES
};

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    profile_strictness => [
        qw{
            $PROFILE_STRICTNESS_WARN
            $PROFILE_STRICTNESS_FATAL
            $PROFILE_STRICTNESS_QUIET
            $PROFILE_STRICTNESS_DEFAULT
            %PROFILE_STRICTNESSES
        }
    ],
    color_severity  => [
        qw{
            $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
            $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
            $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
        }
    ],
    document_type => [
        qw{
            $DOCUMENT_TYPE_SCRIPT
            $DOCUMENT_TYPE_MODULE
            $DOCUMENT_TYPE_AUTO
            %DOCUMENT_TYPES
        }
    ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar our $PROFILE_STRICTNESS_WARN    => 'warn';
Readonly::Scalar our $PROFILE_STRICTNESS_FATAL   => 'fatal';
Readonly::Scalar our $PROFILE_STRICTNESS_QUIET   => 'quiet';
Readonly::Scalar our $PROFILE_STRICTNESS_DEFAULT => $PROFILE_STRICTNESS_WARN;

Readonly::Hash our %PROFILE_STRICTNESSES =>
    hashify(
        $PROFILE_STRICTNESS_WARN,
        $PROFILE_STRICTNESS_FATAL,
        $PROFILE_STRICTNESS_QUIET,
    );

Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT    => 'bold red';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT       => 'magenta';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT     => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOW_DEFAULT        => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT     => $EMPTY;

Readonly::Scalar our $DOCUMENT_TYPE_SCRIPT  => 'script';
Readonly::Scalar our $DOCUMENT_TYPE_MODULE  => 'module';
Readonly::Scalar our $DOCUMENT_TYPE_AUTO    => 'auto';

Readonly::Hash our %DOCUMENT_TYPES =>
    hashify(
        $DOCUMENT_TYPE_SCRIPT,
        $DOCUMENT_TYPE_MODULE,
        $DOCUMENT_TYPE_AUTO,
    );

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::Constants - Global constants.


=head1 DESCRIPTION

Defines commonly used constants for L<Perl::Critic|Perl::Critic>.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE CONSTANTS

=over

=item C<$PROFILE_STRICTNESS_WARN>

=item C<$PROFILE_STRICTNESS_FATAL>

=item C<$PROFILE_STRICTNESS_QUIET>

=item C<$PROFILE_STRICTNESS_DEFAULT>

=item C<%PROFILE_STRICTNESSES>

Valid values for the L<perlcritic/"-profile-strictness"> option.
Determines whether recoverable problems found in a profile file appear
as warnings, are fatal, or are ignored.
C<$PROFILE_STRICTNESS_DEFAULT> is set to C<$PROFILE_STRICTNESS_WARN>.
Importable via the C<:profile_strictness> tag.


=item C<$PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT>

Default for the -color-severity-highest option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_HIGH_DEFAULT>

Default for the -color-severity-high option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT>

Default for the -color-severity-medium option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_LOW_DEFAULT>

Default for the -color-severity-low option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT>

Default for the -color-severity-lowest option. Importable via the
C<:color_severity> tag.

=item C<$DOCUMENT_TYPE_SCRIPT>

The document type representing a script. Importable via the C<:document_types>
tag.

=item C<$DOCUMENT_TYPE_MODULE>

The document type representing a module. Importable via the C<:document_types>
tag.

=item C<$DOCUMENT_TYPE_AUTO>

The option value specifying that Perl::Critic is to determine document types
based on their file names and contents. Importable via the C<:document_types>
tag.

=item C<%DOCUMENT_TYPES>

Valid values for the L<perlcritic/"-document-types"> option.

=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
