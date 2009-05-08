#!/usr/bin/perl

=head1 NAME

vpn-status.pl

=head1 AUTHOR

Kevin Reedy
kevinreedy@gmail.com

=head1 SYNOPSIS

Run with no parameters, outputs HTML

=head1 DESCRIPTION

Uses OpenVPN::StatusLog to parse OpenVPN's status log. Displays the parsed information in HTML Tables

=cut

use strict;
use warnings;
use OpenVPN::StatusLog;

=head1 FUNCTIONS

=over 4

=item generate_table(@array_of_hashes)

Generates an HTML Table from an Array of Hashes. Uses the first hash's keys as the table headers

=cut 

sub generate_table {
    my @rows = @_;

    my $return = "<table border=1>\n";

    # Generate Header Row from kyes
    $return .= " <tr>\n";
    while(my ($key, $value) = each (%{$rows[0]})) {
        $return .= "  <td><b>$key</b></td>\n";
    }
    $return .= " </tr>\n";
    
    # Generate Data Rows
    foreach my $row (@rows) {
        $return .= " <tr>\n";
        while (my ($key, $value) = each(%$row)) {
            $return .= ("  <td>$value</td>\n");
        }
        $return .= " </tr>\n";
    }

    $return .= "</table>\n";
    
    return $return;
}

=back

=cut


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
<title>OpenVPN Status Table</title>
</head>
<body>
ENDHEAD

# Print Client Table
print "<h1>Client Table</h1>\n";
print generate_table(@clients);

# Print Routing Table
print "<h1>Routing Table</h1>\n";
print generate_table(@routes);

# Print Footer
print <<ENDFOOT;
</body>
</html>
ENDFOOT

