package OBJECTS;

use 5.010001;
use strict;
use warnings;
use vars qw ( $AUTOLOAD );
use Cfg    ;
use Data::Dumper ;

our $VERSION = '0.05';

sub load_cfg_to_obj{
    my $self     = shift ;
    my $cfg_file = shift ;
    
    if ( $cfg_file ){
        my $test_set_params = Cfg::get_struct_from_file( $cfg_file ) ;
        $self->{ 'params' }->{ $_ } = $test_set_params->{ $_ } foreach keys %{ $test_set_params } ;
        return $self ;
    } else {
        return undef ;
    }
}

sub AUTOLOAD{
    my $self = shift ;
    (my $method = $AUTOLOAD) =~ s/.*:://;
    if ( defined $self->{ 'params' }->{ $method } ){
        if ( @_ ){
            
            if ( ref $self->{ 'params' }->{ $method } eq 'ARRAY' ){
                push @{ $self->{ 'params' }->{ $method } }, shift ; 

            } elsif( ref $self->{ 'params' }->{ $method } eq 'HASH'){
                $self->{ 'params' }->{ $method }->{ shift } = shift ;
            
            } else {
                $self->{ 'params' }->{ $method } = shift ;

            }

        } else {
            if ( wantarray and ref $self->{ 'params' }->{ $method }  eq "ARRAY" ){
                return @{ $self->{ 'params' }->{ $method } } ;
                
            } else {
                return $self->{ 'params' }->{ $method } ;
                
            }
        }
    } else {
		return undef ;
    }
}


sub add_autoload_method{
    my $self   = shift ;
    my $method = shift ;
    my $value  = shift ;

    $self->{ 'params' }->{ $method } = $value ;
}

1;

