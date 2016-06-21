#!/usr/bin/perl -w

package client_tcp;

use strict;
use IO::Socket;
use Data::Dumper;
use Sys::Hostname;
use POSIX;


sub new {
   my $instance = shift;
   my $class    = ref $instance || $instance;
   my $self     = {};

   $self = {
              'socket_m'   => undef               ,
              'host'       => $_[ 0 ]->{ 'host' } ,
              'port'       => $_[ 0 ]->{ 'port' } ,
           };
	bless $self, $class;
	$self
}

sub connect{
   my $self = shift;
   $self->{'socket_m'} = undef ;
   
   until( $self->{'socket_m'} ){
       $self->{'socket_m'} =  new IO::Socket::INET(
            		   PeerAddr => $self->{ 'host' } ,
      				   PeerPort => $self->{ 'port' } ,
      				   Reuse    => 1                 ,
      				   Timeout  => 1                 ,
      				   Proto    => 'tcp') or print "CONNECTION ERROR\n";
   }

}

sub send_msg{
    my $self = shift;
    my $msg  = shift;
    my $without_recv = shift ;
    my $rv  = $self->{'socket_m' }->send ( "$msg\r\n", 0 );	                     
    if ( !defined $rv or $rv == 0 or $rv == -1 ){
        $self->connect() ;
    }
}

sub my_recv{
    my $self = shift ;
    my $rv2 ;
    my $msg ;
    $rv2 = $self->{'socket_m' }->recv( $msg, POSIX::BUFSIZ, 0 );              
    (defined $rv2) ? $msg : (return undef);
}
sub my_close {
	my $self = shift ;
	close $self->{ 'socket_m' } ;
}

sub init_relay{
    my $self = shift;
    print "Ret:" . $self ->send_msg("") . "\n";
    print "Ret:" . $self ->send_msg("B") . "\n";
    print "Ret:" . $self ->send_msg("C") . "\n";
    print "Ret:" . $self ->send_msg("n", 1 ) . "\n";
}

1;