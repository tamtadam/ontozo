#!C:\Perl64\bin\perl.exe

use strict;
use warnings;
use English qw' -no_match_vars ';
use FindBin;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . ( $OSNAME =~/win/i ? "/../../ontozo/" : "/../../cgi-bin/");

use lib $FindBin::RealBin . "/../";
use lib $FindBin::RealBin . "/../../common/cgi-bin/";

use DBConnHandler;
use CGI;
use View_ajax;
use Controller_ajax;
use Data::Dumper ;
use rn171;

$ENV{ ENABLE_STDOUT } = 0;

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
my $relay_db = &DBConnHandler::init( "server.cfg" );

my $ajax       = View_ajax->new()      ;
my $controller = Controller_ajax->new( {
                                        'DB_HANDLE'   => $relay_db ,
                                        'MODEL'       => "Modell_ajax",
                                        'LOG_DIR'     => "..\\log\\",
                                        'STDOUTREDIR' =>  1
} );

my $cnt = 0;

$controller->init_objects();

while(1){    print "###################################\n";
    print "Round:" . $cnt++ . "\n";
    print scalar localtime . "\n";
    $controller->check_status_of_objects();
    $controller->execute_command();
    sleep(1);
}

