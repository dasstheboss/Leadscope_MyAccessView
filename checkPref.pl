#!/usr/local/bin/perl
## Script runs on crontab and compares if Checksum of a file has changed


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

## Read config file using subroutines.
my $config_file = shift;
my %config_hash = &hashConfigurations($config_file);
my $curr_CheckSum = $config_hash{'checksumPath'};
open(IN, $curr_CheckSum);
my @checksum = <IN>;
close(IN);

#  # Read existing checksum from file.
my $currentCheckSum = $checksum[0];

# Read current checksum on target file.
my $temp = `sha256sum $config_hash{xmlPath}`;
my @temp2 = split(/  /,$temp);
my $newCheckSum = $temp2[0];

## Compare if checkSum are equal or not.
if ($currentCheckSum eq $newCheckSum){
  exit;
}
elsif ($currentCheckSum ne $newCheckSum){
  system("/usr/local/bin/perl /opt/lse/LeadscopeMyAccess/XML_Reader.pl /opt/lse/LeadscopeMyAccess/config.txt");
  open ($writeFile, '>', $curr_CheckSum) or die;
  print $writeFile $newCheckSum;
  close $writeFile;
}
