#!C:/Perl64/bin/perl.exe -w

package View_ajax;

use strict;
use Data::Dumper;
use Ajax;
use Log ;
use JSON;
use Server_spec_datas qw( SESS_REQED ); 
our @ISA = qw( Log Ajax );
my $log = undef ;
sub new {
    my $instance = shift;
    my $class    = ref $instance || $instance;
    my $self     = {};

    bless $self, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    eval '$self->' . "$_" . '::init' for @ISA;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $log;

    $self;
}

sub send_data_to_server {
    my $self        = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $log;

    my $data        = shift;
    my $encode_type = "JSON";
    my $send_data ;
    if ( "JSON" eq $encode_type ) {
        
        return undef if ( 'SCALAR' eq ref $data ) ;
        $send_data = JSON->new->allow_nonref->encode ( $data ) ;

        $self->sendResultToClient($send_data);
    }
}

sub get_data_from_server {
    my $self         = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $log;

    my $needed_param = shift;

    my $needed_valus = $self->getDataFromClient($needed_param);

    return $needed_valus;
}

1;

