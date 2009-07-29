##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Document;

use 5.006001;
use strict;
use warnings;

use Carp qw< confess >;

use PPI::Document;
use PPI::Document::File;

use List::Util qw< reduce >;
use Scalar::Util qw< blessed weaken >;
use version;

use Perl::Critic::Annotation;
use Perl::Critic::Exception::Parse qw< throw_parse >;
use Perl::Critic::Utils qw < :characters shebang_line >;
use Perl::Critic::Utils::Constants qw< :document_type >;
use Perl::Critic::PPIx::Optimized;


#-----------------------------------------------------------------------------

our $VERSION = '1.099_002';

#-----------------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {  ## no critic (ProhibitAutoloading, ArgUnpacking)
    my ( $function_name ) = $AUTOLOAD =~ m/ ([^:\']+) \z /xms;
    return shift->{_doc}->$function_name(@_);
}

#-----------------------------------------------------------------------------

sub DESTROY {
    Perl::Critic::PPIx::Optimized::flush_caches();
    return;
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

#-----------------------------------------------------------------------------

sub _init { ## no critic (Subroutines::RequireArgUnpacking)

    my $self = shift;
    my %args;

    if (@_ == 1) {
        _warn_about_deprected_constructor();
        %args = (-source => shift);
    } else {
        %args = @_;
    }

    my $source_code = $args{-source};

    # $source_code can be a file name, or a reference to a
    # PPI::Document, or a reference to a scalar containing source
    # code.  In the last case, PPI handles the translation for us.

    my $doc = _is_ppi_doc( $source_code ) ? $source_code
              : ref $source_code ? PPI::Document->new($source_code)
              : PPI::Document::File->new($source_code);

    # Bail on error
    if ( not defined $doc ) {
        my $errstr   = PPI::Document::errstr();
        my $file     = ref $source_code ? undef : $source_code;
        throw_parse
            message     => qq<Can't parse code: $errstr>,
            file_name   => $file;
    }

    $self->{_doc} = $doc;
    $self->{_annotations} = [];
    $self->{_suppressed_violations} = [];
    $self->{_disabled_line_map} = {};
    $self->index_locations();
    $self->_disable_shebang_fix();
    $self->{_as_filename} = $args{'-as-filename'};
    $self->{_document_type} = $self->_compute_document_type(\%args);

    return $self;
}

#-----------------------------------------------------------------------------

sub _is_ppi_doc {
    my ($ref) = @_;
    return blessed($ref) && $ref->isa('PPI::Document');
}

#-----------------------------------------------------------------------------

sub ppi_document {
    my ($self) = @_;
    return $self->{_doc};
}

#-----------------------------------------------------------------------------

sub isa {
    my ($self, @args) = @_;
    return $self->SUPER::isa(@args)
        || ( (ref $self) && $self->{_doc} && $self->{_doc}->isa(@args) );
}

#-----------------------------------------------------------------------------

sub filename {
    my ($self) = @_;
    return $self->{_as_filename} if $self->{_as_filename};

    my $doc = $self->{_doc};
    return $doc->can('filename') ? $doc->filename() : undef;
}

#-----------------------------------------------------------------------------

sub highest_explicit_perl_version {
    my ($self) = @_;

    my $highest_explicit_perl_version =
        $self->{_highest_explicit_perl_version};

    if ( not exists $self->{_highest_explicit_perl_version} ) {
        my $includes = $self->_find_perl_version_includes();

        if ($includes) {
            # Note: this doesn't use List::Util::max() because that function
            # doesn't use the overloaded ">=" etc of a version object.  The
            # reduce() style lets version.pm take care of all comparing.
            #
            # For reference, max() ends up looking at the string converted to
            # an NV, or something like that.  An underscore like "5.005_04"
            # provokes a warning and is chopped off at "5.005" thus losing the
            # minor part from the comparison.
            #
            # An underscore "5.005_04" is supposed to mean an alpha release
            # and shouldn't be used in a perl version.  But it's shown in
            # perlfunc under "use" (as a number separator), and appears in
            # several modules supplied with perl 5.10.0 (like version.pm
            # itself!).  At any rate if version.pm can understand it then
            # that's enough for here.
            $highest_explicit_perl_version =
                reduce { $a >= $b ? $a : $b }
                map    { version->new( $_->version() ) }
                       @{$includes};
        }
        else {
            $highest_explicit_perl_version = undef;
        }

        $self->{_highest_explicit_perl_version} =
            $highest_explicit_perl_version;
    }

    return $highest_explicit_perl_version if $highest_explicit_perl_version;
    return;
}

#-----------------------------------------------------------------------------

sub process_annotations {
    my ($self) = @_;

    my @annotations = Perl::Critic::Annotation->create_annotations($self);
    $self->add_annotation(@annotations);
    return $self;
}

#-----------------------------------------------------------------------------

sub line_is_disabled_for_policy {
    my ($self, $line, $policy) = @_;
    my $policy_name = ref $policy || $policy;

    # HACK: This Policy is special.  If it is active, it cannot be
    # disabled by a "## no critic" annotation.  Rather than create a general
    # hook in Policy.pm for enabling this behavior, we chose to hack
    # it here, since this isn't the kind of thing that most policies do

    return 0 if $policy_name eq
        'Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic';

    return 1 if $self->{_disabled_line_map}->{$line}->{$policy_name};
    return 1 if $self->{_disabled_line_map}->{$line}->{ALL};
    return 0;
}

#-----------------------------------------------------------------------------

sub add_annotation {
    my ($self, @annotations) = @_;

    # Add annotation to our private map for quick lookup
    for my $annotation (@annotations) {

        my ($start, $end) = $annotation->effective_range();
        my @affected_policies = $annotation->disables_all_policies ?
            qw(ALL) : $annotation->disabled_policies();

        # TODO: Find clever way to do this with hash slices
        for my $line ($start .. $end) {
            for my $policy (@affected_policies) {
                $self->{_disabled_line_map}->{$line}->{$policy} = 1;
            }
        }
    }

    push @{ $self->{_annotations} }, @annotations;
    return $self;
}

#-----------------------------------------------------------------------------

sub annotations {
    my ($self) = @_;
    return @{ $self->{_annotations} };
}

#-----------------------------------------------------------------------------

sub add_suppressed_violation {
    my ($self, $violation) = @_;
    push @{$self->{_suppressed_violations}}, $violation;
    return $self;
}

#-----------------------------------------------------------------------------

sub suppressed_violations {
    my ($self) = @_;
    return @{ $self->{_suppressed_violations} };
}

#-----------------------------------------------------------------------------

sub document_type {
    my ($self) = @_;
    return $self->{_document_type};
}

#-----------------------------------------------------------------------------

sub is_script {
    my ($self) = @_;
    return $self->{_document_type} eq $DOCUMENT_TYPE_SCRIPT;
}

#-----------------------------------------------------------------------------

sub is_module {
    my ($self) = @_;
    return $self->{_document_type} eq $DOCUMENT_TYPE_MODULE;
}

#-----------------------------------------------------------------------------
# PRIVATE functions & methods

sub _find_perl_version_includes {
    my ($self) = @_;

    # This takes advantage of our find() method, which is
    # optimized to search for elements based on their class.
    my $includes = $self->find('PPI::Statement::Include') || [];
    my @version_includes = grep { $_->version() } @{$includes};
    return @version_includes ? \@version_includes : $EMPTY;
}

#-----------------------------------------------------------------------------

sub _disable_shebang_fix {
    my ($self) = @_;

    # When you install a script using ExtUtils::MakeMaker or Module::Build, it
    # inserts some magical code into the top of the file (just after the
    # shebang).  This code allows people to call your script using a shell,
    # like `sh my_script`.  Unfortunately, this code causes several Policy
    # violations, so we disable them as if they had "## no critic" annotations.

    my $first_stmnt = $self->schild(0) || return;

    # Different versions of MakeMaker and Build use slightly different shebang
    # fixing strings.  This matches most of the ones I've found in my own Perl
    # distribution, but it may not be bullet-proof.

    my $fixin_rx = qr<^eval 'exec .* \$0 \${1\+"\$@"}'\s*[\r\n]\s*if.+;>ms; ## no critic (ExtendedFormatting)
    if ( $first_stmnt =~ $fixin_rx ) {
        my $line = $first_stmnt->location->[0];
        $self->{_disabled_line_map}->{$line}->{ALL} = 1;
        $self->{_disabled_line_map}->{$line + 1}->{ALL} = 1;
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _compute_document_type {
    my ($self, $args) = @_;

    my $file_name = $self->filename();
    if (defined $file_name && ref $args->{'-script-extensions'} eq 'ARRAY') {
        foreach my $ext ( @{ $args->{'-script-extensions'} } ) {
            my $regex = ref $ext eq 'Regexp' ?
                $ext :
                qr{ @{[ quotemeta $ext ]} \z }smx;
            return $DOCUMENT_TYPE_SCRIPT
                if $file_name =~ m/$regex/smx;
        }
    }

    return $DOCUMENT_TYPE_SCRIPT
        if shebang_line($self);

    return $DOCUMENT_TYPE_SCRIPT
        if defined $file_name && $file_name =~ m/ [.] PL \z /smx;

    return $DOCUMENT_TYPE_MODULE;
}

#-----------------------------------------------------------------------------

sub _warn_about_deprecated_constructor {

    warnings::warnif( 'deprecated', 'Perl::Critic::Document->new($source) deprecated, use Perl::Critic::Document->new(-source => $source) instead.' ); ## no critic (RequireInterpolationOfMetachars)
        return;
}


#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords pre-caches

=head1 NAME

Perl::Critic::Document - Caching wrapper around a PPI::Document.


=head1 SYNOPSIS

    use PPI::Document;
    use Perl::Critic::Document;
    my $doc = PPI::Document->new('Foo.pm');
    $doc = Perl::Critic::Document->new(-source => $doc);
    ## Then use the instance just like a PPI::Document


=head1 DESCRIPTION

Perl::Critic does a lot of iterations over the PPI document tree via
the C<PPI::Document::find()> method.  To save some time, this class
pre-caches a lot of the common C<find()> calls in a single traversal.
Then, on subsequent requests we return the cached data.

This is implemented as a facade, where method calls are handed to the
stored C<PPI::Document> instance.


=head1 CAVEATS

This facade does not implement the overloaded operators from
L<PPI::Document|PPI::Document> (that is, the C<use overload ...>
work). Therefore, users of this facade must not rely on that syntactic
sugar.  So, for example, instead of C<my $source = "$doc";> you should
write C<my $source = $doc->content();>

Perhaps there is a CPAN module out there which implements a facade
better than we do here?


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<< new(-source => $source_code, '-as-filename' => $filename '-script-extensions' => [script_extensions]) >>

Create a new instance referencing a PPI::Document instance.  The
C<$source_code> is a required argument and it can be the name of a file, a
reference to a scalar containing actual source code, or a L<PPI::Document> or
L<PPI::Document::File>.

The following arguments are optional:

B<-as-filename> is a string that is used for the filename of the
C<$source_code>.  For exaple, if the C<$souce_code> is a scalar reference to a
string of source code or a L<PPI::Document>, then you can use -as-filename to
supply a hypothetical filename for that code (otherwise, the C<filename()>
method would return undefined).

If C<$source_code> is a L<PPI::Document::File> or a path to a file, then the
-as-filename option will cause this Perl::Critic::Document to masquarade as
the specified file, even the though the source code actually came from another
file.

In other words, the -as-filename option will always cause the C<filename()>
method to return the specified C<$filename> for this Perl::Critic::Document.  Note
that the filename specified by -as-filename will also affect whether the file
is judged to be a script or module.

B<-script-extensions> is a reference to a list of strings and/or regexps. The
strings will be made into regexps matching the end of a file name, and any
document whose file name matches one of the regexps will be considered a
script.

If -script-extensions is not specified, or if it does not determine the
document type, the document type will be 'script' if the source has a shebang
line or its file name (if any) matches C<< m/ [.] PL \z /smx >>, or 'module'
otherwise.

Be aware that the document type influences not only the value returned by the
C<document_type()> method, but also the value returned by the C<is_script()>
and C<is_module()> methods.

=back

=head1 METHODS

=over

=item C<< ppi_document() >>

Accessor for the wrapped PPI::Document instance.  Note that altering
this instance in any way can cause unpredictable failures in
Perl::Critic's subsequent analysis because some caches may fall out of
date.


=item C<< find($wanted) >>

=item C<< find_first($wanted) >>

=item C<< find_any($wanted) >>

If C<$wanted> is a simple PPI class name, then the cache is employed.
Otherwise we forward the call to the corresponding method of the
C<PPI::Document> instance.


=item C<< filename() >>

Returns the filename for the source code if applicable
(PPI::Document::File) or C<undef> otherwise (PPI::Document).


=item C<< isa( $classname ) >>

To be compatible with other modules that expect to get a
PPI::Document, the Perl::Critic::Document class masquerades as the
PPI::Document class.


=item C<< highest_explicit_perl_version() >>

Returns a L<version|version> object for the highest Perl version
requirement declared in the document via a C<use> or C<require>
statement.  Returns nothing if there is no version statement.

=item C<< process_annotations() >>

Causes this Document to scan itself and mark which lines &
policies are disabled by the C<"## no critic"> annotations.

=item C<< line_is_disabled_for_policy($line, $policy_object) >>

Returns true if the given C<$policy_object> or C<$policy_name> has
been disabled for at C<$line> in this Document.  Otherwise, returns false.

=item C<< add_annotation( $annotation ) >>

Adds an C<$annotation> object to this Document.

=item C<< annotations() >>

Returns a list containing all the L<Perl::Critic::Annotation> that
were found in this Document.

=item C<< add_suppressed_violation($violation) >>

Informs this Document that a C<$violation> was found but not reported
because it fell on a line that had been suppressed by a C<"## no critic">
annotation. Returns C<$self>.

=item C<< suppressed_violations() >>

Returns a list of references to all the L<Perl::Critic::Violation>s
that were found in this Document but were suppressed.

=item C<< document_type() >>

Returns the current value of the C<document_type> attribute. When the
C<Perl::Critic::Document> object is instantiated, it will be set based on the
value '-script-extensions' argument (if any) and/or the contents of the file
to L<Perl::Critic::Utils::Constants/"$DOCUMENT_TYPE_SCRIPT"> or
L<Perl::Critic::Utils::Constants/"$DOCUMENT_TYPE_MODULE">. See the C<new()>
documentation for the details.  This attribute exists to support
L<Perl::Critic|Perl::Critic>.

=item C<< is_script() >>

Returns a true value if the C<document_type> attribute is equal to
L<Perl::Critic::Utils::Constants/"$DOCUMENT_TYPE_SCRIPT">. Otherwise returns
false. This method exists to support L<Perl::Critic|Perl::Critic>. 

=item C<< is_module() >>

Returns a true value if the C<document_type> attribute is equal to
L<Perl::Critic::Utils::Constants/"$DOCUMENT_TYPE_MODULE">. Otherwise returns
false. This method exists to support L<Perl::Critic|Perl::Critic>. 

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
