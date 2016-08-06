package prog_relay;
use strict;
use Data::Dumper;
use Error;
use Log  ;
use DBH  ;
use relay_utils ;
use relay;
use program;
use run_status  qw(run_status);
use Carp;
our $VERSION = '0.02';
use OBJECTS;
our @ISA = qw( Error Log DBH relay_utils OBJECTS run_status ) ;

# RUN_STATUS-> hulyeseg, ki kell szervezni az objektum alol
sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self->init( @_ );
    return $self;
}

sub init {
    my $self = shift;
    my $param = shift // {};
    print "INIT\n";
    if( $param->{ 'program_id' } ){
        delete $self->{ $_ } foreach keys %{ $self };
        my $relays_in_prog = $self->my_select({
            "select" => "ALL"  ,
            "from"   => "program_relay",
            "where"  => {
                'program_id' => $param->{ "program_id" } ,
            }
        });
        $self->add_autoload_method( 'RELAYS', []);
        $self->add_autoload_method( 'PROGRAM', 0);
        $self->PROGRAM( program->new( $param ) );

        foreach my $relay_in_prog_data( @{ $relays_in_prog } ) {
            my $new_relay = relay->new( $relay_in_prog_data );
            $self->RELAYS( $new_relay ) if $new_relay;
        }
    }

    return $self;
}

sub refresh_from_db{
    my $self = shift;
    my $updated = 0;
    if( $self->PROGRAM->RUN_STATUS_ID == run_status->RUNNING ) {
        foreach my $relay ( $self->RELAYS() ) {
            if( $relay->check_for_update() ) {
                print "Relay updated: " . $relay->NAME() . "\n";
                #$self->relay_is_stopped_stop_program( $relay );
                $updated = 1;
            }
        }
    }

    if( $self->PROGRAM->check_for_update() ) {
        print "Program updated: " . $self->PROGRAM->NAME() . "\n";
        $self->init( { 'program_id' => $self->PROGRAM->PROGRAM_ID } );
        $updated = 1;
    }
    return $updated;
}

sub execute_command {
    my $self = shift;

    if( $self->PROGRAM->RUN_STATUS_ID != $self->PROGRAM->ACT_STATUS_ID ) {
        if( $self->PROGRAM->RUN_STATUS_ID == run_status->STOPPED ){
            print $self->PROGRAM->NAME . "<--- program is STOPPED\nExecute it on the other relays\n";          
            foreach ( $self->RELAYS() ) {
                $_->update_status( run_status->STOPPED() );
                $_->execute_command();                
            }
            
        }
        $self->PROGRAM->ACT_STATUS_ID( $self->PROGRAM->RUN_STATUS_ID );
    }
}

sub is_act_time_between_start_stop{
    my $self = shift;
    return 0 unless $self->PROGRAM->ACT_STATUS_ID == run_status->RUNNING ;
    print "ACTIVE program:" . $self->PROGRAM->NAME . "\n";
    foreach my $relay ( $self->RELAYS() ) {
        if ( $relay->is_act_time_between_start_stop() ) {
            print "START relay:" . $relay->NAME . "\n";
            $relay->update_status( run_status->RUNNING );

        } elsif ( $self->PROGRAM->RUN_STATUS_ID == run_status->RUNNING ) {
            print "STOP relay: " . $relay->NAME . "\n";
            $relay->update_status( run_status->STOPPED ) ;
        }
        $relay->execute_command();
    }
    return 1;
}

sub relay_is_stopped_stop_program {
    my $self = shift;
    my $stop = 0;
    my $relay = shift;
    print "Program is stopped based on stopped relay:" . $self->PROGRAM->NAME . "\n";
    $self->PROGRAM->update_status( run_status->STOPPED );
    $self->PROGRAM->init( { program_id => $self->PROGRAM->PROGRAM_ID } );
    $stop = 1;
    return $stop;
}

sub delete_relay_from_program{
    my $self = shift ;
    my $data = shift ;

    my $relay_prog_id = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "program_relay",
        "where"  => {
            'relay_id' => $_[ 0 ]->{ 'relay_id' } ,
        },
        "relation" => "AND",
    });

    foreach my $item ( @{ $relay_prog_id } ){
        $self->_update_timestamp_in_table( "program_relay", "program_relay_id", $item->{ 'program_relay_id' } );
    }

    $self->my_delete({
        "from"  => "program_relay",
        "where" => {
            "relay_id" => $data->{ 'relay_id' }  ,
        },
    }) ;
}

sub get_relays_in_programs{
    my $self = shift ;
    my $relay_data = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "program_relay",
    });
    return $relay_data ;
}

sub update_relay_prog_data_to_db{
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    my $where = {
        "program_id" => $_[ 0 ]->{ "program_id" } ,
        "relay_id"   => $_[ 0 ]->{ "relay_id" },
    } ;
    my $res ;
    if ( defined $_[ 0 ]->{ 'start' } ){
         $res = $self->my_update( {
            "table" => "program_relay",
            "where" => $where,
            "relation" => "AND",
            "update" => {
                "start" => $_[ 0 ]->{ "start" },
            },
        } );
    } else {
        $res = $self->my_update( {
            "table" => "program_relay",
            "where" => $where,
            "relation" => "AND",
            "update" => {
                "stop" => $_[ 0 ]->{ "stop" },
            },
        } );
    }
    $self->_update_timestamp_in_table( "program_relay", "program_relay_id", $_[ 0 ]->{ 'program_relay_id' } );
    $self->_update_timestamp_in_table( "program", "program_id", $_[ 0 ]->{ 'program_id' } );
    
    return $res ;
}

sub add_relay_to_program{
    my $self =  shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    delete $_[ 0 ]->{ 'uid' } ;

    my $insert = $self->my_insert({
        "table" => "program_relay",
        "insert" => $_[ 0 ] ,
    });
    $self->_update_timestamp_in_table( "program_relay", "program_relay_id", $insert );
    return $insert;
}



sub remove_relay_in_program{
    my $self = shift ;
    
    my $relay_prog_id = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "program_relay",
        "where"  => {
            'program_id' => $_[ 0 ]->{ 'program_id' } ,
            'relay_id' => $_[ 0 ]->{ 'relay_id' } ,
        },
        "relation" => "AND",
    });
    $relay_prog_id = $relay_prog_id->[0];
    $self->_update_timestamp_in_table( "program_relay", "program_relay_id", $relay_prog_id->{ 'program_relay_id' } );
    
    return $self->my_delete({
        "from" => "program_relay",
        "where" => {
            "program_id" => $_[ 0 ]->{ 'program_id' },
            "relay_id"   => $_[ 0 ]->{ 'relay_id' } ,
        },
        "relation" => "AND",
    });    
}


