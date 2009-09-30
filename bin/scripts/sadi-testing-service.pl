#!/usr/bin/perl -w
#
# Calling a BioMoby services (with or without SOAP).
#
# $Id: sadi-testing-service.pl,v 1.8 2009-09-10 19:22:53 ubuntu Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

BEGIN {

	# some command-line options
	use Getopt::Std;
	use vars qw/ $opt_h $opt_d $opt_v $opt_l $opt_e $opt_g /;
	getopts('hdvl:e:g:C:a:');

	# usage
	if ( $opt_h or ( not $opt_e and not $opt_g and scalar @ARGV == 0) ) {
		print STDOUT <<'END_OF_USAGE';
Calling SADI services remotely or locally.

   Usage: # calling a local module representing a service
       [-vd] [-l <lib-location>] <package-name> [<input-file>]

       # calling a real service, using HTTP
       -e <service-url> <service-name> [<input-file>]

       # calling a real service to obtain service interface
       -g <service-url>

    <package-name> is a full name of a called module (service)
        e.g. Service::HelloSadiWorld

    -l <lib-location>
        A directory where is called service stored.
        Default: Perl-SADI/services   

    -e <service-url>
        A SADI service url
        (e.g. http://localhost/cgi-bin/HelloSadiWorld)

    -g <cgi-service-url>
        A SADI service url
        (e.g. http://localhost/cgi-bin/HelloSadiWorld)

    <input-file>
        A SADI RDF/XML file with input data for the service.
        Default: an empty SADI request

    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
		exit(0);
	}

	if ($opt_e) {
		# calling a real service, using cgi
		eval "use HTTP::Request; 1;"
		  or die "$@\n";
		eval "use LWP::UserAgent; 1;"
		  or die "$@\n";
	} elsif ($opt_g) {
		# calling a real service, using cgi
		eval "use HTTP::Request; 1;"
		  or die "$@\n";
		eval "use LWP::UserAgent; 1;"
		  or die "$@\n";
	} else {
		# calling a local service module, without HTTP
		eval "use SADI::Base; 1;";

		# take the lib location from the config file
		require lib;
		lib->import( SADI::Config->param("generators.impl.outdir") );
		require lib;
		lib->import( SADI::Config->param("generators.outdir") );
		unshift( @INC, $opt_l ) if $opt_l;
		$LOG->level('INFO')  if $opt_v;
		$LOG->level('DEBUG') if $opt_d;
	}

}

use strict;

sub _empty_input {
	eval "use SADI::Utils; 1;" or die "$@\n";
	return SADI::Utils::empty_rdf();
}


# --- what service to call
my $module = shift unless $opt_e or $opt_g;    # eg. Service::Mabuhay, or just Mabuhay
my $service;
( $service = $module ) =~ s/.*::// unless $opt_e or $opt_g;

# --- call the service
if ($opt_e) {

	# calling a real service, using HTTP Post
	my $req = HTTP::Request->new( POST => $opt_e );
	my $ua = LWP::UserAgent->new;
	my $input = '';
	if ( @ARGV > 0 ) {
		my $data = shift;    # a file name
		open INPUT, "<$data"
		  or die "Cannot read '$data': $!\n";
		while (<INPUT>) { $input .= $_; }
		close INPUT;
	} else {
		$input = _empty_input;
	}
	print "\nSending to $opt_e the following:\n$input\n" if $opt_d or $opt_v;
	$req->content_type('application/rdf+xml');
	$req->content("$input");
	print "\n" . $ua->request($req)->as_string . "\n";

} elsif ($opt_g) {
	# calling a real SADI service, using HTTP Get
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new( GET => $opt_g );
	my $response = $ua->request($req);
	print "\n" . $response->as_string . "\n";
	print "\nDone!\n";
	exit;
} else {

	# calling a local service module, without HTTP
	my $data;
	if ( @ARGV > 0 ) {
		$data = shift;    # a file name
	} else {
		use File::Temp qw( tempfile );
		my $fh;
		( $fh, $data ) = tempfile( UNLINK => 1 );
		print $fh _empty_input();
		close $fh;
	}
	eval "require $module" or croak $@;
	eval {
		my $target = new $module;
		print $target->$service($data), "\n";
	} or croak $@;
}

__END__
