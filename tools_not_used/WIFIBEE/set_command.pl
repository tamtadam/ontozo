#!C:\Perl64\bin\perl.exe

use client_tcp;
use strict;
use Data::Dumper;
use utf8;
use lib 'd:\\XAMPP_2\\cgi-bin\\ontozo\\' ;
use rn171 qw($rn171);

my $wifly = client_tcp->new({
                            'host' => "192.168.0.20" ,
                            'port' => 2000           ,
});

$wifly->connect();

$wifly->send_msg($rn171->MANUAL, 1) . "\n";
$wifly->send_msg($rn171->ALLRELAYOFF, 1) . "\n";

END{
    $wifly->send_msg($rn171->ALLRELAYOFF, 1) . "\n";
    $wifly->my_close();
}

sleep(1);
while( 1 ){

    print "Ret:" . $wifly->send_msg($rn171->RELAY1ON, 1) . "\n";
    sleep( 1 ) ;
    print "Ret:" . $wifly->send_msg($rn171->RELAY2ON, 1) . "\n";
    sleep( 1 ) ;
    print "Ret:" . $wifly->send_msg($rn171->RELAY3ON, 1) . "\n";
    sleep( 1 ) ;
    print "Ret:" . $wifly->send_msg($rn171->RELAY4ON, 1) . "\n";
    sleep( 1 );
    last;
}

