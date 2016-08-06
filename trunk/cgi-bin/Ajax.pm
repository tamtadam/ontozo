#!C:/Perl64/bin/perl.exe -w

package Ajax;
use strict;
use warnings;
use CGI;
use Data::Dumper;
use utf8;
use JSON;
use Log;
use DBH;
our @ISA = qw( Log DBH );
sub new {
    my ($class) = shift;

    my $self = {};

    bless( $self, $class );
    $self->init( @_ );
    return $self;
}
my $CGI ;
sub init {
    my $self = shift;
    eval '$self->' . "$_" . '::init( @_ )' for @ISA;
    $CGI = CGI->new();
    $self->{XML} = XML::Simple->new();
    print $CGI->header(-type=>"text/html",-charset=>"utf-8"); 

    $self;
}

sub getDataFromClient {
    my $self   = shift;
    my $data   = shift;
    my $result = {};

    my $true = undef ;
            $self->start_time( @{ [ caller(0) ] }[3], $CGI ) ;
    for ( $CGI->param() ) {
            my $json = JSON->new->allow_nonref;
            my $param = $CGI->param($_) ;
            $result->{$_} = $json->utf8(0)->decode ( $param );#, { utf8  => 1 } );
            $true = 1  ;
    }
    return undef unless defined $true ;
    return $result;
}

sub sendResultToClient {
    my $self = shift;
    my $data = shift;

    print $data ;
}

1;

