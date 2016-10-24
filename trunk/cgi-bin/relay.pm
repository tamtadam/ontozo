package relay;
use strict;
use Data::Dumper;

use Errormsg        ;
use Log             ;
use DBH             ;
use run_status      ;
use relay_utils     ;
use Carp            ;
use rn171 qw($rn171);

our @ISA = qw( DBH relay_utils Log run_status );

our $VERSION = '0.02';

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self = $self->init( @_ );

    return $self;
}

sub init {
    my $self = shift;
    my $relay_params = shift;
    eval '$self->' . "$_" . '::init(@_)' for @ISA;
    if ( $relay_params->{ "relay_id" } ) {
        my $relay_data = $self->my_select({
            "select" => "ALL"  ,
            "from"   => "relay",
            "where"  => {
                'relay_id' => $relay_params->{ "relay_id" } ,
            }
        });
        return undef unless $relay_data ;
        $relay_data->[ 0 ]->{ act_status_id } = -1;
        $self->read_data_to_from_db_to_obj( $relay_data->[ 0 ] );
        #remove program relevant values
        delete $relay_params->{ $_ } for keys %{$relay_data->[ 0 ] };
        $self->read_data_to_from_db_to_obj( $relay_params );
    } else {
        $self->add_autoload_method( 'IP', $relay_params->{ip} );
        $self->add_autoload_method( 'PORT', $relay_params->{port} );
        $self->add_autoload_method( 'CONNECT_RETRY', $relay_params->{connect_retry} );
        $self->add_autoload_method( 'AUTOCONN', $relay_params->{autoconn} );
    }

    return $self;
}


sub check_for_update {
    my $self = shift;
    my $act_time = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "relay",
        "where" => {
            "relay_id" => $self->RELAY_ID(),
        }
    });
    my $update_needed = ( ( $self->LAST_MODIFIED()) and ( $self->update_is_needed( $self->LAST_MODIFIED(), $act_time->[0]->{ 'last_modified' } ) ) );
    if( $update_needed ){
        $self->init({
            'relay_id' => $self->RELAY_ID(), 
        });
    }
    return $update_needed;
}

sub get_connections{
    my $self = shift ;
    my $relays = $self->my_select( {
        'select' => 'ALL',
        'from'   => 'connected_relay' ,
    } );
    my $conn_relays = {} ;
    $self->start_time( @{ [ caller(0) ] }[3], $relays ) ;
    foreach ( @{ $relays } ){
        unless( defined $conn_relays->{ $_->{ 'parent' } } ){
            $conn_relays->{ $_->{ 'parent' } } = [] ;
        }
        push @{ $conn_relays->{ $_->{ 'parent' } } }, $_->{ 'child' } ;
    }
    $self->start_time( @{ [ caller(0) ] }[3], $conn_relays ) ;
    return $conn_relays ;
}

sub show_rssi {
    my $self = shift;
    rn171::show_rssi( $self );
}

sub execute_command{
    my $self = shift;
    rn171::send_command_to_relay( $self );
    $self->ACT_STATUS_ID( $self->RUN_STATUS_ID() );
    return 1;
}


sub delete_connection{
    my $self = shift ;
    map { delete $_[ 0 ]->{ $_ } } grep( !defined $_[ 0 ]->{ $_ }, keys %{ $_[ 0 ] } ) ;
    $self->my_delete({
        "from"  => "connected_relay",
        "where" => $_[ 0 ],
        "relation" => "AND"
    }) ;
}

sub delete_relay{
    my $self = shift ;
    
    my $relay = relay->new({
        "relay_id" => $_[ 0 ]->{ 'relay_id' } 
    });
    
    $relay->delete_it() ;
}

sub get_relay_list{
    my $self = shift ;
    my $relays = $self->my_select( {
        'from'   => 'relay' ,
        'select' => 'ALL'
    } );
    return $relays ;
}

sub get_relay_list_not_in_prog{
    my $self = shift ;

    my $relays = $self->my_select({
             'from'   => 'relay AS r',
             'select' => [ 'r.relay_id   AS relay_id' ],
              'join'  => 'LEFT JOIN program_relay pr ON pr.relay_id = r.relay_id',
              'where' => {
                          "pr.program_id" => 'IS NULL' 
              },
    });
    return $relays ;
}

