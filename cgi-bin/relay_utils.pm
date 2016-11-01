package relay_utils;
use strict;
use Data::Dumper;
use OBJECTS;
use Time::gmtime;
our @ISA = qw( OBJECTS ) ;
use HTTP::Date;
sub _update_timestamp_in_table{
    my $self    = shift;
    my $table   = shift;
    my $id_name = shift;
    my $id_data = shift;
    
    my $gth = $self->{ 'DB_HANDLE' }->prepare("UPDATE $table SET last_modified = NOW() WHERE $id_name = $id_data");

    my $res = $gth->execute();
}

sub read_data_to_from_db_to_obj{
    my $self = shift;
    my $data = shift || {};
    foreach ( keys %{ $data } ) {
        $self->add_autoload_method(uc $_, $data->{ $_ } );
        $self->{ $_ } = $data->{ $_ } ; # TODO remove direct access
    }
}

sub update_is_needed{
    my $self = shift;
    my $fst = shift;
    my $scnd = shift;
    if ( !defined $fst or !defined $scnd ){
        print "Not defiend input for comparing\n";
        return 1;
    }
    # 2016-03-10 11:17:23
    my @fst_a = $fst =~/(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/;
    my @scnd_a = $scnd =~/(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/;

    for my $idx ( 0..$#fst_a ) {
        if( $fst_a[ $idx ] < $scnd_a[ $idx ] ) {
            return 1;
        }
    }
    return 0;
}

sub is_act_time_between_start_stop{
    my $self = shift;

    return 0 unless $self->START and $self->STOP ;

    my $act_time_in_sec = $self->convert_localtime_to_sec(localtime(time));

    if( (sort {$a <=> $b} $self->START, $self->STOP, $act_time_in_sec)[1] == $act_time_in_sec ){
        return 1;
    }
    return 0;
}

sub convert_localtime_to_sec{
    my $self = shift;
    my @act_time = @_;

    return ( $act_time[2]*3600 + $act_time[1]*60 + $act_time[0] ) ;
}

1;

