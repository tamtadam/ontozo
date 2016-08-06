package AccMan;

use strict ;
use DBI;
use DBH;
use Data::Dumper;
use Log;
our @ISA = qw( Log );
use utf8;
use Server_spec_datas qw( SESS_REQED $VIEWS $LOG SEL_CSET INS_CSET GET_FUNC_NAME ); 

sub new {
    my $instance = shift;
    my $class    = ref $instance || $instance;
    my $self     = {};

    bless $self, $class;
   $self->init(@_);
    $self;
}

sub init{

    my $self = shift;

    eval '$self->' . "$_" . '::init( @_ )' for @ISA;

    $self->{DB_HANDLE} = $_[0]->{DB_HANDLE};
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $LOG;

    $self;
}


sub LogOut{
    my $self  = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $LOG;
    my $data = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], $data ) if $LOG;
    
    $self->{'DB_Session'}->delete_session( $data->{'session'} ) ;

    return {} ;
}

sub LoginForm{
    my $self = shift ;
    $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $LOG;

    my $data = shift ;
    my $login;
    if( $login = $self->{'DB_Session'}->check_password( $data ) ){
        $login = $self->{'DB_Session'}->save_session({
            'login' => $login ,      
        }); 
    }
    return $login ;
}

sub ActivateUser{
   my $self = shift;
   my $data = shift;
    
   my $my_update = $self->my_update(
            {
               'update' => { 'activated' => 1 },
               'where'  => {
                  'partner_id' => $data->{"activated_uid"}
               },
               'table'    => 'partner',
               'select'   => 'partner_id',
            }
         );
   if ( $my_update == '0E0' )
   {
       return undef ;   
   }
   else
   {
        return $my_update ; 
   }
}

sub SaveNewUser {
   my $self = shift;
   $self->start_time( @{ [ caller(0) ] }[3], \@_ ) if $LOG;

   my $data = $_[ 0 ]->{ "SaveNewUser" };

   my $sth = $self->{'DB_HANDLE'}->{'mysql_enable_utf8'} = 1;

   $sth = $self->{'DB_HANDLE'}->do('SET NAMES utf8');
   $sth = $self->{'DB_HANDLE'}->do('SET CHARSET utf8');

   $sth = $self->{'DB_HANDLE'}->prepare("SELECT * FROM partner WHERE email = ?");
   $sth->execute( $data->{'email'} ) or die "ERROR\n";

   my $result = $sth->fetchrow_hashref();
   
   return { 
    'partner_login' => 0 } if $result->{'email'};
   utf8::decode( $data->{ $_ } ) foreach keys %{ $data } ;
   my $insert_data = {
      'email'     => $data->{'email'},
      'name'      => $data->{'uname'},
      'jelszo'    => $data->{'password'},
      'login_nev' => $data->{'felhname'},
      'activated' => 0        
   };

   my $partner_id = $self->my_insert(
      {
         'insert' => $insert_data,
         'table'  => 'partner',
         'select' => 'partner_id',
      }
   );
   
   my $login = {
      'partner_login' => $partner_id,
      'email'         => $data->{'email'} ,
   };

   return $login;

}

1 ;
