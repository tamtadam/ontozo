use strict ;
use Data::Dumper ;
use DBConnHandler ;
use ontozo_model;
use relay;
use program;

my $relay_db = &DBConnHandler::init( "relay.cfg" );


my $relay = ontozo_model->new({
                                        'DB_HANDLE' => $relay_db ,
                                        'MODEL'     => "ontozo_model",
                                        'LOG_DIR'   => "/home/deveushu/web_log/ontozo/"
});

print Dumper $relay ;
$relay->save_relay_data_to_db({
         'ip' => '1.1.1.56',
         'id' => '54'
});
my $RELAY = relay->new( {
    "relay_id" => 54
} );

print $RELAY->get_ip() . "\n" ;
$RELAY->update_ip( "0.0.0.10" );
print $RELAY->get_ip() . "\n" ;

exit ;

print $RELAY->get_name() . "\n" ;
$RELAY->update_name( "almaaa" );
print $RELAY->get_name() . "\n" ;



print $RELAY->get_status() . "\n" ;
$RELAY->update_status( 3 );
print $RELAY->get_status() . "\n" ;

my $new_id = $relay->add_new_relay({
    "name"            => "ujjj"    ,
    "ip"              => "0.0.0.0" ,
    "run_status_id"   => 3         ,
});

$RELAY = relay->new({
    "relay_id" => $new_id
});

$RELAY->delete() ;

$RELAY = relay->new({
    "relay_id" => $new_id
});


#------------------------------------------------------
my $PROG = program->new( {
    "program_id" => 2
} );

print $PROG->get_name() . "\n" ;
$PROG->update_name( "alma" );
print $PROG->get_name() . "\n" ;

print $PROG->get_repetition_time() . "\n" ;
$PROG->update_repetition_time( 100 );
print $PROG->get_repetition_time() . "\n" ;

print $PROG->get_status() . "\n" ;
$PROG->update_status( 3 );
print $PROG->get_status() . "\n" ;

my $new_id = $relay->add_new_program({
    "name"            => "ujjj",
    "repetition_time" => 1000  ,
    "run_status_id"   => 3     ,
});

$PROG = program->new({
    "program_id" => $new_id
});

$PROG->delete() ;

