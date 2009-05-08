#!/usr/bin/perl

=head1 NAME

network-diagram.pl

=head1 AUTHOR

Kevin Reedy
kevinreedy@gmail.com

=head1 SYNOPSIS

Run with no parameters, outputs HTML

=head1 DESCRIPTION

Uses OpenVPN::StatusLog to parse OpenVPN's status log. Displays the parsed information as a Network Diagram

=head1 TODO

=over 4

=item

Move the name of each node to below or above the icon

=item

Query the Chicago VPN Server once it is running

=item

Draw Lines using javascript or CSS Tricks between nodes

=item

Add javascript to display more information about a node onClick or onHover

=item

If node is a router, query what devices are connected to it using NMAP, or the router's ARP table

=item

Show disconnected clients from /etc/openvpn/ipp.txt and /etc/openvpn/ccd/ as well

=back

=cut
 
use strict;
use warnings;
use Math::Trig;
use OpenVPN::StatusLog;

# Simple Round Function
sub round{
    my $number = shift;
    return int($number + .5);
}

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

# HTTP Header

# Print Headers
print <<ENDHEAD;
Content-type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-type" content="text/html;charset=iso-8859-1">
<link rel="stylesheet" type="text/css" href="network-diagram.css" />
<title>Network Diagram</title>
</head>
<body>
<div id="area">
ENDHEAD


# Print vpn boxes
# Icons are 48px, so 176px means centered at 200px
print('<div class="vpn" id="chi1" style="left: 176px; top: 176px">chi1</div>' . "\n");
print('<div class="vpn" id="sf1"  style="left: 576px; top: 176px">sf1</div>' . "\n");

# Figure out how many times each client shows up in the routing table
my %client_count;
foreach my $route (@routes) {
    # Get Common Name from Hash References
    my $name = $$route{'Common Name'};
    
    # Increment the count if it exists, or start it at 1
    if($client_count{$name}) {
        $client_count{$name}++;
    } else {
        $client_count{$name} = 1;
    }
}


# Counter starts as 1, since we are going to draw a line between the VPN boxes as well
my $i = 1; 

# Print out the clients for sf1
foreach (@clients) {
    # Dereference the hash
    my %client = %$_;

    # Pull the name from the hash
    my $name = $client{'Common Name'};

    # Determine if this client is a router
    # AKA it has multiple enties in the routing table
    my $class = "client";
    $class = "router" if($client_count{$name} > 1);

    # Find the angle, starting at 180deg (which is where chi1 is)
    my $angle = 180 + (360 / (@clients + 1))*$i++;

    # find the left and top (subtract 48 to account for the 48px width) 
    my $left = 600 - 24 + round(150 * cos(deg2rad($angle)));
    my $top  = 200 - 24 + round(150 * sin(deg2rad($angle)));
    
    printf('<div class="%s" id="%s" style="left: %spx; top: %spx">%s</div>' . "\n", 
        $class,
        $name,
        $left,
        $top,
        $name,
    );
}

# Print Footer
print <<ENDFOOT;
</div>
</body>
</html>
ENDFOOT

