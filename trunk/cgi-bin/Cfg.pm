#!/usr/bin/perl -w

package Cfg;

use strict;

#use LockFile::Simple;
use vars qw( $VERSION %cnf );

$VERSION = '1.00';

use Data::Dumper;

sub TIEHASH {

   my $class = shift;
   my $args  = {
         READ       => undef ,
         WRITE      => undef ,
         RW         => undef ,
         MODE       => 0640  ,
         LOCK       => undef ,
         SEP        => '='   ,
         REGSEP     => undef ,
         COMMENT    => ';'   ,
         REGCOMMENT => undef ,
         CHANGE     => undef ,
         @_
      };
   my $file     = undef ;
   my $outfile  = undef ;
   if ( $args->{RW} ) {
      $file     = $args->{RW} ;
      $outfile  = $args->{RW} ;
   } else {
      $file     = $args->{READ}  ? $args->{READ}  : '' ;
      $outfile  = $args->{WRITE} ? $args->{WRITE} : '' ;
   }
   my $lock     = $args->{LOCK};
   my $mode     = $args->{MODE};
   my $sep      = $args->{SEP};
   my $splitsep = $args->{REGSEP} ? $args->{REGSEP} : $sep;
   my $comment  = $args->{COMMENT};
   my $regcmnt  = $args->{REGCOMMENT} ? $args->{REGCOMMENT} : $args->{COMMENT};
   my %cnf      = ();
   my $prekey   = '';

   my $node = {
         CNF   => {},
         FILE  => $outfile,
         MODE  => $mode,
         LOCK  => undef,
         SEP   => $sep,
         SSEP  => $splitsep,
         CMNT  => $comment,
         SCMNT => $regcmnt,
      };
=pod
  if ( $lock and $outfile ) {
      $node->{LOCK} = LockFile::Simple->make (
            -max   => 30 ,
            -delay => 1  ,
            -nfs   => 1 ,
         );
      $node->{LOCK}->lock( $outfile )
  }
=cut
   my $val;
   my $key;
   if ( -e $file ) {
       my $section = '' ;
       open FH, $file ;
       for ( grep { !/\s*$regcmnt/ &&  !/^\s*$/ } <FH> ) {

         chomp;
         if ( /^\s*\[\s*(.*?)\s*\]\s*$/ ) {
            $section = $1;
            $prekey  = '';
            for my $s ( split /\./, $section ) {
               $prekey .= "{$s}"
            }
            next
         }
         
         ( $key, $val ) = split /$splitsep/, $_, 2;
         
         $key =~ s/^\s*(.*?)\s*$/$1/;
         $val =~ s/^\s*(.*?)\s*$/$1/;
         $val =~ s/"/\"/g;                         # escape quotation marks (") in value to avoid problem at eval
         $val =~ s/'/\'/g;                         # escape quotation marks (') in value to avoid problem at eval
         for my $chg ( @{$args->{CHANGE}} ) {
            $val = __change( $chg, $val )
         }
         if ( $key =~ /\[\s*([0-9]+)\s*\]$/ ) {
            my $idx = $1;
            $key =~ s/\[\s*$idx\s*\]$//;
            eval '$cnf'."$prekey"."{$key}[$idx]='$val'"
         } else {
            eval '$cnf'."$prekey"."{$key}='$val'"
         }
      }
      close FH;
      $node->{CNF} = \%cnf
   } else{ 
       print "Can't open file: $file\n" and die;
   }
   my $this = bless $node, $class;
   return $this
}

sub getHash {
   my $s = shift;
   my $r;
   ( $s,$r )= split /\./, $s, 2;
   my %c;

   return $c{s}
}

sub __change {
  my $change = shift;
  my $value  = shift;
  
  my $from;
  my $to;
  my $g;

   if ( not $to ) {
      if ( $change=~/g$/ ) {
         $g = 'g'
      }
      $change =~ s/^s//;
      $change =~ s/^\///;
      $change =~ s/g$//;
      $change =~ s/\/$//;
      ( $from,$to ) = split /\//, $change, 2
   }

   if ( not defined $g ) {
      $g = ''
   }

   if ( $g eq 'g' ) {
      $value=~s/$from/$to/g
   } else {
      $value=~s/$from/$to/
   }
   $value
}

sub FETCH {
   return $_[0]->{CNF}->{$_[1]}
}

sub STORE {
   $_[0]->{CNF}->{$_[1]} = $_[2];
   return $_[2]
}

sub DELETE {
   delete $_[0]->{CNF}->{$_[1]}
}

sub EXISTS {
   return exists $_[0]->{CNF}->{$_[1]}
}

sub FIRSTKEY {
   my $temp = keys %{$_[0]->{CNF}};
   return scalar each %{$_[0]->{CNF}}
}

sub NEXTKEY {
   return scalar each %{$_[0]->{CNF}}
}

sub DESTROY {
   my $self = shift;

   if ( $self->{FILE} ) {
      my   $fh;
      open $fh, '>', $self->{FILE};

      print $fh $self->{CMNT}, " TEE3::Tie::Cfg version $VERSION\n";
      #print $fh $self->{CMNT}," Tie::Cfg version $VERSION (c) H. Oesterholt-Dijkema, license perl\n";
      print $fh "\n";

      __write_self($self->{CNF},$fh,0,$self->{SEP},$self->{CMNT},"");
      
      print $fh "\n";
      
      close $fh;
      chmod $self->{MODE}, $self->{FILE};

      if ($self->{LOCK}) {
         $self->{LOCK}->unlock($self->{FILE});
      }
   }
}


sub __write_self {
   my $cfg     = shift;
   my $fh      = shift;
   my $depth   = shift;
   my $sep     = shift;
   my $cmnt    = shift;
   my $section = shift;
   my $key;
   my $value;

   # Pass 1, Keys that are no sections
   if ( $section ) {
      print $fh "[$section]\n"
   }

   while ( ( $key, $value ) = each %{$cfg}) {
      if ( ref $value  ne 'HASH' ) {
         if ( ref $value  eq 'ARRAY') {
            my $idx = 0;
            for my $element ( @{$value }) {
               print $fh "$key", "[$idx]", "$sep", "$element\n";
               $idx++
            }
         } else {
            print $fh "$key", "$sep", "$value\n" ;
            
#            if ( ! $key ||  ! $sep || ! $value ) {
#               print Dumper ( { key => $key, sep => $sep, value => $value } ) ;
#            }
            
         }
      }
   }
   # Pass 2, keys that are sections
   while ( ( $key, $value ) = each %{$cfg} ) {
      if ( ref $value  eq 'HASH' ) {
         # OK, It's a section
         if ( $depth==0 ) {
            __write_self( $value, $fh, $depth+1, $sep, $cmnt, $key )
         }
         else {
            __write_self( $value, $fh, $depth+1, $sep, $cmnt, $section . '.' . $key )
         }
      }
   }
}

sub get_struct_from_file{
    my  %cfg = ();
    my %rcfg;
    
    tie %cfg, 'Cfg' , READ => $_[0] ,
                      COMMENT => '#';
    unless ( %cfg ) {    
      print "Reading of $_[0] is F A I L E D\n" and return undef ;
    }
    %rcfg = %cfg ;
    untie %cfg   ;
    
    return \%rcfg ;
}

