package rn171;
use strict;
use utf8;

use Data::Dumper;
use Errormsg;
use Log  ;
use Readonly;
use OBJECTS;
use client_tcp;
use run_status;
use Net::Ping;
use feature qw(state);
use Exporter;
our @ISA = qw( OBJECTS Exporter ) ;
our @EXPORT_OK = qw($rn171);

our $rn171;

our $ping = Net::Ping->new();

Readonly::Hash my %hash => (
    AUTO          => "A",
    MANUAL        => "B",
    CURRENTMODE   => "C",
    GETALLSTATES  => "D",

    STATE1 => "F",
    STATE2 => "G",
    STATE3 => "H",
    STATE4 => "I",
    STATE5 => "J",
    STATE6 => "K",
    STATE7 => "L",
    STATE8 => "M",

    ALLRELAYON    => "d",
    ALLRELAYOFF   => "n",

    '1ON'      => "e",
    '2ON'      => "f",
    '3ON'      => "g",
    '4ON'      => "h",
    '5ON'      => "i",
    '6ON'      => "j",
    '7ON'      => "k",
    '8ON'      => "l",

    '1OFF'     => "o",
    '2OFF'     => "p",
    '3OFF'     => "q",
    '4OFF'     => "r",
    '5OFF'     => "s",
    '6OFF'     => "t",
    '7OFF'     => "u",
    '8OFF'     => "v",

    CLOSE         => "close",

);

unless( ref $rn171 ) {
    $rn171 = {
        active_connections => undef ,
    };
    bless( $rn171, __PACKAGE__ );
    $rn171->add_autoload_method( $_, $hash{$_} ) foreach keys %hash;
}


sub _ping {
    my $rn171           = shift;
    my $relay_hr        = shift;
    my $stdout_disabled = shift ;

    $ping = Net::Ping->new();

    my $wait     = $relay_hr->PING_RETRY() || 10;
    my $res      = undef;
    my $duration;
    my $ip;

    do {
        Log::log_info "\n\nPING:" . $relay_hr->IP . "\n" unless $stdout_disabled;
        $ping->hires();
        ($res, $duration, $ip) = $ping->ping( $relay_hr->IP, 2);
        unless ( $stdout_disabled ) {
            Log::log_info "Retry Ping...\n" unless $res ;
        }

        $wait--;

    } while ( !$res && $wait > 0 );

    Log::log_info "PING is " . ( $res ? "SUCCESSFULL" : "FAILED") . "\n" unless $stdout_disabled;

    unless ( $stdout_disabled ) {
        Log::log_info "Giving up Ping after " . $relay_hr->PING_RETRY() . " trial\n" unless $res;
    }
    $duration = sprintf( "%.2f ms", $duration );

    $ping->close();

    $res ? (return ( $res, $duration ) ) : return ;
}

sub get_status {
    my $rn171 = shift;
    my $relay_hr = shift;
    my $req_func = shift;

    my $wifly = wait_for_available_connection( $relay_hr );

    Log::log_info "GETALLSTATES:" . $rn171->GETALLSTATES . "\n";
    my @recv = $wifly->send_msg( $rn171->GETALLSTATES, 1) ;

    if ( scalar @recv > 1 ) {
        $relay_hr->update_connected( 1 );
        my $status = $recv[1]->[-1]->{ unpackbs };
        return [ split "", $status ]->[ $relay_hr->POS() - 1 ];

    } else {

        return -1;
    }
}

sub send_command_to_relay {
    my $rn171 = shift;
    my $relay_hr = shift;
    my $req_func = shift;

    my $wifly = wait_for_available_connection( $relay_hr );

    my $func = $req_func || $relay_hr->POS;

    unless( $req_func ) {
        if( $relay_hr->RUN_STATUS_ID() == run_status->RUNNING() ) {
            $func .= "ON";
        }
        elsif( $relay_hr->RUN_STATUS_ID() == run_status->STOPPED() ) {
            $func .= "OFF";
        }
        Log::log_info "send command: $func -> wifly code: " . $rn171->$func . "\n";
        unless ( $wifly->send_msg($rn171->$func) ) {
            delete_connection( $relay_hr );
            $relay_hr->update_connected( 0 );
        } else {
            $relay_hr->update_connected( 1 );
        }

    } else {


    }
}

