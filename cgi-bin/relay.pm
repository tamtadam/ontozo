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
use List::Util qw(first max maxstr min minstr reduce shuffle sum);

our @ISA = qw( DBH relay_utils Log run_status );

our $VERSION = '0.02';
my $relay_store = {};

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self = $self->init( @_ );
    return $self;
}

sub init {
    my $self         = shift;
    my $relay_params = shift;
    my $update_needed = delete $relay_params->{ update_needed };

    eval '$self->' . "$_" . '::init(@_)' for @ISA;

    #return $relay_store->{$relay_params->{ "relay_id" } } if $relay_params->{ "relay_id" } && $relay_store->{$relay_params->{ "relay_id" } } && !$update_needed ;

    if ( $relay_params->{ "relay_id" } ) {
        my $relay_data = $self->my_select({
            "select" => [
                "r.relay_id      as relay_id",
                "r.name          as name",
                "r.ip            as ip",
                "r.run_status_id as run_status_id",
                "r.pos           AS pos",
                "r.last_modified AS last_modified",
                "r.connected     AS connected",
                "pr.start        AS start",
                "pr.stop         AS stop"
            ],
            "from"   => "relay as r",
            "join"   => "LEFT JOIN program_relay as pr ON (r.relay_id = pr.relay_id)",
            "where"  => {
                'r.relay_id' => $relay_params->{ "relay_id" } ,
            }
        });

        return undef unless $relay_data ;
        $relay_data->[ 0 ]->{ act_status_id } = -1;
        $self->read_data_to_from_db_to_obj( $relay_data->[ 0 ] );
        #remove program relevant values
        delete $relay_params->{ $_ } for keys %{$relay_data->[ 0 ] };
        $self->read_data_to_from_db_to_obj( $relay_params );

        $self->init_master_relays() unless( $relay_params->{ not_to_connect_master } );
        #$relay_store->{ $self->RELAY_ID() } = $self;
        return $self;
        return $relay_store->{ $self->RELAY_ID() };

    } else {

        foreach ( qw( ip port connect_retry autoconn ping_retry name) ) {
            if( exists $relay_params->{ $_ } ) {
                $self->add_autoload_method( uc $_, $relay_params->{ $_ } );
            }
        }

        return $self;
    }
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
        $self = $self->init({
            'relay_id'      => $self->RELAY_ID(),
            'update_needed' => 1
        });
    }
    return $update_needed;
}

sub init_master_relays {
    my $self = shift;
    my $relay_id = shift || $self->RELAY_ID() || return ;
    Log::log_info 'Start init_master_relays of ' . $self->NAME() . "\n";
    $self->add_autoload_method( 'MASTERS', []);

    my $masters = $self->my_select({
         'from'   => 'connected_relay as cr',
         'select' => [
                        'c.relay_id       AS relay_id',
                        'c.ip             AS ip',
                        'c.last_modified  AS last_modified',
                        'c.name           AS name',
                        'c.run_status_id  AS run_status_id',
                        'c.pos            AS pos'
         ],
         'join'  => '
            JOIN relay as p on (cr.parent = p.relay_id)
            JOIN relay as c  on (cr.child  = c.relay_id )
         ',
         'where' => {
                      "p.relay_id" => $relay_id
          },
    });

    foreach my $master( @{ $masters } ) {
        $master->{ not_to_connect_master } = 1;
        my $new_relay = relay->new( $master );
        Log::log_info "Add master: " . $new_relay->NAME() . "\n";
        $self->MASTERS( $new_relay ) if $new_relay;
    }
    return $self;
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
    Log::log_info "show_rssi\n";
    my $res = rn171::show_rssi( $self );
    return $res->[0]{ packa };
}

sub get_status_via_wifi {
    my $self = shift;
    my $pos = $self->POS() || return;

    my $status = rn171::get_status( $self );
    return $status;
};

sub send_stdout {
    my $self = shift;
    my $stdin ;
    while( 1 ) {
        Log::log_info "Wait for input\n";
        $stdin = <>;
        Log::log_info rn171::send_message_from( $self, $stdin, 1 );
        Log::log_info "ready\n";
    }
}

sub test {
    my $self = shift;
}

sub execute_command{
    my $self = shift;
    my $params = shift || {};

    rn171::send_command_to_relay( $self );
    $self->ACT_STATUS_ID( $self->RUN_STATUS_ID() );
    Log::log_info "act running masters: " . ( join ",", @{ $params->{ act_running_masters } || [] }) . "\n";
    if ( $params->{  master_enabled } ) {
        Log::log_info "Masters should follow me: " . $self->NAME() . "\n";
        foreach my $master ( grep{ $_} $self->MASTERS() ) {
            next if !grep{ $master->RELAY_ID() == $_ } @{ $params->{ act_running_masters } || [] } ;
            Log::log_info $master->NAME() . " will follow you\n";
            $master->ACT_STATUS_ID( $self->RUN_STATUS_ID() );
            $master->RUN_STATUS_ID( $self->RUN_STATUS_ID() );
            rn171::send_command_to_relay( $master );
        }
    }

    return 1;
}

sub get_master_list {
    my $self = shift;
    return [ map{ $_->RELAY_ID() } $self->MASTERS() ];
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
        "relay_id"              => $_[ 0 ]->{ 'relay_id' },
        "not_to_connect_master" => 1
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
    my $self   = shift ;
    my $new_status = shift || return ;
    my $params = shift || {};

    my $res = $self->my_update( {
        "table"  => "relay",
        "update" => {
            "run_status_id" => $new_status,
        },
        "where" => {
            "relay_id" => $self->get_id() ,
        }
    } ) ;
    if( $res ){
        $self->{ 'run_status_id' } = $new_status ;
        $self->RUN_STATUS_ID( $new_status );
        $self->_update_timestamp_in_table( "relay", "relay_id", $self->RELAY_ID ) if $params->{ db_store };
    }
}

sub connect {

}

sub get_status_{
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
        relay_id              => $_[ 0 ]->{ 'id' },
        not_to_connect_master => 1
    });

    my $update_items = [ grep ( $_ ne "id" && $_ ne "uid", keys %{ $_[ 0 ] } ) ] ;

    foreach my $update_item ( @{ $update_items } ) {
        my $update_func = "update_" . $update_item ;
        eval{
            $relay->$update_func( $_[ 0 ]->{ $update_item }, { db_store => 1 } ) ;
        } ;
    }
    $self->_update_timestamp_in_table( "relay", "relay_id", $_[ 0 ]->{ 'id' } );
}
