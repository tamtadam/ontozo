#!C:\Perl64\bin\perl.exe

##
##  printenv -- demo CGI program which just prints its environment
##

use strict;
use warnings;
use Server_spec_datas; 
use CGI;
use View_ajax;
use Controller_ajax;
use Data::Dumper ;

my $relay_db = &Server_spec_datas::init( "relay" );

my $ajax       = View_ajax->new()      ;
my $controller = Controller_ajax->new( { 
                                        'DB_HANDLE' => $relay_db ,
                                        'MODEL'     => "ontozo_model",
                                        'LOG_DIR'   => "d:\\XAMPP_2\\cgi-bin\\ontozo\\log\\",
} );


my $struct;
my $data;          

$data = $ajax->get_data_from_server();

$struct = $controller->start_action( $data );
$ajax->send_data_to_server( $struct, "JSON" );
