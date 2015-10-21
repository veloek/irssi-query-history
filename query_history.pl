use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.1.0';
%IRSSI = (
    authors     => 'Vegard Løkken',
    contact     => 'vegard@loekken.org',
    name        => 'Query history',
    description => 'Show some lines of history from log in new query',
    license     => 'MIT'
);

# Helper function to read a number of lines at the end of file
# With help from http://stackoverflow.com/a/12017327
sub log_tail {
    my ($file, $num_lines) = @_;

    my @result = ();
    my $count = 0;
    my $filesize = -s $file;
    my $offset = -2; # skip two last characters: \n and ^Z in the end of file

    if (open (my $fh, '<:raw', $file)) {

        # Read lines
        while (abs($offset) <= $filesize && $count < $num_lines) {
            my $line = '';

            # Read backwards until we reach newline
            while (abs($offset) <= $filesize) {

                # Move backwards byte by byte
                seek($fh, $offset--, 2);

                # Get the char
                my $char = getc($fh);

                # If char is newline, break loop
                last if ($char eq "\n");

                $line = $char.$line;
            }

            # Skip "log opened/closed" messages
            next if ($line =~ /^--- Log (opened|closed)/);

            # Skip "-!- " messages since they're usually status msgs
            next if ($line =~ /^\d\d:\d\d -!- /);

            # Insert line to beginning of result array
            unshift(@result, '%b-%n!%b-%n '.$line);

            # Increment counter to know how many lines we've got
            $count++;
        }
    }

    return(@result);
}

sub sig_query_created {
    my $query = @_[0];
    my $qwin = $query->window();
    my $name = $query->{name};
    my $servertag = $query->{server_tag};

    # Find correct log file
    #
    # Loop through open logs and find the one that matches
    # name and servertag to get the correct filename.
    my $filename;
    my @active_logs = Irssi::logs();

    foreach my $log (@active_logs) {
        my $fname = $log->{real_fname};

        foreach my $items ($log->{items}) {
            foreach my $logitem (@$items) {

                if ($logitem->{name} eq $name &&
                    $logitem->{servertag} eq $servertag) {

                    $filename = $fname;
                }
            }
        }
    }

    if (defined($filename)) {

        # Read log entries from the end of log file
        my $max_entries = Irssi::settings_get_int('query_history_num');
        my @logs = log_tail($filename, $max_entries);

        # Print to query window
        if (scalar(@logs) > 0) {
            $qwin->print(join("\n", @logs), MSGLEVEL_CLIENTCRAP);
        }

    } else {
        Irssi::print('query_history.pl: No active log for '.
            $name.'@'.$servertag);
    }
}

Irssi::settings_add_int($IRSSI{name}, 'query_history_num', 10);
Irssi::signal_add_last('query created', 'sig_query_created');
