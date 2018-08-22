#!/usr/bin/perl

my $file = $ARGV[0];

open FILE, $file;

my @lines = <FILE>;

open OUTFILE, ">>$file\_you.txt";

foreach $line(@lines){
	
	$line =~ s/^I am/You are/ig;
	$line =~ s/I am/you are/ig;
	$line =~ s/^I /You /ig;
	$line =~ s/ I / you /ig;
	$line =~ s/^My /Your /ig;
	$line =~ s/ my / your /ig;
	$line =~ s/ me / you /ig;
	$line =~ s/ me\n/ you\n/ig;
	$line =~ s/ am / are /ig;
	$line =~ s/ myself / yourself /ig;
	$line =~ s/ I was / you were /ig;
	print OUTFILE $line;
	
	
	
}