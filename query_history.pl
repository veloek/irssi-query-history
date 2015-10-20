use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.0.1';
%IRSSI = (
    authors     => 'Vegard Løkken',
    contact     => 'vegard@loekken.org',
    name        => 'Query history',
    description => 'Show some lines of history from log in new query',
    license     => 'MIT'
);

use constant MAX_ENTRIES => 10;

sub sig_query_created {
    my ($query, $auto) = @_;
    my $qwin = $query->window();
    my $name = $query->{name};
    my $servertag = $query->{server_tag};

    # Find correct log file
    #
    # Loop through open logs and find the one that matches
    # name and servertag to get the correct filename.
    my $filename = '';
    my @active_logs = Irssi::logs();

    foreach my $log (@active_logs) {
        my $fname = $log->{real_fname};

        foreach my $intermediate ($log->{items}) {
            foreach my $logitem (@$intermediate) {

                if ($logitem->{name} == $name &&
                    $logitem->{servertag} == $servertag) {

                    $filename = $fname;
                }
            }
        }
    }

    # Read all log entries
    #
    # TODO: Only read end of file for better performance
    # Hard to know how many lines to read though since we are
    # stripping unecessary "empty" lines
    my @log = ();

    if (open (my $fh, '<:encoding(UTF-8)', $filename)) {
        $qwin->print('--- Query history with '.$name.':');

        ENTRY:
        while (my $entry = <$fh>) {
            chomp $entry;

            # Skip "log opened/closed" messages
            next ENTRY if ($entry =~ /^--- Log (opened|closed)/);

            # Skip "-!- Irssi" messages
            next ENTRY if ($entry =~ /^\d\d:\d\d -!- Irssi:/);

            push(@log, $entry);
        }

        # Print up to MAX_ENTRIES log entries from the end
        my $logsize = @log;

        for (my $i = $logsize-(MAX_ENTRIES); $i < $logsize; $i++) {
            if ($i > 0) {
                $qwin->print(@log[$i]);
            }
        }

    } else {
        Irssi::print('query_history.pl: No active log for '.
            $name.'@'.$servertag);
    }
}

Irssi::signal_add_last('query created', 'sig_query_created');
