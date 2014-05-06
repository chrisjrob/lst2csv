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

    my $group    = '';
    my $accid    = '';
    my $actype   = '';
    my $currency = 'GBP';
    my $sortcode = '';
    my $account  = '';
    my $ddmmyy   = '';

    print '"GROUP","ACC ID","ACCOUNT NO","TYPE","BANK CODE","CURR","ENTRY DATE","AS AT","AMOUNT","TLA CODE","CHEQUE NO","STATUS","DESCRIPTION"', "\n";

    while ( defined (my $line = <$fh_statement_file>) ) {
        chomp($line);

        # Find sort code in branch line
        if ( $line =~ /^\s+Branch\s+(\d\d-\d\d-\d\d)/ ) {
            $sortcode = $1;

        } elsif ( $line =~ /^\s+Id.*No\s+(\d{8})\s/ ) {
            $account = $1;

        # Line has no alphanumerics - probably blank, certainly not interesting
        } elsif ( $line !~ /\w/ ) {
            next;
            
        # Line has no numerics - probably a title line
        } elsif ( $line !~ /\d/ ) {
            next;

        # Line has no decimals - probably a title line
        } elsif ( $line !~ /\./ ) {
            next;

        # A balance line
        } elsif ( $line =~ /^\s+(Open|Clos)ing\s+
                                Balance\s+for\s+
                                (\d{2}\/\d{2}\/\d{2})\s+
                                ([\d,\.]+)\s+
                                (DR)?\s+$/x ) {
            my $asat = $1;
            if ($asat eq 'Clos') {
                $asat = 'Close';
            }
            $ddmmyy    = $2;
            my $balance = format_number($3);
            my $crdr      = $4;
            if ( (defined $crdr) and ( $crdr eq 'DR' ) ) {
                $balance *= -1;
                $balance  = format_number($balance);
            }

            $ddmmyy = convert_text_to_date($ddmmyy, 0);
            print "\"$group\",\"$accid\",\"$account\",\"$actype\",\"$sortcode\",\"$currency\",\"$ddmmyy\",\"$asat\",$balance,\"BAL\",\"\",\"\",\"Balance\"\n";

            if ($asat eq 'Close') {
                $ddmmyy = convert_text_to_date($ddmmyy, 1)
            }

#             # Temporary code to limit to first day only
#             if ($asat eq "Close") {
#                 last;
#             }

        # Assume a detail line
        } else {
            my $details  = substr( $line,  1, 18 ) . '    ' . substr( $line, 19, 18);
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
        
            my $status   = '';
            my $asat     = '';

            my $cheque   = '';
            if ($code =~ /^\d+$/) {
                $cheque = $code;
                $code   = 'CHQ';
            }

            print "\"$group\",\"$accid\",\"$account\",\"$actype\",\"$sortcode\",\"$currency\",\"$ddmmyy\",\"$asat\",$value,\"$code\",\"$cheque\",\"\",\"$details\"\n";

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

    my $dt;
    $dt = DateTime->new(
        year       => $yy,
        month      => $mm,
        day        => $dd,
    );

    $dt->add( days => $increment );

    # Remove as no compatible with older versions
    # return $dt->format_cldr('dd/MM/yy');
    return $dt->strftime('%d/%m/%y');
}

sub trim {
    my $text = shift;

    $text =~ s/\s+$//g;
    $text =~ s/^\s+//g;

    # $text =~ s/\s{2,}/ /g;

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
