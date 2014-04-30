#!/usr/bin/perl

use warnings;
use strict;

use DateTime;

foreach my $statement (@ARGV) {
    convert_statement($statement);
}

exit;

sub convert_statement {
    my $statement_file = shift;

    open( my $fh_statement_file, '<', $statement_file) or 
        die "Cannot open $statement_file: $!";

    my $ddmmyy;
    while ( defined (my $line = <$fh_statement_file>) ) {
        chomp($line);

        # Line has no alphanumerics - probably blank, certainly not interesting
        if ( $line !~ /\w/ ) {
            next;
            
        # Line has no numerics - probably a title line
        } elsif ( $line !~ /\d/ ) {
            next;

        # Line has no decimals - probably a title line
        } elsif ( $line !~ /\./ ) {
            next;

        # A balance line
        } elsif ( $line =~ /^\s+(Opening|Closing)\s+
                                Balance\s+for\s+
                                (\d{2}\/\d{2}\/\d{2})\s+
                                ([\d,\.]+)\s+
                                (DR)?\s+$/x ) {
            my $openclose = $1;
            $ddmmyy    = $2;
            my $balance = format_number($3);
            my $crdr      = $4;
            if ( (defined $crdr) and ( $crdr eq 'DR' ) ) {
                $balance *= -1;
                $balance  = format_number($balance);
            }

            $ddmmyy = convert_text_to_date($ddmmyy, 0);
            print "$ddmmyy,$openclose,Balance,,$balance\n";

            if ($openclose eq 'Closing') {
                $ddmmyy = convert_text_to_date($ddmmyy, 1)
            }

#             # Temporary code to limit to first day only
#             if ($openclose eq "Closing") {
#                 last;
#             }

        # Assume a detail line
        } else {
            my $details1 = trim( substr( $line,  1, 18 ) );
            my $details2 = trim( substr( $line, 19, 18 ) );
            my $code     = trim( substr( $line, 37,  7 ) );
            my $payments = trim( substr( $line, 46, 15 ) );
            my $receipts = trim( substr( $line, 63, 13 ) );
            if ($payments !~ /\d/) {
                $payments = 0;
            }
            if ($receipts !~ /\d/) {
                $receipts = 0;
            }

            if (($payments == 0) and ($receipts == 0)) {
                # Not a detail line
                next;
            }

            my $value    = $receipts - $payments;
            $value       = format_number($value);

            print "$ddmmyy,$details1,$details2,$code,$value\n";

        }


    }

    close( $fh_statement_file ) or
        die "Cannot close $statement_file: $!";


}

sub convert_text_to_date {
    my ($text, $increment) = @_;

    my ($dd, $mm, $yy) = split( /\//, $text);

    if ($yy < 50) {
        $yy += 2000;
    } elsif ($yy < 100) {
        $yy += 1900;
    } 

    my $dt = DateTime->new(
        year       => $yy,
        month      => $mm,
        day        => $dd,
    );

    $dt->add( days => $increment );

    return $dt->dmy('/');
}

sub trim {
    my $text = shift;

    $text =~ s/\s+$//g;
    $text =~ s/^\s+//g;

    $text =~ s/\s{2,}/ /g;

    $text =~ s/,//g;

    return $text;
}

sub format_number {
    my $text = shift;

    $text =~ s/,//g;

    return sprintf("%0.2f", $text);
}

__END__

=pod

=head1 LST2CSV

lst2csv - Convert Barclays BusinessMaster statements from LST to CSV

=head1 SYNOPSIS

lst2csv SAMPLE.LST > SAMPLE.CSV

=head1 DESCRIPTION

B<LST2CSV> will read the given input file(s) and print as CSV to STDOUT

=cut
