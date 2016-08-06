package connections;
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
    
    my $relay_data = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "connections",
    });

    return undef unless $relay_data ;

    $self->{ 'connections' }      = $relay_data;

    return $self;
}

sub add_new_connections{
    my $self       = shift ;
    my $new_rel_id = $self->my_insert({
        "table"  => "connections",
        "insert" => {
            "parent" => $_[ 0 ]->{ 'parent' } ,
            "child"   => $_[ 0 ]->{ 'child' } ,
        }
    });
    if( $new_rel_id ){
        $self->init() ;
    }
    return $new_rel_id ;
}
