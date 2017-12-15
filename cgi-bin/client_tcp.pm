package client_tcp;

use utf8;
use strict;
use IO::Socket;
use Data::Dumper;
use Sys::Hostname;
use POSIX;
use Carp;
use IO::Socket::Timeout;
use English qw' -no_match_vars ';
use feature qw( state );
use Carp;
use IO::Select;
use Log;

my $select = IO::Select->new();

$| = 1; # flush after every write

sub new {
   my $instance = shift;
   my $class    = ref $instance || $instance;
   my $self     = {};

   $self = {
              'socket_m'      => undef               ,
              'host'          => $_[ 0 ]->{ 'host' } ,
              'port'          => $_[ 0 ]->{ 'port' } ,
              'autoconn'      => $_[ 0 ]->{ 'autoconn' },
              'connect_retry' => $_[ 0 ]->{ 'connect_retry' } // 10,
           };
	bless $self, $class;
	$self
}

sub connect{
   my $self = shift;
   my $cnt  = 0;

   $self->{'socket_m'} = undef ;

   until( $self->{'socket_m'} or $cnt > $self->{'connect_retry'} ){
       Log::log_info "Open TCP/IP connection:\n";
       Log::log_info "ip  : " . $self->{ 'host' } . "\n";
       Log::log_info "port: " . $self->{ 'port' } . "\n";
       $self->{'socket_m'} =  new IO::Socket::INET(
                       PeerAddr   => '192.168.0.200:2000',
      				   Proto    => ( $self->{ 'proto' } ? $self->{ 'proto' } : 'tcp' ) ) or Log::log_info "CONNECTION ERROR: $cnt\n";
       $cnt++;
       sleep( 2 );
   }

   unless( $self->{'socket_m'} ) {
       $self->init_reconnect();
   }

   $select = IO::Select->new();
   IO::Socket::Timeout->enable_timeouts_on( $self->{'socket_m'} );

   $self->{'socket_m'}->read_timeout(2);
   $self->{'socket_m'}->write_timeout(2);

   $select->add( $self->{'socket_m'} );

   return $self->{'socket_m'};
}

sub send_msg{
    state $cnt = 0;
    my $self = shift;
    my $msg  = shift;
    my $with_recv = shift ;

    if( !$self->test_connection() ) {
        Log::log_info Dumper $!;
        Log::log_info "Start Reconnection procedure\n";
        $self->init_reconnect();
        return; # trigger reconnect
    }

    my $rv  = $self->{'socket_m' }->send( "$msg\r\n"); # "\r\n"

    if ( $self->{ autoconn } && (!defined $rv or $rv == 0 or $rv == -1 ) ){
        Log::log_info Dumper $!;
        Log::log_info "Start Reconnection procedure\n";
        $self->init_reconnect();
        return; # trigger reconnect
    }
    sleep( 1 );
    if ( $with_recv ) {
        return $self->my_recv();
    }
    return $rv;
}

sub test_connection {
    my $self = shift;

    return unless defined $self->{'socket_m' };
    return unless $self->{'socket_m' }->connected;
    return 1;
}

sub init_reconnect {
    Log::log_info Dumper $! . "\n";
    Log::log_info "Start Reconnection procedure\n";
    my $self = shift;
    $self->my_close();
    $self->connect() ;
}

sub my_recv{
    my $self = shift ;
    my $size = shift ;
    my $rv2 ;
    my $msg ;
    my @ready = $select->can_read(4);

    unless( $self->test_connection() ) {
        $self->init_reconnect();
        return; # trigger reconnect
    }

    if (@ready) {
        $rv2 = $self->{'socket_m' }->recv( $msg, $size || POSIX::BUFSIZ, 0 );
        my $packs= [
            {packa    => pack( "a*", $msg )},
            {packAs   => pack( "A*", $msg )},
            {packHs   => pack( "H*", $msg )},
            {packbs   => pack( "b*", $msg )},
            {packBs   => pack( "B*", $msg )},
            {unpackas => unpack( "a*", $msg )},
            {unpackAs => unpack( "A*", $msg )},
            {unpackHs => unpack( "H*", $msg )},
            {unpackBs => unpack( "B*", $msg )},
            {unpackbs => unpack( "b*", $msg )},
        ];
        if ( defined $rv2 ) {
            return ($msg, $packs);

        } else {
            $self->init_reconnect();
            return;
        }

    } else {
        #Log::log_info "SELECT TIMEOUT\n";
        #warn $!;
        #Log::log_info "Start Reconnection procedure\n";
        #$self->init_reconnect();
        return 'NOTHING TO READ FROM THE RELAY';
    }
}

sub my_close {
	my $self = shift ;
    $self->{ 'socket_m' }->close();
	shutdown( $self->{ 'socket_m' }, 2);
	close $self->{ 'socket_m' } ;
    $self->{'socket_m'} = undef;

}

sub init_relay{
    my $self = shift;
    Log::log_info "Ret:" . $self ->send_msg("") . "\n";
    Log::log_info "Ret:" . $self ->send_msg("B") . "\n";
    Log::log_info "Ret:" . $self ->send_msg("C") . "\n";
    Log::log_info "Ret:" . $self ->send_msg("n", 1 ) . "\n";
}

1;