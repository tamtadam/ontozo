package program;
use strict;
use Data::Dumper;
use Errormsg;
use Log  ;
use DBH  ;
use run_status  ;
our $VERSION = '0.02';
our @ISA = qw( Errormsg Log DBH relay_utils run_status ) ;

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self->init( @_ );
    return $self;
}


sub get_program_list{
    my $self = shift ;

    my $progs = $self->my_select({
        'from'   => 'program',
        'select' => 'ALL'
    }) ;
    return $progs ;
}

sub init {
    my $self = shift;
    my $params = shift // {};
    my $relay_data;
    if($params->{ "program_id" }) {
        $relay_data = $self->my_select({
            "select" => "ALL"  ,
            "from"   => "program",
            "where"  => {
                'program_id' => $params->{ "program_id" } ,
            }
        });
        return undef unless $relay_data ;
        $relay_data->[ 0 ]->{ act_status_id } = -1;
        $self->read_data_to_from_db_to_obj( $relay_data->[ 0 ] );
        $self->add_autoload_method( 'RUN_STATUS', run_status->new() );
    }
    return $self;
}

sub check_for_update {
    my $self = shift;
    my $act_time = $self->my_select({
        "select" => "ALL"  ,
        "from"   => "program",
        "where" => {
            "program_id" => $self->PROGRAM_ID(),
        }
    });
    my $update_needed = ( $self->LAST_MODIFIED() and $self->update_is_needed( $self->LAST_MODIFIED(), $act_time->[0]->{ 'last_modified' } ) );
    if( $update_needed ){
        $self->init({
            'program_id' => $self->PROGRAM_ID(),
        });
    }
    return $update_needed;
}

sub update_name{
    my $self = shift ;

    my $res = $self->my_update( {
        "table"  => "program",
        "update" => {
            "name" => $_[ 0 ],
        },
        "where" => {
            "program_id" => $self->get_id() ,
        }
    } ) ;
    if( $res ){
        $self->{ 'name' } = $_[ 0 ] ;
        $self->NAME( $_[ 0 ] );
    }
}

sub update_status{
    my $self = shift ;

    my $res = $self->my_update( {
        "table"  => "program",
        "update" => {
            "run_status_id" => $_[ 0 ],
        },
        "where" => {
            "program_id" => $self->get_id() ,
        }
    } ) ;
    if( $_[ 0 ] == run_status->RUNNING ) {
        $self->execute_sql( "UPDATE program SET time_of_last_start = DATE_SUB(time_of_last_start, INTERVAL 10 DAY)" . " WHERE program_id = ?", $self->get_id() ) ;

    }
    if( $res ){
        $self->{ 'run_status_id' } = $_[ 0 ] ;
        $self->RUN_STATUS_ID( $_[ 0 ] );
    }
}


sub update_repetition_time{
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    my $res = $self->my_update( {
        "table"  => "program",
        "update" => {
            "repetition_time" => $_[ 0 ],
        },
        "where" => {
            "program_id" => $self->get_id() ,
        }
    } ) ;
    if( $res ){
        $self->{ 'repetition_time' } = $_[ 0 ] ;
    }
}

sub save_program_data_to_db{
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    $self->start_time( @{ [ caller(0) ] }[3], $self ) ;
    my $param_fv = {
        "name"            => \&update_name,
        "status"          => \&update_status,
        "repetition_time" => \&update_repetition_time,
    };

    my $program = program->new({
        "program_id" => $_[ 0 ]->{ 'id' }
    });

    my $update_item = [ grep ( $_ ne "id" && $_ ne "uid", keys %{ $_[ 0 ] } ) ]->[ 0 ] ;
    my $update_func = "update_" . $update_item ;
    eval{
        $program->$update_func( $_[ 0 ]->{ $update_item } ) ;
    } ;
    $self->_update_timestamp_in_table( "program", "program_id", $_[ 0 ]->{ 'id' } );
}

sub add_new_program{
    my $self       = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;
    map { delete $_[ 0 ]->{ $_ } } grep( !defined $_[ 0 ]->{ $_ }, keys %{ $_[ 0 ] } ) ;
    my $new_rel_id = $self->my_insert({
        "table"  => "program",
        "insert" => $_[ 0 ],
    });
    return $new_rel_id ;
}

sub delete{
    my $self = shift ;
    $self->my_delete({
        "from"  => "program",
        "where" => {
            "program_id" => $self->get_id() ,
        },
    }) ;
}

sub get_id{
    return $_[ 0 ]->{ 'program_id' } ;
}

sub get_name{
    return $_[ 0 ]->{ "name" } ;
}

sub get_status{
    return $_[ 0 ]->{ 'run_status_id' } ;
}

sub get_repetition_time{
    return $_[ 0 ]->{ 'repetition_time' } ;
}