#!C:\Perl64\bin\perl.exe

use Net::Ping;
use strict;

my $p = Net::Ping->new();
while( 1 ){
    print "host is alive.\n" if $p->ping('192.168.0.20');
    sleep( 1 );
}
$p->close();

