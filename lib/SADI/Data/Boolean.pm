#-----------------------------------------------------------------
# SADI::Data::Boolean
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Boolean.pm,v 1.3 2009-09-08 15:20:23 ubuntu Exp $
#-----------------------------------------------------------------

package SADI::Data::Boolean;
use base ("SADI::Data::Object");
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

SADI::Data::Boolean - A primite SADI data type for booleans

=head1 SYNOPSIS

 use SADI::Data::Boolean;

 # create a SADI Boolean with initial value of true
 my $data = SADI::Data::Boolean->new ( value=>'true' );
 my $data = SADI::Data::Boolean->new ('true');
 my $data = SADI::Data::Boolean->new ();
 
 # change the value to false
 $data->value ('false');

 # get the value
 print $data->value;

=head1 DESCRIPTION
	
An object representing a Boolan.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See SADI::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<SADI::Base>. Here just a list of them (additionally
to the attributes from the parent classes)

=over

=item B<value>

A value of this datatype. Must be a boolean (defaults to 1).

=back

=cut

{
    my %_allowed =
	(
	 value  => {type => SADI::Base->BOOLEAN},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->primitive ('yes');
    $self->value(1);
}

sub _express_value {
    shift;
    my ($value) = shift;
    $value ? 'true' : 'false';
}


1;
__END__