sub update_name{
    my $self = shift ;
    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "name" => $_[ 0 ],
        },
        "where" => {
            "relay_id" => $self->get_id() , 
        }
    } ) ;
    if( $res ){
        $self->{ 'name' } = $_[ 0 ] ;
        $self->NAME( $_[ 0 ] );
    }
}

sub get_name{
    return $_[ 0 ]->{ "name" } ;
}

sub update_pos{
    my $self = shift ;
    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "pos" => $_[ 0 ],
        },
        "where" => {
            "relay_id" => $self->get_id() , 
        }
    } ) ;
    if( $res ){
        $self->{ 'pos' } = $_[ 0 ] ;
        $self->POS( $_[ 0 ] );
    }
}

sub update_connected{
    my $self = shift ;
    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "connected" => $_[ 0 ],
        },
        "where" => {
            "relay_id" => $self->get_id() , 
        }
    } ) ;
    if( $res ){
        $self->{ 'connected' } = $_[ 0 ] ;
        $self->CONNECTED( $_[ 0 ] );
    }
}

sub get_pos{
    return $_[ 0 ]->{ "pos" } ;
}

sub get_id{
    return $_[ 0 ]->{ 'relay_id' } ;   
}

sub delete_it{
    my $self = shift ;
    $self->my_delete({
        "from"  => "relay",
        "where" => {
            "relay_id" => $self->get_id() ,
        },
    }) ;
}

sub update_ip{
    my $self = shift ;
    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "ip" => $_[ 0 ],
        },
        "where" => {
            "relay_id" => $self->get_id() , 
        }
    } ) ;
    if( $res ){
        $self->{ 'ip' } = $_[ 0 ] ;
        $self->IP( $_[ 0 ] );
    }
}

sub get_ip{
    return $_[ 0 ]->{ "ip" } ;
}

sub update_status{
    my $self = shift ;
    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "run_status_id" => $_[ 0 ],
        },
        "where" => {
            "relay_id" => $self->get_id() , 
        }
    } ) ;
    if( $res ){
        $self->{ 'run_status_id' } = $_[ 0 ] ;
        $self->RUN_STATUS_ID( $_[ 0 ] );
        $self->_update_timestamp_in_table( "relay", "relay_id", $self->RELAY_ID );
    }
}

sub connect {
    
}

sub get_status{
    return $_[ 0 ]->{ "run_status_id" } ;
}

sub add_new_relay{
    my $self       = shift ;
    
    map { delete $_[ 0 ]->{ $_ } } grep( !defined $_[ 0 ]->{ $_ }, keys %{ $_[ 0 ] } ) ;
    $self->start_time( @{ [ caller(0) ] }[3], $_[ 0 ] );
    my $new_rel_id = $self->my_insert({
        "table"  => "relay" ,
        "insert" => $_[ 0 ] ,
    });
    my $relay_data = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "relay",
        "where"  => {
            'relay_id' => $new_rel_id ,
        }
    }) if $new_rel_id ;
    return $relay_data->[ 0 ] ;
}

sub add_new_connections{
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    map { delete $_[ 0 ]->{ $_ } } grep( !defined $_[ 0 ]->{ $_ }, keys %{ $_[ 0 ] } ) ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    my $new_rel_id = $self->my_insert({
        "table"  => "connected_relay" ,
        "insert" => $_[ 0 ] ,
    });
}

sub save_relay_data_to_db{
    my $self = shift ;

    my $param_fv = {
        "ip"     => \&update_ip,
        "name"   => \&update_name,
        "status" => \&update_status,
        "pos"    => \&update_pos,
    };

    my $relay = relay->new({
        "relay_id" => $_[ 0 ]->{ 'id' } 
    });

    my $update_items = [ grep ( $_ ne "id" && $_ ne "uid", keys %{ $_[ 0 ] } ) ] ;

    foreach my $update_item ( @{ $update_items } ) {
        my $update_func = "update_" . $update_item ;
        eval{
            $relay->$update_func( $_[ 0 ]->{ $update_item } ) ;
        } ;
    }
    $self->_update_timestamp_in_table( "relay", "relay_id", $_[ 0 ]->{ 'id' } );
}
