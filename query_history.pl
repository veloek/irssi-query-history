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
        ENTRY:
        while (my $entry = <$fh>) {
            chomp $entry;

            # Skip "log opened/closed" messages
            next ENTRY if ($entry =~ /^--- Log (opened|closed)/);

            # Skip "-!- Irssi" messages
            next ENTRY if ($entry =~ /^\d\d:\d\d -!- Irssi:/);

            push(@log, '%b-%n!%b-%n '.$entry);
        }

        # Print a number of log entries from the end
        my $logsize = @log;
        my $max_entries = Irssi::settings_get_int('query_history_num');
        my @output = ();

        for (my $i = $logsize-$max_entries; $i < $logsize; $i++) {
            if ($i > 0) {
                push(@output, @log[$i]);
            }
        }

        $qwin->print(join("\n", @output), MSGLEVEL_CLIENTCRAP);

    } else {
        Irssi::print('query_history.pl: No active log for '.
            $name.'@'.$servertag);
    }
}

Irssi::settings_add_int($IRSSI{name}, 'query_history_num', 10);
Irssi::signal_add_last('query created', 'sig_query_created');
