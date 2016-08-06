package Log;
use strict;
use warnings;
use Data::Dumper;
use File::stat;
our $LOG_ENABLED = 1 ;
our $VERSION = '0.02';

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self->init( @_ );
    return $self;
}

sub init {
    my $self = shift;
    $self->{ 'LOG_DIR' } = $_[ 0 ]->{ "LOG_DIR" } ;
    $self;
}

sub start_time{
    my $self = shift ;

    return undef unless $LOG_ENABLED;

    $_[0] =~/(\w+)::(\w+)/i ;
    my $pkg      = $1 ;
    my $fv       = $2 ;
    my $params   = $_[1] ;
    my $w_mode   = ">>"  ;
    my $file = "$pkg" . "_" . "$fv.txt";
    my $dir = ( $self->{ 'LOG_DIR' } ? $self->{ 'LOG_DIR' } : "/log/" );
    unless( -e $dir ){
        mkdir( $dir ) ;
    }

    my $size = stat( $dir . $file );
    if ( $size and $size->size >= 1000000 ){
        $w_mode = ">" ;
    }

    open (LOGGER, $w_mode . $dir . $file ) or return $fv  ;
    print LOGGER "\n$pkg" . "::" . "$fv\n start_time: " . ( scalar localtime ). "\n" ;
    print LOGGER Dumper $params;
    close LOGGER ;
    return $fv ;
}

1;
