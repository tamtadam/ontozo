package Modell_ajax;
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
use DBDispatcher qw( convert_sql );
use English qw' -no_match_vars ';
use File::Slurp;

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
    $self->{ $_ } = $_[ 0 ]->{ $_ } for qw(DB_HANDLE DB_Session);
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

sub get_stdout {
    my $self = shift;
    my @text = read_file( $self->get_stdout_log_path() ) ;

    return { text => \@text };
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

    foreach my $program ( $self->PROGRAM_LIST() ) {
        $program->force_relay_stop_if_program_is_not_set_properly();

        if ($program->its_time_for_the_execution() ) {
            $program->execute_relays_in_program();
            $is_running_prog = 1;

        };
    }
    if ($is_running_prog == 0) {
        print "N O   R U N N I N G   P R O G R A M ,   I T S   T I M E   O F   F R E E   E X E C U T I O N\n";
        foreach my $relay ( $self->RELAYS() ) {
            print "\n*******\nHANDLING: " . $relay->NAME() . "\n";
            $relay->check_for_update();
            $relay->execute_command( {
                master_enabled => 1
            } );
        }
    }
    if( ( $ping_cnt ) % 4 == 3 ) {
        foreach my $relay ( $self->RELAYS() ) {
            #$relay->update_connected( rn171::_ping($relay) );
        }
    }
    $ping_cnt++;
}
