package rn171;
use strict;
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
our $rn171 = undef;

my $active_connections = {};
my $ping = Net::Ping->new();

Readonly::Hash my %hash => (
    AUTO          => "A",
    MANUAL        => "B",
    CURRENTMODE   => "C",
    GETALLSTATES  => "D",

    CHANNEL1STATE => "F",
    CHANNEL2STATE => "G",
    CHANNEL3STATE => "H",
    CHANNEL4STATE => "I",
    CHANNEL5STATE => "J",
    CHANNEL6STATE => "K",
    CHANNEL7STATE => "L",
    CHANNEL8STATE => "M",

    ALLRELAYON    => "d",
    ALLRELAYOFF   => "n",

    RELAY1ON      => "e",
    RELAY2ON      => "f",
    RELAY3ON      => "g",
    RELAY4ON      => "h",
    RELAY5ON      => "i",
    RELAY6ON      => "j",
    RELAY7ON      => "k",
    RELAY8ON      => "l",
    
    RELAY1OFF     => "o",
    RELAY2OFF     => "p",
    RELAY3OFF     => "q",
    RELAY4OFF     => "r",
    RELAY5OFF     => "s",
    RELAY6OFF     => "t",
    RELAY7OFF     => "u",
    RELAY8OFF     => "v",

);

INIT {
    unless( defined $rn171 ) {
        $rn171 = {};
        bless( $rn171, 'OBJECTS' );
        $rn171->add_autoload_method( $_, $hash{$_} ) foreach keys %hash;
    }
}

sub _ping {
    my $relay_hr = shift;
    print "PING:" . $relay_hr->IP . "\n";
    return $ping->ping( $relay_hr->IP, 10);
}

sub send_command_to_relay {
    my $relay_hr = shift;
    my $req_func = shift;
    my $wifly = get_connection( $relay_hr );
    unless ( $wifly ) {
        print "No connection: " . $relay_hr->NAME . "\n" and return undef ;
    }

    my $func = $req_func || $relay_hr->POS;

    unless( $req_func ) {
        if( $relay_hr->RUN_STATUS_ID() == run_status->RUNNING() ) {
            $func .= "ON";
        }
        elsif( $relay_hr->RUN_STATUS_ID() == run_status->STOPPED() ) {
            $func .= "OFF";
        }
        print "$func:" . $rn171->$func . "\n";
        unless ( $wifly->send_msg($rn171->$func) ) {
            delete_connection( $relay_hr );
            $relay_hr->update_connected( 0 );
        }
    } else {
    
    
    }
}

sub show_rssi {
    my $relay_hr = shift;
    my $wifly = get_connection( $relay_hr );
    print $wifly ->my_recv();
    $wifly->send_msg( '$$$' ) ;
    print $wifly ->my_recv(); 
    $wifly->send_msg( "" ) ;
    print $wifly ->my_recv(); 
    
    $wifly ->send_msg( "show rssi\n" ) ;
    print "show rssi\n";
    my $res = $wifly ->my_recv() . "\n"; 
    $wifly->send_msg( "exit\n" );
    print $wifly ->my_recv();
    return $res;
}


sub delete_connection {
    my $relay_hr = shift;
    $active_connections->{ $relay_hr->IP }->my_close();
    delete $active_connections->{ $relay_hr->IP };
}


sub get_connection {
    my $relay_hr      = shift;
    my $connect_retry = shift ;
    state $ping_cnt   = 0;

    unless ( exists $active_connections->{ $relay_hr->IP } ) {
        if( _ping( $relay_hr ) ) {
            print "CONNECT to relay\n";
            print "\tip: " . $relay_hr->IP . "\n";
            print "\tport: " . ( $relay_hr->PORT || 2000 )  . "\n";
            $active_connections->{ $relay_hr->IP } = client_tcp->new({
                                                            'host' => $relay_hr->IP ,
                                                            'port' => $relay_hr->PORT || 2000 ,
            });
            sleep(5);
            $active_connections->{ $relay_hr->IP }->connect();
            print "Wait for start\n";
            sleep(10);
            print $active_connections->{ $relay_hr->IP } ->my_recv() . "\n";
            print "MANUAL:" . $rn171->MANUAL . "\n";
            print "ALLRELAYOFF:" . $rn171->ALLRELAYOFF . "\n";
            $active_connections->{ $relay_hr->IP }->send_msg( $rn171->MANUAL );
            $active_connections->{ $relay_hr->IP }->send_msg( $rn171->ALLRELAYOFF );
            return $active_connections->{ $relay_hr->IP } ;
        } else {
            return undef;
        }
    } else {
        return $active_connections->{ $relay_hr->IP };
    }
    return undef;

}

sub STOPCONNECTIONS {
    $ping->close();

    foreach my $conn_id ( keys %{ $active_connections } ) {
        print "IP:" . $conn_id . " ALLRELAYOFF\n";
        $active_connections->{ $conn_id }->send_msg($rn171->ALLRELAYOFF);
        $active_connections->{ $conn_id }->send_msg($rn171->AUTO);
        sleep(4);
        $active_connections->{ $conn_id }->my_close();
    }
}

1;