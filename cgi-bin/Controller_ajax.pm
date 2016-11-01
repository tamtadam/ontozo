package Controller_ajax;

use strict        ;
use Data::Dumper  ;

use FindBin;
use lib $FindBin::RealBin;

use Log           ;
use DB_Session    ;
use DBConnHandler qw( SESS_REQED $LOG START STOP );
use ontozo_model ;

our @ISA ;

sub new {
    my $instance = shift;
    my $class    = ref $instance || $instance;
    my $self     = {};

    bless $self, $class;
    my $required_module;

    ( defined $_[ 0 ]->{ "MODEL" } ) ? ( $required_module = $_[ 0 ]->{ "MODEL" } ) :
                                       ( $required_module = "Modell_ajax" ) ;

    eval {
        require $required_module . "\.pm";
        $required_module->import();
        1;
    } or do {
       print "Module is not found: " . $@;
    };

    @ISA = ( "Log", $required_module );
    $self->init(@_);
    $self;
}

sub init {
    my $self = shift;
    $self->{'DB_Session'} = DB_Session->new( {'DB_HANDLE' => $_[0]->{'DB_HANDLE'}} )  ;
    $_[0]->{'DB_Session'} = $self->{'DB_Session'} ;
    eval '$self->' . "$_" . '::init(@_)' for @ISA;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;

    $self;
}

sub start_action {
    my $self          = shift;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) ;

    my $received_data = shift;
    my $uid;
    my $return_value;
   if ( $received_data->{"session_data"} ) {
      $uid = $self->{'DB_Session'}->check_session( $received_data->{'session_data'} );

    }

    $self->start_time( @{ [ caller(0) ] }[3], $received_data ) ;
    $received_data->{ $_ }->{'order'} = 10 foreach grep( !defined $received_data->{ $_ }->{'order'}, keys % { $received_data } ) ;

    for ( sort {
        $received_data->{ $b }->{ 'order' } <=>
        $received_data->{ $a }->{ 'order' }
        } keys %{$received_data} ){

      next if ( ( $_ eq "session_data" ) or ( $_ eq "project" ) );

      if ( SESS_REQED($_) ) {
         return undef unless $uid;

        }
      #Saveform1- ben tombben erkezik az adat mentesre es a user data
      if ( 'ARRAY' eq ref $received_data->{$_} ) {
         $received_data->{$_}->[0]->{'uid'} = $uid;
      }
      else {
         $received_data->{$_}->{'uid'} = $uid;
      }

      START;
          $self->start_time( @{ [ caller(0) ] }[3], \@ISA ) ;
          $self->start_time( @{ [ caller(0) ] }[3], \@ontozo_model::ISA ) ;
          delete $received_data->{ $_ }->{'order'} ;
      $return_value->{$_} = $self->$_( $received_data->{$_} );
         $self->start_time( @{ [ caller(0) ] }[3], $return_value ) if $LOG;

      $return_value->{'time'}->{$_} = STOP;
      $return_value->{ "errors" } = $self->get_errors();


    }
    return $return_value;
}

1;
