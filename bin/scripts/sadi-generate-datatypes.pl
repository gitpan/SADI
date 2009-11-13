#!/usr/bin/perl -w
#
# Generate perl modules from OWL files.
#
# $Id: sadi-generate-datatypes.pl,v 1.47 2009-11-13 17:53:27 ubuntu Exp $
# Contact: Edward Kawas <edward.kawas+SADI@gmail.com>
# -----------------------------------------------------------
# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_u $opt_d $opt_v $opt_s $opt_F/;
getopts('hudvsF');

# usage
if ( &check_odo() or $opt_h or @ARGV == 0 ) {
	print STDOUT <<'END_OF_USAGE';
Generate perl modules from OWL files.
Usage: [-vds] owl-class-file
       [-vds] -u owl-class-url

    -u ... owl is from url
    -s ... show generated code on STDOUT
           (no file is created, disabled when no data type name given)
    
    -v ... verbose
    -d ... debug
    -h ... help

Note: This script requires that the PERL module ODO, from IBM Semantic Layered,
      Research Platform be installed on your workstation!

END_OF_USAGE
	exit(0);
}

sub check_odo {
    eval "require ODO";
    if ($@) {
        print STDOUT "Module ODO not installed and is required for this script.\n";
        print STDOUT "Should I proceed? [n] ";
        my $tmp = <STDIN>;  $tmp =~ s/\s//g; 
        exit() unless $tmp =~ /y/i;
    }
}

# -----------------------------------------------------------
use strict;
use warnings;

use SADI::Base;
use SADI::Utils;
use SADI::Generators::GenOWL;

use ODO::Parser::XML;
use ODO::Graph::Simple;
use ODO::Ontology::OWL::Lite;

use ODO::Graph::Simple;
use ODO::Node;

use SADI::Data::Def::ObjectProperty;
use SADI::Data::Def::DatatypeProperty;
use SADI::Data::Def::OWLClass;

use Data::Dumper;
$LOG->level('INFO')  if $opt_v;
$LOG->level('DEBUG') if $opt_d;
sub say { print @_, "\n"; }

if (@ARGV) {
	foreach my $arg (@ARGV) {
		say 'Generating perl modules for: ' . $arg;
		my $GRAPH_schema = ODO::Graph::Simple->Memory();
        my $GRAPH_source_data = ODO::Graph::Simple->Memory();
		if ($opt_u) {
			say 'Downloading OWL file';
			my $owl        = SADI::Utils::getHttpRequestByURL( $arg );
			my $statements = ODO::Parser::XML->parse($owl);
			$GRAPH_schema->add($statements);
		} else {
			say "Parsing schema file: $arg\n";
			my $statements = ODO::Parser::XML->parse_file($arg);
			$GRAPH_schema->add($statements);
		}

		# create the 'stuff'
		my $SCHEMA = ODO::Ontology::OWL::Lite->new(
                                         graph        => $GRAPH_source_data,
                                         schema_graph => $GRAPH_schema,
                                         schemaName   => '',
        );
		  
		if ($opt_s) {
			my $code = '';
			&generate_datatypes( $SCHEMA, \$code );
			say $code;
		} else {
			&generate_datatypes($SCHEMA);
		}
	}
}

sub generate_datatypes {
	my ( $lite, $code ) = @_;
    # process the object properties
	my $oProps = &_process_object_properties( $lite, $code );

	# process the datatype properties
	my $dProps = &_process_datatype_properties( $lite, $code );
	
	# process the owl classes
    &_process_classes( $lite, $oProps, $dProps, $code );
}

sub _process_object_properties {
	my ( $lite, $code ) = @_;
	my %objectProperties = %{ $lite->objectPropertyMap };
	my %oProperties;
	foreach my $key ( keys %objectProperties ) {
		my $object = $objectProperties{$key};
		next
		  unless defined $object->{'object'}
			  and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
		my $property = new SADI::Data::Def::ObjectProperty;

		# set the uri / uri sets the name too
		$property->uri($key);
		
		if ( defined $object->{'domain'} and @{ $object->{'domain'} } > 0 ) {
			my $range = shift @{ $object->{'domain'} };
			$property->domain($range);
		}
		if ( defined $object->{'range'} and @{ $object->{'range'} } ) {
			my $range = shift @{ $object->{'range'} };
			$property->range($range);
		}
		if ( defined $object->{'inheritance'} and @{ $object->{'inheritance'} } > 0 ) {
			my $parent = $object->{'inheritance'}->[0] || '';
			if ( UNIVERSAL::isa( $parent, 'ODO::Node::Resource' ) ) {
				$parent = $parent->value;
			}
			$parent = 'SADI::Data::OWL::ObjectProperty'
			  if $parent eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property';
			$property->parent($parent);
			
		}
		my $generator = SADI::Generators::GenOWL->new();
		if ( defined $code ) {
			$generator->generate_object_property(
												  property   => $property,
												  outcode    => $code,
												  force_over => $opt_F,
			);
		} else {
			$generator->generate_object_property( property   => $property,
												  force_over => $opt_F, );
		}
		$oProperties{$key} = $property;
	}
	return \%oProperties;
}

