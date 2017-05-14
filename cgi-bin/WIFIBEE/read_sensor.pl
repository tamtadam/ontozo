#!C:/Perl/bin/perl.exe -w

use client_tcp;
use strict;
use Data::Dumper;
use English qw' -no_match_vars ';
use FindBin;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . ( $OSNAME =~/win/i ? "/../../ontozo/" : "/../../cgi-bin/");

use lib $FindBin::RealBin . "/../";

my $wifly = client_tcp->new({
                            'host' => "192.168.0.21" ,
                            'port' => 2000      ,
});

$wifly->connect();
print $wifly ->my_recv();

$wifly->send_msg( '$$$' ) ;
print $wifly ->my_recv();
$wifly->send_msg( "" ) ;
print $wifly ->my_recv();

while ( 1 ){
    foreach ( 0..7 ) {
        $wifly->send_msg( "show q $_" )  ;
        select ( undef, undef, undef, 0.5 ) ;
        my $res = $wifly->my_recv() ;
        my $volt = &get_voltage_from_res( $res ) ;
        print "$_ : " . $volt . "\n" if $volt > 0.15 ;
    }
}

sleep( 5 ) ;
$wifly->my_close();
END{
    $wifly->my_close();

}

sub get_voltage_from_res{
    my $res = shift ;
    $res =~/8(.*?),/s ;
    return (hex "0x" . $1) / 1000000 ;
}
=pod
while( 1 ){

    print "Ret:" . $cli ->send_msg("\\1", 1) . "\n";
    print "Ret:" . $cli ->send_msg("[") . "\n";
    sleep( 2 ) ;
    print "Ret:" . $cli ->send_msg("\\2", 1) . "\n";
    print "Ret:" . $cli ->send_msg("[") . "\n";
    sleep( 3 ) ;
    print "Ret:" . $cli ->send_msg("\\4", 1) . "\n";
    print "Ret:" . $cli ->send_msg("[") . "\n";
    sleep( 4 ) ;
    print "Ret:" . $cli ->send_msg("\\8", 1) . "\n";
    print "Ret:" . $cli ->send_msg("[") . "\n";
    sleep( 5 );
}
$cli->my_close();

=cut