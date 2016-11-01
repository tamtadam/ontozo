package ontozo_model;
use strict;
use Data::Dumper;

use prog_relay  ;
use program     ;
use relay       ;
use run_status  ;
use connections ;
use Errormsg       ;
use Log         ;
use OBJECTS     ;
use feature qw(state);

our @ISA = qw( prog_relay program relay run_status Errormsg connections OBJECTS) ;

our $VERSION = '0.02';

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

sub init_objects{
    my $self = shift;
    my $programs = program->new()->get_program_list();
    $self->add_autoload_method('PROGRAM_LIST', []);
    $self->add_autoload_method('RELAYS', []);
    my $realy_not_in_db = relay->new()->get_relay_list();
    foreach my $realy_data ( @{ $realy_not_in_db } ) {
        $self->RELAYS( relay->new( $realy_data ) );
    }

    foreach my $prog_data( @{ $programs } ) {
        $self->PROGRAM_LIST( prog_relay->new( $prog_data ) );
    }
}

sub check_status_of_objects{
    my $self = shift;
    my $idx = 0;
    foreach my $program_relay ( $self->PROGRAM_LIST() ) {
        $program_relay->refresh_from_db();
    }
}

sub execute_command{
    my $self            = shift;
    state $ping_cnt     = 0;
    my $is_running_prog = 0;
    
    foreach my $obj ( $self->PROGRAM_LIST() ) {
        $obj->execute_command();
        if ($obj->is_act_time_between_start_stop()) {
            $is_running_prog = 1;   
        };
    }
    if ($is_running_prog == 0) {
        print "No running program, its time of free execution\n";
        foreach my $relay ( $self->RELAYS() ) {
            $relay->check_for_update();
            $relay->execute_command();
        }
    }
    if( ( $ping_cnt ) % 4 == 3 ) {
        foreach my $relay ( $self->RELAYS() ) {
            $relay->update_connected( rn171::_ping($relay) );
        }
    }
    $ping_cnt++;
}
