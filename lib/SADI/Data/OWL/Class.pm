#-----------------------------------------------------------------
# SADI::Data::OWL::Class
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Class.pm,v 1.3 2009-11-13 18:16:00 ubuntu Exp $
#-----------------------------------------------------------------
package SADI::Data::OWL::Class;
use base ("SADI::Base");
use strict;

# imports
use RDF::Core::Statement;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

SADI::Data::OWL::Class

=head1 SYNOPSIS

 use SADI::Data::OWL::Class;

 # create a sadi owl class 
 my $data = SADI::Data::OWL::Class->new ();


=head1 DESCRIPTION

An object representing an OWL class

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See SADI::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<SADI::Base>. Here just a list of them:

=over

=item B<type> a URI that describes the type of this clas

=item B<value> a URI to an individual of this class (same as uri, e.g. if you set this, you set value too)

=item B<uri> a URI to an individual of this class (same as value, e.g. if you set this, you set uri too)

=item B<statements> an array of RDF::Core::Statement objects describing the relationships in this class. Most users need not worry about this method.

=back

=cut

{
	my %_allowed = (
		type  => { type => SADI::Base->STRING },
		# value and uri are synonyms here
		value => {
			type => SADI::Base->STRING,
			post => sub {
				my $self = shift;
				$self->{uri} = $self->value;
			  }
		},
		# value and uri are synonyms here
		uri => {
			type => SADI::Base->STRING,
			post => sub {
				my $self = shift;
				$self->{value} = $self->uri;
			  }
		},
		statements => { type => 'RDF::Core::Statement', is_array => 1 },
		# used internally / set during _get_statements
		subject => => { type => 'RDF::Core::Resource' },
		
	);

	sub _accessible {
		my ( $self, $attr ) = @_;
		exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
	}

	sub _attr_prop {
		my ( $self, $attr_name, $prop_name ) = @_;
		my $attr = $_allowed{$attr_name};
		return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
		return $self->SUPER::_attr_prop( $attr_name, $prop_name );
	}
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
	my ($self) = shift;
	$self->SUPER::init();
	$self->statements( [] );
}

#-------------------------------------------------------------------
# get all RDF::Core::Statements for this thing (array_ref)
#-------------------------------------------------------------------
sub _get_statements {
}
1;
__END__
