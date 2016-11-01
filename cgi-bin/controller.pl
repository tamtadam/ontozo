#!C:\Perl64\bin\perl.exe

##
##  printenv -- demo CGI program which just prints its environment
##

use strict;
use warnings;
use DBConnHandler;
use CGI;
use View_ajax;
use Controller_ajax;
use Data::Dumper ;
use rn171;

$SIG{INT} = sub {
    rn171::STOPCONNECTIONS();
    exit;
};

$SIG{TERM} = sub {
    rn171::STOPCONNECTIONS();
    exit;
};
$SIG{KILL} = sub {
    rn171::STOPCONNECTIONS();
    exit;
};
my $relay_db = &DBConnHandler::init( "relay.cfg" );

my $ajax       = View_ajax->new()      ;
my $controller = Controller_ajax->new( {
                                        'DB_HANDLE' => $relay_db ,
                                        'MODEL'     => "ontozo_model",
                                        'LOG_DIR'   => "d:\\XAMPP_2\\cgi-bin\\ontozo\\log\\",
} );

my $cnt = 0;

$controller->init_objects();

while(1){
    print "###################################\n";
    print "Round:" . $cnt++ . "\n";
    $controller->check_status_of_objects();
    $controller->execute_command();
    sleep(4);
}


