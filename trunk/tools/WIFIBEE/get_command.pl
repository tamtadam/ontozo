#!C:/Perl/bin/perl.exe -w

use strict;
use Data::Dumper; 
use FindBin;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . "/../../cgi-bin/ontozo/";
use Cfg;
use Carp;
use relay;
use Log qw($LOG_ENABLED);

$Log::LOG_ENABLED = 0;

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

my $realy = relay->new({
    ip => '192.168.0.240',
    port => '2000',

});

while ( 1 ) {
    print $realy->show_rssi();
    sleep(2);
}


