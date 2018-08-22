#!/usr/bin/perl

my $file = $ARGV[0];

open FILE, $file;

my @lines = <FILE>;

open OUTFILE, ">>$file\_pronouncer.txt";

foreach $line(@lines){
	
	$line =~ s/ so / sow /ig;
	$line =~ s/ So / Sow /ig;
	$line =~ s/ do / doo /ig;
	$line =~ s/ their / there /ig;
	
	$line =~ s/ or / awe /ig;
	$line =~ s/ that / vat /ig;
	
	$line =~ s/ Close / Cloze /ig;
	print OUTFILE $line;
	
	
	
}