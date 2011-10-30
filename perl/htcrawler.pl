#!/usr/bin/perl
##
# 2009 Kurt P. Hundeck (whereiskurt@gmail.com)
#
# Recursively search through '--path' for files that match '--match' regex,
# slurp those files up, and output them as descendents of apache conf
# '<Directory ...>$slurped</Directory'.  Count and warn matches of 'RedirectBase'
#
# Usage:  
#           perl htcrawler.pl > htaccess.conf
#        or
#           perl htcrawler.pl --path=./ --match='\.htaccess$' > htaccess.conf
#        or
#           ./htcrawler.pl --path=/var/www/somesite.com/ > somesite.com.conf
#
# NOTE: It's the 'AccessFileName .htaccess' (default), it *could* be something
#       else, use '--match' to override.
#
use strict;
use warnings;

use English;
use Data::Dumper;
use Getopt::Long          qw(GetOptions);
use File::Find            qw(find);          
use File::Spec::Functions qw(rel2abs splitdir);
use File::Basename        qw(dirname);

##Set some reasonable defaults
my %argv = ( 
  'startpath' => dirname(rel2abs($0)), ## Real fullpath of script, default.
  'match'     => qr{\.htaccess$},      ## Regex for ".htaccess" files
  'skip'      => qr{^((.cvs)|(.svn))$},
);

##Parse commandline
GetOptions ( 'startpath|path=s' => \$argv{'startpath'} ,
             'match=s'          => \$argv{'match'}     ,
             'skip=s'           => \$argv{'skip'}      ,
) or die "Can't parse commandline (!)";

my @matches; ##Holds the fullnames of matching files (/dir1/dir2/.htaccess)

##Find files that match our criteria.
File::Find::find({ 'preprocess' => \&skiprcs ,   #Filter hook
                   'wanted'     => \&wanted  , } #Check match hook
                 , $argv{'startpath'});

sub skiprcs {
  ## 'grep' through the arglist (@_) and return things that
  ## don't match .cvs|.svn
  return grep { !/$argv{'skip'}/ } @_;
};

sub wanted {
  ##Add *fullpath* filename to matches, if we matched.
  if ($File::Find::name =~ m/$argv{'match'}/i) {
    push @matches, $File::Find::name;
  }
}

if (not @matches ) { 
  die "No files matched '$argv{'match'}' in path '$argv{'startpath'}'.\n";
}

##Sort by shortest path depth (ie. '/folder' before '/folder/subfolder')
##by comparying the length of arrays returned by 'splitdir'
@matches = sort { splitdir($a) <=> splitdir($b) } @matches;

my (%errflag, $errcount);

## Hash lookup to support different failures for conversion.  Certain
## pragmas won't convert 1-to-1 (like "RedirectBase"), these are the rules.
my %error_lkp = (
  'RedirectBase' => { 
    're'=>qr/RedirectBase/ix, 
    'msg'=>"##WARNING! RedirectBase' does't convert correctly. Check manually!",
   },
  'OtherParamLabel'   => { 
     're'=>qr/ApacheParam*/ix, 
     'msg'=>"##WARNING! Apache params not supported. ;-)" 
   },
);

foreach my $file (@matches) {
  ##Perl5 'slurp' $file idiom
  my $text = do { local( @ARGV, $RS ) = $file ; <> } ;

  if ($text) {
    ##Cleanup leading/trailing whitespace
    $text =~ s/^(.+?)\s*$/$1/gmix; #ltrim()
    $text =~ s/^\s*(.+?)$/$1/gmix; #rtrim()

    # Use the error lookup to see if the text contains things that don't
    # convert from .htaccess (like RedirectBase..)
    while( my ($key, $value) = each(%error_lkp)) {
      my $re  = $value->{'re'};   #Each error has it's own match pattern
      my $msg = $value->{'msg'};  #and error message.

      ##If the text matched the error regex, insert a warning $msg
      ## and track/count it.
      if (my $count = $text =~ s/^(.*?$re.*?)$/$RS##$msg$RS$1/gmix) {
        $errflag{$key}+=$count;
        $errcount +=$count;
      }
    }

    ##Add a "tab" infront of each line
    $text =~ s/^(.+?)$/\t$1/gmix;  
    ##Add a newline, back.
    $text .= $RS;
  }
  else {
   $text = ""; ##NOTE: $text is undef until we make it an "empty string"
  }

  my $dir = dirname($file); 
  print "<Directory $dir >$RS";
  print $text;
  print "</Directory>$RS";

}

## Output a commented block (Apache style) with any erros we found.
if ($errcount > 0) {
  ##Convert our %errflag to a nicely Dump'd output.
  my $errors = Data::Dumper->Dump( [ \%errflag ], [ qw(*ErrorTypeFound) ] );

  ##Append '#' infront of each line of $errors.
  $errors =~ s/^(.+?)$/#$1/gmix;

  print $RS;
  print "######################################################$RS";
  print "#Total Warnings: $errcount $RS";
  print $errors;
  print "######################################################$RS";
  print $RS;
}

print "######################################################$RS";
print "## Total Files processed: " . scalar @matches . $RS;
print "######################################################$RS";
print $RS;
print "## Please test before going live, no guarantees! $RS";
