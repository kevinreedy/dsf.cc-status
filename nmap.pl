#!/usr/bin/perl

use strict;
use warnings;
use OpenVPN::StatusLog;

# Arrays to store tables
my @clients;
my @routes;

# Create a status log object from the log file
my $status = OpenVPN::StatusLog->new(log_file => "/var/log/openvpn/status.log");

# Parse the log file into these passed arrays
$status->parse(
    client_array => \@clients,
    route_array => \@routes,
) or die("Couldn't Parse Status Log");

foreach my $route (@routes) {
    my $network = $$route{'Virtual Address'};
    # Next unless address is in CIDR, 192.168.65.0/24 for example
    next unless $network =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/;
    
    # Run an nmap on the subnet
    #TODO Write or find an existing perl module to do this
    my $command = 'nmap -sP ' . $network;
    my @lines = `$command`;
    
    # Remove CIDR part
    my $filename = $network;
    $filename =~ s/\/\d{1,2}$//g;
    
    # Open Log File
    open (LOG, '>', "log/$filename") or next;

    # Go through log file
    foreach my $line (@lines) {
        # Skip the router (x.x.x.1)
        next if $line =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.1/;

        # Look for lines that show up hosts
        next unless $line =~ /^Host\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
        
        # Write to Log
        print(LOG "$1\n");
    }

    # Close File
    close (LOG);
}
