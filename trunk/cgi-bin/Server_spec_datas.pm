#!/usr/bin/perl


package Server_spec_datas;
use CGI;
use Log;
use DBI;
use Cfg;
use Carp;
use Exporter 'import';
use Data::Dumper ;
use constant RELAY      => 'd:\\XAMPP_2\\cgi-bin\\ontozo\\relay.cfg'  ;
use Time::HiRes qw(time);
@EXPORT_OK = qw( $DB $SERVER_DFG $DBH SESS_REQED SEL_CSET INS_CSET $LOG $VIEWS GET_FUNC_NAME START STOP INS_COLLAT );

our $SLESH      = $^O =~ /win/i ? '\\' : '/' ;
our $QSLESH     = quotemeta $SLESH;
our $DB         = undef ;
our $SERVER_CFG = {}    ;
our $LOG        = 1     ;
our $start_time = undef;
our $VIEWS = {
    'SearchCompany' => ''    ,
};


BEGIN{
    use strict;
}


END{
    $DB->disconnect();
} 


sub init{
   my $project = shift ;
   my  %cfg = ();
      
   if ( $project =~/nds/ ){
       tie %cfg, 'Cfg' , READ => NDSCFG ,
                         COMMENT => '#|;';

   } elsif ( $project =~/testcase/ ){
       tie %cfg, 'Cfg' , READ => TESTCASE ,
                         COMMENT => '#|;';
       
   } elsif ( $project eq "omni" ){
       tie %cfg, 'Cfg' , READ => OMNICFG ,
                         COMMENT => '#|;';
   } elsif ( $project =~/test/ ){
       tie %cfg, 'Cfg' , READ => TESTCFG ,
                         COMMENT => '#|;';
   } elsif ( $project eq "omni_pg" ){
       tie %cfg, 'Cfg' , READ => POSTGRE ,
                         COMMENT => '#|;';
   } elsif ( $project eq "trend" ){
       tie %cfg, 'Cfg' , READ => TREND ,
                         COMMENT => '#|;';
   } elsif ( $project eq "relay" ){
       tie %cfg, 'Cfg' , READ => RELAY ,
                         COMMENT => '#|;';
   } else {
       tie %cfg, 'Cfg' , READ => LOCALCFG ,
                     COMMENT => '#|;';
   }

   unless ( %cfg ) {    
      print "failed" and return undef
   }
   my %rcfg;
   %rcfg = %cfg ;
   untie %cfg   ;
   $SERVER_CFG = \%rcfg ;

   $DB = DBI->connect("dbi:$SERVER_CFG->{DATABASE}->{PLATFORM}:dbname=$SERVER_CFG->{DATABASE}->{DATABASE};host=$SERVER_CFG->{DATABASE}->{HOST};port=$SERVER_CFG->{DATABASE}->{PORT};", "$SERVER_CFG->{DATABASE}->{USER}", "$SERVER_CFG->{DATABASE}->{PWD}", 
                        { "RaiseError" => 1, PrintWarn=>0, PrintError=>0 })
                                                        or print "ERROR in db connection\n" . Dumper $SERVER_CFG;
    return $DB ;
}

sub START{
    $start_time = time ;
}

sub STOP{
    my $stop_time = time ;
    
    $stop_time -= $start_time ;
    return int(( $stop_time*1000))/1000  ;

}
sub SESS_REQED{
    return $SERVER_CFG->{ 'PREREQ' }->{ $_[0] }->{'SESSION'} ;
}

sub SEL_CSET{

    return $SERVER_CFG->{ 'PREREQ' }->{ $_[0] }->{'CHARSET'}->{ 'SELECT' } ;

}
sub INS_CSET{
    return $SERVER_CFG->{ 'PREREQ' }->{ $_[0] }->{'CHARSET'}->{ 'INSERT' } ;

}

sub INS_COLLAT{
    return $SERVER_CFG->{ 'PREREQ' }->{ $_[0] }->{'CHARSET'}->{ 'COLLAT' } ;

}

sub GET_FUNC_NAME{

    @{ [ caller(1) ] }[3] =~/(\w+)::(\w+)/i ;

    return $2 ;
}
1;