sub _process_datatype_properties {
	my ( $lite, $code ) = @_;
	my %objectProperties = %{ $lite->datatypePropertyMap };
	my %dProperties;
	foreach my $key ( keys %objectProperties ) {
		my $object = $objectProperties{$key};
		next
		  unless defined $object->{'object'}
			  and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
		my $property = new SADI::Data::Def::DatatypeProperty;

		# set the uri / uri sets the name automatically
		$property->uri($key);
		
		if ( defined $object->{'domain'} and @{ $object->{'domain'} } > 0 ) {
			my $range = shift @{ $object->{'domain'} };
			$property->domain($range);
		}
		if ( defined $object->{'range'} and @{ $object->{'range'} } ) {
			my $range = shift @{ $object->{'range'} };
			$property->range($range);
		}
		if ( defined $object->{'inheritance'} and @{ $object->{'inheritance'} } > 0 ) {
			my $parent = $object->{'inheritance'}->[0] || '';
			if ( UNIVERSAL::isa( $parent, 'ODO::Node::Resource' ) ) {
				$parent = $parent->value;
			}
			$parent = 'SADI::Data::OWL::DatatypeProperty'
			  if $parent eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property';
			$property->parent($parent);
		}
		my $generator = SADI::Generators::GenOWL->new();
		if ( defined $code ) {
			$generator->generate_datatype_property(
													property   => $property,
													outcode    => $code,
													force_over => $opt_F,
			);
		} else {
			$generator->generate_datatype_property( property   => $property,
													force_over => $opt_F, );
		}
		$dProperties{$key} = $property;
	}
	return \%dProperties;
}

sub _process_classes {
	my ($lite, $oProps, $dProps, $code) = @_;
	# oProps and dProps are hash refs ...
	my %classes = %{ $lite->classMap };
    my %dProperties;
    foreach my $key ( keys %classes ) {
        my $object = $classes{$key};
        # we only process ODO Nodes
        next
          unless defined $object->{'object'}
              and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
        my $class = new SADI::Data::Def::OWLClass;

        # set the uri / this also sets the name
        $class->type($key);
        
        # process inheritance
        if ( defined $object->{'inheritance'} and @{ $object->{'inheritance'} } > 0 ) {
        	foreach my $parent (@{ $object->{'inheritance'} }) {
        		$class->add_parent($parent);           	
            }
        }
        
        # process equivalent classes - either string or ODO::EquivalentClass
        if ( defined $object->{'equivalent'} and @{ $object->{'equivalent'} } > 0 ) {
            foreach my $equivalent (@{ $object->{'equivalent'} }) {
            	if ( UNIVERSAL::isa( $equivalent, 'ODO::Ontology::OWL::Lite::Fragments::EquivalentClass' ) ) {
                    #   perl object
                    my $key = $equivalent->{'restrictionURI'};
                    if (defined $classes{$key} and defined $classes{$key}->{'object'}) {
                    	# add to parents ... this $key will be auto generated
                    	$class->add_parent($key);
                    } else {
                    	# suck in the restrictions
			            if ($dProps->{$equivalent->{'onProperty'}}) {
			            	my $dp = $dProps->{$equivalent->{'onProperty'}};
			                $class->add_datatype_properties($dp);
			            } else {
			                my $op = $oProps->{$equivalent->{'onProperty'}};
			                $class->add_object_properties($op);
			            }
			            
                    }
                } else {
                    # string
                    my $key = $equivalent;
                    if (defined $classes{$key} and defined $classes{$key}->{'object'}) {
                        # add to parents ... this $key will be auto generated
                        $class->add_parent($key);
                    } else {
                        # TODO FIX suck in the restrictions
                        print STDERR "equivalent(else->else):->$key\n";
                        foreach my $restrict (@{ $object->{'restrictions'} }){
                            if ($dProps->{$restrict->{'onProperty'}}) {
                                my $dp = $dProps->{$restrict->{'onProperty'}};
                                $class->add_datatype_properties($dp);
                            } else {
                                my $op = $oProps->{$restrict->{'onProperty'}};
                                $class->add_object_properties($op);
                            }
                        }
                    }
                }
            }
        }
        
        # TODO process intersections - read in the equivalent classes and suck out their attributes ... put them on this class
        if ( defined $object->{'intersections'} 
            and @ { $object->{'intersections'}->{'classes'} } > 0 
            or @ { $object->{'intersections'}->{'restrictions'} } > 0) {
            	foreach my $restrict (@{ $object->{'intersections'}->{'restrictions'} }){
            		if ($dProps->{$restrict->{'onProperty'}}) {
                        my $dp = $dProps->{$restrict->{'onProperty'}};
                        # TODO add someValuesFrom, allValuesFrom to inheritance
                        
                        $class->add_datatype_properties($dp);
                    } else {
                        my $op = $oProps->{$restrict->{'onProperty'}};
                        $class->add_object_properties($op);
                    }
            	}
            	foreach my $iClass (@{ $object->{'intersections'}->{'classes'} }){
                    $class->add_parent($iClass);
                }
        }
        # TODO process the restriction
        if ( defined $object->{'restrictions'} and @ { $object->{'restrictions'} } ) {
            foreach my $restrict (@{ $object->{'restrictions'} }){
            	next unless defined $restrict->{'onProperty'};
            	if ($dProps->{$restrict->{'onProperty'}}) {
            		my $dp = $dProps->{$restrict->{'onProperty'}};
            		$class->add_datatype_properties($dp);
            	} elsif ($oProps->{$restrict->{'onProperty'}}) {
            		my $op = $oProps->{$restrict->{'onProperty'}};
            		$class->add_object_properties($op);
            	} elsif ($oProps->{$restrict->{'restrictionURI'}}) {
            		# FIXME hack ... 
                    my $op = $oProps->{$restrict->{'restrictionURI'}};
                    $class->add_parent($op) if defined $classes{$restrict->{'restrictionURI'}};
                }
            }
        }
        #print Dumper($class) ;
        my $generator = SADI::Generators::GenOWL->new();
        if ( defined $code ) {
            $generator->generate_class(
                class   => $class,
                outcode    => $code,
                force_over => $opt_F,
            );
        } else {
            $generator->generate_class( 
                class   => $class,
                force_over => $opt_F, );
        }
    }
}

say 'Done.';
__END__
