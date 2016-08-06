package prog;
use strict;
use Data::Dumper;
use Errormsg;
use Log  ;
use DBH  ;

our $VERSION = '0.02';
our @ISA = qw( Errormsg Log DBH ) ;

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self->init( @_ );
    return $self;
}

sub init {
    my $self = shift;
    return $self;
}
