package regexer ;
sub regexp{
    my $passed_reg = join( '.*?', split( '', $_[ 1 ]->{ "string" } ) );
    return @{ [ grep( $_->{ $_[ 1 ]->{ 'row_name' } } =~ /$passed_reg/i, @{ $_[ 1 ]->{ 'table' } } ) ] }[ 0 ]->{ $_[ 1 ]->{ 'row_id' } } ;
}

package STATUS  ;

sub PAUSE{
    return $_[ 0 ]->regexer::regexp({
            "string"   => "Passed"    ,
            "row_name" => "name",
            "row_id"   => "run_status_id"  ,
            "table"    => $_[ 0 ]->{ "RUN_STATUS" } ,
    }) ;
}

sub STOPPED{
    return $_[ 0 ]->regexer::regexp({
            "string"   => "Failed"    ,
            "row_name" => "name",
            "row_id"   => "run_status_id"  ,
            "table"    => $_[ 0 ]->{ "RUN_STATUS" } ,
    })

sub RUNNING{
    return $_[ 0 ]->regexer::regexp({
            "string"   => "Failed"    ,
            "row_name" => "name",
            "row_id"   => "run_status_id"  ,
            "table"    => $_[ 0 ]->{ "RUN_STATUS" } ,
    }) ;
} ;
}

package db_const;

use strict;
use warnings;

use DBH;
use Data::Dumper;
use Log;
use Errormsg;
use JSON;
use utf8 ;
use DBConnHandler qw( SESS_REQED $VIEWS $LOG SEL_CSET INS_CSET GET_FUNC_NAME $DB);
use MyFile ;

our @ISA = qw( Log DBH Errormsg );
our $VERSION = "1.00";

sub new {
    my $instance = shift;
    my $class    = ref $instance || $instance;
    my $self     = {};

    bless $self, $class;
    $DB = &DBConnHandler::init( "testcase.cfg" );
    $_[ 0 ]->{ "DB_HANDLE" } = $DB ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    $self->init(@_);
    $self;
}

sub init {
    my $self = shift;

    eval '$self->' . "$_" . '::init( @_ )' for @ISA;
    $self->{ 'DB_HANDLE' }    = $_[0]->{ 'DB_HANDLE' };
    $self->{ 'LOG_DIR' }      = $_[0]->{ 'LOG_DIR' };
    $self->{ "ERROR_CODE" }   = [] ;
    $self->{ "TIMES" }        = [] ;
    $self->init_ids() ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ );
    $self;
}

sub init_ids{
    my $self = shift ;
    $self->{ 'RUN_STATUS' } = $self->my_select({
             'from'   => 'run_status',
             'select' => 'ALL',
    });
    if ( !defined $self->{ 'RESULTS' } or
         !defined $self->{ 'PROJECT' } or
         !defined $self->{ 'TESTCASETYPE' } ){
        die "Init ids F A I L E D\n" ;
    }
}

1 ;
