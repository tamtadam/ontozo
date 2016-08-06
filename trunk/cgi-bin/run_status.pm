package run_status;
use strict;
use Data::Dumper;
use DBH;
use Errormsg;
use Log  ;
use OBJECTS;
use Exporter;
our $VERSION = '0.02';
our @ISA = qw( Errormsg Log DBH OBJECTS ) ;
use vars qw ( $AUTOLOAD );
our $RUN_STATUS = {};
our @EXPORT_OK = qw(run_status);

sub new {
    my ($class) = shift;

    my $self = {};
    bless( $self, $class );
    $self = $self->init( @_ );
    return $self;
}

sub init {
    my $self = shift;
    unless ( scalar keys %{ $RUN_STATUS } ) {
        my $db_data = $self->my_select({
                 'from'   => 'run_status',
                 'select' => 'ALL',
        });
        bless( $RUN_STATUS, 'OBJECTS' );
        foreach my $row ( @{$db_data} ) {
            $RUN_STATUS->add_autoload_method( uc $row->{'name'}, $row->{'run_status_id'} );
        }
    }
    return $RUN_STATUS;
}

sub get_run_status_name_by_id {
    my $status_id = shift;
}

sub AUTOLOAD {
    my $self = shift ;
    (my $method = $AUTOLOAD) =~ s/.*:://;
    return $RUN_STATUS->$method;
}

1;