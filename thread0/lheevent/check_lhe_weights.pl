#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $expected_weights;
my $min_weights = 5;
my $verbose = 0;
my $show_mismatches = 0;
my $help = 0;

GetOptions(
    'expected=i'   => \$expected_weights,
    'min-weights=i' => \$min_weights,
    'verbose'      => \$verbose,
    'mismatches'   => \$show_mismatches,
    'help'         => \$help,
) or die "Error in command line arguments\n";

if ($help || @ARGV == 0) {
    print "Usage: $0 [options] <lhe_file>\n";
    print "\nOptions:\n";
    print "  --expected=N      Expected number of weights per event\n";
    print "  --min-weights=N   Minimum acceptable weights per event (default: 5)\n";
    print "  --mismatches      Show event numbers that don't match expected count\n";
    print "  --verbose         Show detailed per-event information\n";
    print "  --help            Show this help message\n";
    print "\nExamples:\n";
    print "  $0 file.lhe\n";
    print "  $0 --expected=5 file.lhe\n";
    print "  $0 --expected=889 --min-weights=10 file.lhe\n";
    print "  $0 --expected=5 --mismatches file.lhe\n";
    print "\nExit codes:\n";
    print "  0 - Success: all validations passed\n";
    print "  1 - Error: inconsistent weights, too few weights, or mismatched expected count\n";
    exit 0;
}

my $file = $ARGV[0];
die "File not found: $file\n" unless -e $file;

my $in_event = 0;
my $in_weights = 0;
my $event_count = 0;
my $weight_count = 0;
my %weight_counts;
my $total_weights = 0;
my @mismatched_events;
my @low_weight_events;

print "Checking LHE file: $file\n";
if (defined $expected_weights) {
    print "Expected weights per event: $expected_weights\n";
}
print "Minimum acceptable weights: $min_weights\n";
print "=" x 60 . "\n";

open my $fh, '<', $file or die "Cannot open $file: $!\n";

while (my $line = <$fh>) {
    # Track event boundaries (handle attributes in event tag)
    if ($line =~ /<event[\s>]/) {
        $in_event = 1;
        $event_count++;
        $weight_count = 0;
    }
    elsif ($line =~ /<\/event>/) {
        $in_event = 0;
        $weight_counts{$weight_count}++;
        $total_weights += $weight_count;

        # Check for minimum weight threshold
        if ($weight_count < $min_weights) {
            push @low_weight_events, {
                event_num => $event_count,
                found => $weight_count
            };
        }

        # Check against expected weights
        if (defined $expected_weights && $weight_count != $expected_weights) {
            push @mismatched_events, {
                event_num => $event_count,
                found => $weight_count,
                expected => $expected_weights
            };
        }

        # Verbose output
        if ($verbose) {
            printf "Event %5d: %3d weight(s)", $event_count, $weight_count;
            if ($weight_count < $min_weights) {
                print " ✗ (too few!)";
            } elsif (defined $expected_weights) {
                if ($weight_count == $expected_weights) {
                    print " ✓";
                } else {
                    print " ✗ (expected $expected_weights)";
                }
            }
            print "\n";
        }
    }

    # Track weights section
    elsif ($in_event) {
        if ($line =~ /<rwgt>/ || $line =~ /<weights>/) {
            $in_weights = 1;
        }
        elsif ($line =~ /<\/rwgt>/ || $line =~ /<\/weights>/) {
            $in_weights = 0;
        }
        elsif ($in_weights && $line =~ /<wgt[^>]*>/) {
            $weight_count++;
        }
    }
}

close $fh;

# Print results
print "Total events found: $event_count\n";
print "\n";

