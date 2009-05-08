=head1 NAME

OpenVPN::StatusLog

=head1 AUTHOR

Kevin Reedy
kevinreedy@gmail.com

=head1 DESCRIPTION

A Class to represent OpenVPN's status log which is specified in the server side config

=cut

package OpenVPN::StatusLog;
use strict;
use warnings;

our $log_file;

=head1 METHODS

=over 4

=item new(log_file => status.log)

Constructor takes the path to the log file, but does not check if it is readable

=cut

sub new {
    my $self = shift;
    my %p    = @_;
    if($p{log_file}) {
        $log_file = $p{log_file};
    } else {
        die("Must pass log_file");
    }

    return $self;
}

=item parse(client_array => \@client_array, route_array => \@route_array)

Parses the status log file. Input is 2 array references (client_array and route_array).
Returns 1 on success.

=cut

sub parse {
    my $self = shift;
    my %p    = @_;

    # Return 0 if parameters were not passed
    return 0 unless($p{client_array} && $p{route_array});

    # Attempt to open status log file, return 0 on failure
    open(LOG, $log_file) or return 0;

    # Read in log file
    my @log = <LOG>;
    
    # Close status log file
    close(LOG);

    # Variables to store array references
    my $client_ref = $p{client_array};
    my $route_ref  = $p{route_array};
    my $current_ref;

    # When $headers_next is true, the next line in the log, should be header information
    my $headers_next = 0;
    my @headers;

    foreach my $line(@log) {
        # Remove newline from end of line
        chomp($line);

        # Stop once we hit the line END or GLOBAL STATS
        last if($line =~ /^END$/);
        last if($line =~ /^GLOBAL\sSTATS$/);

        # For now we want to skip the Updated Time, as it throws off header information
        next if ($line =~ /^Updated/);

        # Determine if we should change the current array reference
        if($line =~ /^OpenVPN\sCLIENT\sLIST$/) {
            # Set the reference
            $current_ref = $client_ref;

            # Headers will be the next row
            $headers_next = 1;
            
            next;
        } elsif($line =~ /^ROUTING\sTABLE$/) {
            # Set the reference
            $current_ref = $route_ref;

            # Headers will be the next row
            $headers_next = 1;
            
            next;
        }

        # Read Headers
        if($headers_next) {
            # Next line will no longer be headers
            $headers_next = 0;

            # Clear out the headers array
            @headers = ();

            # Headers are comma separated
            foreach my $header (split(/,/, $line)) {
                push(@headers, $header);
            }
            
            next;
        }

        # If $current_ref is set, this is data we care about
        if($current_ref) {
            # Data should be put into a hash and then pushed onto the current array
            my %h = ();

            # Values are comma separated
            my @values = split(/,/, $line);

            # Keep a counter so that we can assign the correct header
            for(my $i = 0; $i < @values; $i++) {
                # store data to temporary hash
                $h{$headers[$i]} = $values[$i];
            }
            
            # Push hash onto current array
            push(@$current_ref, \%h);
        }
    }
    
    return 1;
}

=back

=cut

1;

