#!/usr/bin/perl

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
use Log;

sleep( 40 );

Log::init_log_path( $OSNAME =~/win/i ? "f:\\xampp\\cgi-bin\\log\\" : "/var/www/cgi-bin/log/" );

$ENV{ STDOUT_REDIRECT } = 1;
$ENV{ ENABLE_STDOUT } = 1;

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

my $cfg = ( $OSNAME =~/win/i ? '' : '/var/www/cgi-bin/' ) . 'server.cfg' ;
my $relay_db = &DBConnHandler::init( $cfg );

my $ajax = View_ajax->new();

my $controller = Controller_ajax->new( {
    'DB_HANDLE'   => $relay_db ,
    'MODEL'       => "Modell_ajax",
} );

my $cnt = 0;

$controller->init_objects();

while(1){    print "###################################\n";
    Log::log_info "Round:" . $cnt++ . "\n";
    Log::log_info scalar localtime . "\n";
    $controller->check_status_of_objects();
    $controller->execute_command();
    sleep(5);
}

