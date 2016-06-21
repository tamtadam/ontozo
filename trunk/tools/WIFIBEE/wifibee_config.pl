#!C:/Perl/bin/perl.exe -w

use client_tcp;
use strict;
use Data::Dumper; 

my $wifly = client_tcp->new({
                            'host' => "1.2.3.4" ,
                            'port' => 2000      ,
});
    
$wifly->connect();
print $wifly ->my_recv(); 

open ( SET, "$ARGV[ 0 ]") or die "File open error $ARGV[ 0 ]\n" ;
$wifly->send_msg( '$$$' ) ;
print $wifly ->my_recv(); 
$wifly->send_msg( "" ) ;
print $wifly ->my_recv(); 

while( my $line = <SET> ){
    chomp $line ;
    $wifly ->send_msg( $line ) ;
    print $wifly ->my_recv() . "\n"; 
    sleep( 3 ) ;
    $wifly ->send_msg( "save\n" ) ;
    print $wifly ->my_recv() . "\n"; 
    sleep( 2 ) ;
}

$wifly ->send_msg( "save\n" ) ;
print $wifly ->my_recv() . "\n"; 

sleep( 3 ) ;
$wifly->my_close();
END{
    $wifly->my_close();
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