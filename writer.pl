use XML::Simple;
use Data::Dumper;
use DBI;
use POSIX 'strftime';
use XML::Writer;
use IO::File;

## Trim both ends to remove whitespace.
sub  trim {
  my $s = shift; $s =~ s/^\s+|\s+$//g;
  return $s;
}

sub hashConfigurations {
  my ($configurations) = @_;
  my %config = ();
  open(IN, $configurations);
  my @config_array = <IN>;
  close(IN);

  foreach $line (@config_array){
    my @pair = split("=", $line);
    my $key = &trim($pair[0]);
    my $value = &trim($pair[1]);
    $config{$key} = $value;
  }
  return %config;
}

sub adminConfirmation{
 my $userId = $_[0];
 print "Pleae confirm if you want to add $userId [Y/N] :-";
 chomp ($_=<STDIN>);
 if (/^[yn]/i){
  if (/^n/i){
   print "Canceled::\"$userId\" will not be added to Leadscope \n";
   exit; 
  }
  if (/^y/i){
   print "Success:: $userId has been added to Leadscope \n";
  }
  }
 else {
  print "You Have Entered and Incorrect Option\n";
  print "Valid Options are [Y/N]\n";
  &adminConfirmation($userId);
 }
}
sub XML_Parse {
 ## Read XML file.
 my %config = @_;
 my $xmlPath = $config{'xmlPath'};

 my $xml = XML::Simple->new( );
 my $input = $xml->XMLin($xmlPath, forcearray => 1);

 my @output=();
 foreach $ID (@{$input->{application}{LeadScopeEnterpriseServer}{key}{server}{key}{'auth.principal.name'}{value}}){

    push(@output,$ID->{content});
  }
  print ">>>>>>>>>>>>>>Below is the list of active users>>>>>>>>>>>>>>>\n";
  foreach $id (@output){
    print "$id \n"
  }
  return @output;
}
 sub XML_Write {
 my %config = @_;
 my $xmlPath = $config{'xmlPath'};
 print "Enter User ID to provide access:-";
 $newUser = <STDIN>;
 $newUser = &trim($newUser);
 &adminConfirmation($newUser); 
 open(FILE,"$xmlPath") || die "can't open file for read\n";
 my @lines=<FILE>;
 close(FILE);
 open(FILE,">$xmlPath")|| die "can't open file for write\n";
 foreach $line (@lines){
    print FILE $line;
    print FILE "<value type=\"java.lang.String\">$newUser</value>\n" if($line =~ /<key name="auth.principal.name">/); #Insert newUser Id along with required text. 
  }
 close(FILE);

}

$config_file = shift;
%config_hash = &hashConfigurations($config_file);
my @activeUsers = &XML_Parse(%config_hash);
#foreach $id (@activeUsers){
 # print "$id \n"
#}
XML_Write(%config_hash);

