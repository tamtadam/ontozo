#!C:/Perl/bin/perl.exe -w


use strict;
use Data::Dumper;

use English qw' -no_match_vars ';
use FindBin;
use lib $FindBin::RealBin;
use lib $FindBin::RealBin . ( $OSNAME =~/win/i ? "/../../ontozo/" : "/../../cgi-bin/");

use lib $FindBin::RealBin . "/../";
use lib $FindBin::RealBin . "/../../../common/cgi-bin/";

$ENV{ ENABLE_STDOUT } = 1;

use client_tcp;
use Cfg;
use Carp;
use Controller_ajax;
use DBConnHandler;
use Log qw($LOG_ENABLED);
#my $relay_db = &Server_spec_datas::init( "relay" );
#my $controller = Controller_ajax->new( {
#                                        'DB_HANDLE' => $relay_db ,
#                                        'MODEL'     => "ontozo_model",
#                                        'LOG_DIR'   => "d:\\XAMPP_2\\cgi-bin\\ontozo\\log\\",
#} );
$Log::LOG_ENABLED = 0;
my $cfg = read_cfg(@ARGV);
print Dumper $cfg;
execute_commands( $cfg->{ 'COMMANDS' } );
#add_to_db($cfg);


sub read_cfg {
    my @params = @_;
    confess "input is missing" unless @params;
    my  %cfg = ();

   tie %cfg, 'Cfg' , READ => $ARGV[0],
                         COMMENT => '#|;';
    my %rcfg;
    %rcfg = %cfg;
    untie %cfg;
    return \%rcfg;
}
my @recv;
sub execute_commands {
    my $wifly = client_tcp->new({
#                            'host' => "1.2.3.4" ,
                            'host' => "192.168.1.1" ,
                            'port' => 2000      ,
    });
    $wifly->connect();
    my $command_list = shift // [];
    @recv = $wifly ->my_recv();
    print $recv[0] . "\n";
    $wifly->send_msg( '$$$' ) ;
    @recv = $wifly ->my_recv();
    print $recv[0] . "\n";
    $wifly->send_msg( "" ) ;
    @recv = $wifly ->my_recv();
    print $recv[0] . "\n";

    foreach my $command ( @{ $command_list } ) {
        print "command:" . $command . "\n";
        $wifly ->send_msg( $command ) ;
        @recv = $wifly ->my_recv();
        print $recv[0] . "\n";
        sleep( 1 ) ;
        $wifly ->send_msg( "save\n" ) ;
        @recv = $wifly ->my_recv();
        print $recv[0] . "\n";
        sleep( 2 ) ;
    }
}
=pod
sub add_to_db {
    my $relay_datas = shift // {};

    my $relay;
    foreach my $relay_id ( grep {$_ !~/COMMANDS/} keys %{ $relay_datas } ) {
        if ( $relay = get_relay_id( $relay_datas->{ $relay_id } ) ) {
            print "UPDATE\n";
            $controller->start_action({
                'save_relay_data_to_db' => {
                    id => $relay,
                    map { lc $_ => $relay_datas->{ $relay_id }->{ $_ } } keys %{ $relay_datas->{ $relay_id } },
                }
            });
        } else {
            print "ADD\n";
            $controller->start_action({
                'add_new_relay' => {
                    map { lc $_ => $relay_datas->{ $relay_id }->{ $_ } } keys %{ $relay_datas->{ $relay_id } }
                }
            });

        }
    }
}

sub get_relay_id {
    my $relay_params = shift;

    my $res = $controller->my_select({
        "select" => "ALL"  ,
        "from"   => "relay",
        "where"  => {
            'name' => $relay_params->{ "NAME" },
        }
    });
    if ( $res ) {
        return $res->[ 0 ]->{ 'relay_id' };
    } else {
        return undef;
    }
}

=cut