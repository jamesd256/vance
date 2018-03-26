#!/usr/bin/perl

my $file = $ARGV[0];

open FILE, $file;

my @lines = <FILE>;

open OUTFILE, ">>$file\_you.txt";

foreach $line(@lines){
	
	$line =~ s/^I am/You are/g;
	$line =~ s/I am/you are/g;
	$line =~ s/^I /You /g;
	$line =~ s/ I / you /g;
	$line =~ s/^My /Your /g;
	$line =~ s/ my / your /g;
	$line =~ s/ me / you /g;
	$line =~ s/ me\n/ you\n/g;
	$line =~ s/ am / are /g;
	$line =~ s/ myself / yourself /g;
	print OUTFILE $line;
	
	
	
}