if ($event_count > 0) {
    my $avg_weights = $total_weights / $event_count;
    print "Total weights counted: $total_weights\n";
    print "Average weights per event: " . sprintf("%.2f", $avg_weights) . "\n";
    print "\n";

    print "Weight count distribution:\n";
    print "-" x 60 . "\n";
    printf "%-20s | %-15s | %s\n", "Weights per event", "Number of events", "Percentage";
    print "-" x 60 . "\n";

    foreach my $count (sort { $a <=> $b } keys %weight_counts) {
        my $num_events = $weight_counts{$count};
        my $percentage = ($num_events / $event_count) * 100;
        printf "%-20d | %-15d | %.2f%%\n", $count, $num_events, $percentage;
    }

    # Check consistency
    print "\n";
    my $is_consistent = (keys %weight_counts == 1);
    if ($is_consistent) {
        my ($count) = keys %weight_counts;
        print "✓ Consistent: All events have $count weight(s)\n";
    } else {
        print "✗ FAILURE: Inconsistent weight counts across events!\n";
        my @counts = sort { $a <=> $b } keys %weight_counts;
        print "  Range: $counts[0] to $counts[-1] weights per event\n";
    }

    # Check minimum weights threshold
    my $low_count = scalar @low_weight_events;
    if ($low_count > 0) {
        print "\n";
        print "✗ FAILURE: Found $low_count event(s) with fewer than $min_weights weights!\n";
        if ($show_mismatches) {
            print "\nEvents with too few weights:\n";
            print "-" x 60 . "\n";
            printf "%-15s | %s\n", "Event number", "Found weights";
            print "-" x 60 . "\n";
            my $max_show = 50;
            my $shown = 0;
            foreach my $event (@low_weight_events) {
                last if $shown >= $max_show;
                printf "%-15d | %d\n", $event->{event_num}, $event->{found};
                $shown++;
            }
            if ($low_count > $max_show) {
                print "... and " . ($low_count - $max_show) . " more\n";
            }
        } else {
            print "  (use --mismatches to see which events are wrong)\n";
        }
    }

    # Validation against expected weights
    if (defined $expected_weights) {
        print "\n";
        print "Validation Results:\n";
        print "-" x 60 . "\n";

        my $mismatches = scalar @mismatched_events;
        my $matches = $event_count - $mismatches;
        my $match_percentage = ($matches / $event_count) * 100;

        printf "Events matching expected count: %d / %d (%.2f%%)\n",
               $matches, $event_count, $match_percentage;
        printf "Events with wrong count:        %d / %d (%.2f%%)\n",
               $mismatches, $event_count, (100 - $match_percentage);

        if ($mismatches == 0) {
            print "\n✓ SUCCESS: All events have the expected $expected_weights weight(s)!\n";
        } else {
            print "\n✗ FAILURE: Found $mismatches event(s) with incorrect weight count!\n";

            # Show mismatched events if requested
            if ($show_mismatches) {
                print "\nMismatched events:\n";
                print "-" x 60 . "\n";
                printf "%-15s | %-15s | %s\n", "Event number", "Found weights", "Expected";
                print "-" x 60 . "\n";

                my $max_show = 50;
                my $shown = 0;
                foreach my $event (@mismatched_events) {
                    last if $shown >= $max_show;
                    printf "%-15d | %-15d | %d\n",
                           $event->{event_num}, $event->{found}, $event->{expected};
                    $shown++;
                }

                if ($mismatches > $max_show) {
                    print "... and " . ($mismatches - $max_show) . " more\n";
                    print "(showing first $max_show mismatches)\n";
                }
            } else {
                print "  (use --mismatches to see which events are wrong)\n";
            }
        }
    }

    print "=" x 60 . "\n";

    # Determine exit code
    my $has_errors = 0;
    $has_errors = 1 if !$is_consistent;
    $has_errors = 1 if $low_count > 0;
    $has_errors = 1 if (defined $expected_weights && scalar @mismatched_events > 0);

    if ($has_errors) {
        print "\nExit code: 1 (FAILURE)\n";
        exit 1;
    } else {
        print "\nExit code: 0 (SUCCESS)\n";
        exit 0;
    }
} else {
    print "No events found in file!\n";
    print "=" x 60 . "\n";
    exit 1;
}
