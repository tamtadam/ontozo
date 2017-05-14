#!C:/Perl/bin/perl.exe -w

use strict;
use utf8;
use Data::Dumper;
use FindBin;
use English qw' -no_match_vars ';

use lib $FindBin::RealBin;
use lib $FindBin::RealBin . ( $OSNAME =~/win/i ? "/../../ontozo/" : "/../../cgi-bin/");

use Cfg;
use Carp;
use relay;
use Log qw($LOG_ENABLED);

$Log::LOG_ENABLED = 0;
=pod
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
=cut
my $realy = relay->new({
    ip            => '192.168.0.240',
    port          => '2000',
    autoconn      => 1,
    connect_retry => 100,
});

my $cnt = 0;

while ( 1 ) {
    print $realy->show_rssi();
}