sub send_message_from {
    my $rn171 = shift;
    my $relay_hr = shift;
    my $msg = shift;
    my $wifly = get_connection( $relay_hr );

    my $res = $wifly->send_msg( $msg, 1);

    return $res;
}

sub show_rssi {
    my $rn171 = shift;
    my $relay_hr = shift;
    my $wifly = get_connection( $relay_hr );

    $wifly->send_msg( '$$$', 1);
    my $res = $wifly->send_msg( "show rssi", 1);
    $wifly->send_msg( "exit");

    #$wifly->my_recv( 1024 );

    return $res;
}


sub delete_connection {
    my $relay_hr = shift;
    Log::log_info 'delete_connection' . $relay_hr->IP . "\n";

    return unless keys %{ $rn171->{ 'active_connections' } };
    $rn171->{ 'active_connections' }->{ $relay_hr->IP }->my_close();
    delete $rn171->{ 'active_connections' }->{ $relay_hr->IP };
    Log::log_info 'Deleted from active connection list: ' . $relay_hr->IP . "\n";
}


sub wait_for_available_connection {
    my $relay_hr = shift;
    my $wifly;
    until ( $wifly = get_connection( $relay_hr ) ) {
        Log::log_info "Never Give up to send the proper message to: " . $relay_hr->NAME . "\n";
        return if $relay_hr->PING_GIVE_UP;

        delete_connection( $relay_hr ) ;
        get_connection( $relay_hr ) ;
    }
    return $wifly;
}

sub get_connection {
    my $relay_hr      = shift;

    unless ( exists $rn171->{ 'active_connections' }->{ $relay_hr->IP } ) {
        if( $rn171->_ping( $relay_hr ) ) {
            Log::log_info "CONNECT to relay\n";
            Log::log_info "\tip: " . $relay_hr->IP . "\n";
            Log::log_info "\tport: " . ( $relay_hr->PORT || 2000 )  . "\n";
            $rn171->{ 'active_connections' }->{ $relay_hr->IP } = client_tcp->new({
                                                            'host'          => $relay_hr->IP ,
                                                            'port'          => $relay_hr->PORT || 2000 ,
                                                            'autoconn'      => $relay_hr->AUTOCONN || 1,
                                                            'connect_retry' => $relay_hr->CONNECT_RETRY // 6000 ,
            });
            sleep(2);

            $rn171->{ 'active_connections' }->{ $relay_hr->IP }->connect();

            if( $relay_hr->JUST_CONNECT ) {
                return $rn171->{ 'active_connections' }->{ $relay_hr->IP } ;
            }

            Log::log_info "Wait for start\n";
            sleep(2);

            Log::log_info $rn171->{ 'active_connections' }->{ $relay_hr->IP } ->my_recv() . "\n";
            Log::log_info "MANUAL:" . $rn171->MANUAL . "\n";
            #Log::log_info "ALLRELAYOFF:" . $rn171->ALLRELAYOFF . "\n";

            $rn171->{ 'active_connections' }->{ $relay_hr->IP }->send_msg( $rn171->MANUAL );
            #$rn171->{ 'active_connections' }->{ $relay_hr->IP }->send_msg( $rn171->ALLRELAYOFF );
            return $rn171->{ 'active_connections' }->{ $relay_hr->IP } ;

        } else {
            return undef;

        }
    } else {
        if ( !$rn171->_ping( $relay_hr ) ) {
            Log::log_info "No connection: " . $relay_hr->NAME . "\n" and return undef ;
        }
        return $rn171->{ 'active_connections' }->{ $relay_hr->IP };
    }
    return undef;

}

sub STOPCONNECTIONS {
    $ping->close();

    foreach my $conn_id ( keys %{ $rn171->{ 'active_connections' } } ) {
        Log::log_info "IP:" . $conn_id . " ALLRELAYOFF\n";
        $rn171->{ 'active_connections' }->{ $conn_id }->send_msg($rn171->ALLRELAYOFF);
        $rn171->{ 'active_connections' }->{ $conn_id }->send_msg($rn171->AUTO);
        $rn171->{ 'active_connections' }->{ $conn_id }->send_msg($rn171->CLOSE);
        sleep( 4 );
        $rn171->{ 'active_connections' }->{ $conn_id }->my_close();
        sleep( 3 );
    }
}

1;