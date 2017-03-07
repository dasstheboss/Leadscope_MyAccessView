#!/usr/local/bin/perl
use XML::Simple;
use Data::Dumper;
use DBI;
use POSIX 'strftime';

## Trim both ends to remove whitespace.
sub  trim {
  my $s = shift; $s =~ s/^\s+|\s+$//g;
  return $s;
}

## Read Configurations into Hash
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

sub XML_Parse {
  ## Read XML file.
  my %config = @_;
  my $xmlPath = $config{'xmlPath'};
  #print $xmlpath."\n";
  my $xml = XML::Simple->new( );
  my $input = $xml->XMLin($xmlPath, forcearray => 1);

  ## Extract active user IDs.
  my @output=();
  foreach $ID (@{$input->{application}{LeadScopeEnterpriseServer}{key}{server}{key}{'auth.principal.name'}{value}}){
    #print $ID->{content}."\n";
    push(@output,$ID->{content});
  }
  return @output;
}

sub queryString {
  my ($ID) = @_;
  my $queryString = "INSERT INTO LSE_OWNER.ACTIVE_USERS (System_ID) SELECT '$ID' FROM DUAL WHERE NOT EXISTS (SELECT * FROM LSE_OWNER.ACTIVE_USERS WHERE System_ID='$ID')";
  return $queryString;
}

sub dbPerform {
  my (%config) = @_;
  my @userIDs = &XML_Parse(%config);
  my $driver = $config{'driver'};
  my $database = $config{'database'};
  my $dsn = "DBI:$driver:$database";
  my $userid = $config{'userID'};
  my $passw0rd = $config{'passw0rd'};
 
  ############Database connection starts ############
  require $config{'oracleEnvironment'};
  my $dbh = DBI->connect($dsn, $userid, $passw0rd) or die $DBI::errstri;
  ############Truncate table before input ###########
  #my $truncater = $dbh->execute("TRUNCATE TABLE LSE_OWNER.ACTIVE_USERS");
  my $truncater = $dbh->prepare("delete from LSE_OWNER.active_users");
  $truncater->execute() or die $DBI::errstr;

  ############Open output from XML_Parse routine ############
  foreach $systemID (@userIDs){
    ##################Execute query on database #################
    my $query = &queryString($systemID);
    my $sth = $dbh->prepare($query);
    $sth->execute() or die $DBI::errstr;
    #print "$query\n";
    $sth->finish();
  }
  $dbh->disconnect; #Disconnect
  &logNotify($config{'logPath'}) or die; #Log change in logFile.
}

sub logNotify {
  my ($logPath) = @_;
  my $date = strftime '%Y-%m-%d,%H:%M', localtime;
  open ($logFile, '>>', $logPath) or die;
  print $logFile "Logged success at ".$date.".\n";
  close $logFile;
}

## Read configuration file and evoke hashing configurations.
$config_file = shift;
%config_hash = &hashConfigurations($config_file);
## Update database table with any changes.
&dbPerform(%config_hash);
