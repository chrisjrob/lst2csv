#!/usr/bin/perl.exe
#
# Converts CSV to SIF format
#
use strict;
use warnings;

my $csvfile = 'C:/Barclays/bbm.csv';
my $siffile = 'C:/Barclays/import.sif';

test_source_file();
process();
test_destination_file();
rename_source_file ();

print "\nPress ENTER to exit\n";
<STDIN>;
exit;

# End of main program

sub rename_source_file {
    if (-e "$csvfile.xxx") {
        unlink ("$csvfile.xxx") or die "Cannot delete $csvfile.xxx: $!";
    }
    rename ("$csvfile", "$csvfile.xxx") or die "Cannot rename $csvfile to $csvfile.xxx: $!";
    print "Renamed $csvfile to $csvfile.xxx\n";

    return;
}

sub test_destination_file {
    if (-z $siffile) {
        print "\n$siffile has NOT been created successfully\n";
    } else {
        print "\n$siffile has been created successfully\n";
    }

    return;
}

sub test_source_file {
    my $query;
    until (-e $csvfile) {
        do {
            system("cls");
            print "\n";
            print "$csvfile does not exist.\n\n";

            print "Before running this program you must export\n";
            print "from ADP Kpay by confirming the period payroll\n";
            print "and running the 'Transfer Autopay to BBMII'\n";
            print "located in Payroll User-defined Reports.\n\n";

            print "[C]ontinue or [A]bort?\n";

            $query = <STDIN>;
            chomp ($query);
            if ($query =~ /^[Aa]/) {
                exit;
            }

        } until ($query =~ /^[Cc]/);
    };

    return;
}

sub process {
    system("cls");
    print "\n";
    if (-e "$siffile") {
            unlink ("$siffile") or die "Cannot delete $siffile: $!";
    }

    open ( my $fh_CSVFILE, '<', $csvfile) or die "Cannot read $csvfile: $!";
    open ( my $fh_SIFFILE, '>', $siffile) or die "Cannot create $siffile: $!";

    my ($sortcode, $name, $account, $amount, $narrative, $type);
    while (defined (my $line = <$fh_CSVFILE>)) {
            chomp ($line);

            # Remove all quotes and spaces
            $line =~ s/[\"\ ]//g;

            # Barclays.net does not permit underscores - replace with a space
            $line =~ s/\_/ /g;

            ($sortcode, $name, $account, $amount, $narrative, $type) = split (/\,/, $line);

            $sortcode = fix ($sortcode, 6);
            $account  = fix ($account, 8);

            print $fh_SIFFILE "$sortcode,$name,$account,$amount,$narrative,$type\n";
            print "$sortcode,$name,$account,$amount,$narrative,$type\n";
    }
    close($fh_CSVFILE) or die "Cannot close $csvfile: $!";
    close ($fh_SIFFILE) or die "Cannot close $siffile: $!";

    return;
}

sub fix {
    my ($number, $places) = @_;

    $places = "%0" . $places . "d";

    return sprintf($places, $number);
}
