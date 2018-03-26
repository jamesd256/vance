#!/usr/bin/perl
use Data::Dumper;

my ($input_file_1, $input_file_2) = @ARGV;

my $context = {};

initialise_context();
generate_silences();
set_max_length();       
                                        
set_multiplier();


split_file(1);

split_file(2);

get_combined(1);

get_combined(2);

mix_audio();

cleanup();
	

sub initialise_context{

	$context->{"input_file"}->{"1"} = $input_file_1;
	$context->{"input_file"}->{"2"} = $input_file_2;
	
	$context->{"desired_audio_length"} = 786;
	$context->{"output_base"} = "./out";
	
	$context->{"output_folder"}->{1} = $context->{"output_base"} . "/1";
	$context->{"output_folder"}->{2} = $context->{"output_base"} . "/2";
	
	$context->{"binaural_folder"} = "./binaurals";
	$context->{"binaural_file_l"} = $context->{"binaural_folder"} . "/theta_l_20.wav";
	$context->{"binaural_file_r"} = $context->{"binaural_folder"} . "/theta_r_20.wav";
	
	$context->{"silence_folder"} = $context->{"output_base"} . "/silence";
	$context->{"gap_silence_length"} = "0.5";
	$context->{"intro_silence_length"} = "120";
	
	$context->{"combined_parts_folder"} = $context->{"output_base"} . "/combined";
	$context->{"male_voice_track_level"} = "0.25";
	$context->{"female_voice_track_level"} = "0.4";
	$context->{"binaural_track_level"} = "1.0";
	$context->{"silence_threshold"} = 1;	
	
	
	$context->{"outfile"} = "./affirmations.wav";
	
}

sub generate_silences{

	print "Building silence\n";
	my $short_silence_cmd = "sox -n -r 22050 -c 1 " . $context->{"silence_folder"} . "/silence.wav trim 0.0 " . $context->{"gap_silence_length"};
	my $intro_silence_cmd = "sox -n -r 22050 -c 1 " . $context->{"silence_folder"} . "/intro_silence.wav trim 0.0 " . $context->{"intro_silence_length"};
	`$short_silence_cmd`;
	`$intro_silence_cmd`;
	
}

sub set_max_length{
	
	$context->{"file1_length"} = get_length($context->{"input_file"}->{1});
	
	print "length of file1: " . $context->{"file1_length"} . "\n";
	$context->{"file2_length"} = get_length($context->{"input_file"}->{2});
	
	print "length of file2: " . $context->{"file2_length"} . "\n";
	
	if($context->{"file1_length"} > $context->{"file2_length"}){
		$context->{"max_audio_length"} = $context->{"file1_length"};
	}else{
		$context->{"max_audio_length"} = $context->{"file2_length"};
	}
	
	print "Max length: " . $context->{"max_audio_length"} . "\n";
	
}

sub set_multiplier{
	$context->{"multiplier"} = $context->{"desired_audio_length"} / $context->{"max_audio_length"};
	
	print "Multiplier: " . $context->{"multiplier"} . "\n";
}

sub split_file{
	
	my ($input_file_number) = @_;
	
	my $input_file = $context->{"input_file"}->{$input_file_number};
	my $output_folder = $context->{"output_folder"}->{$input_file_number};
	
	my $silence_threshold = $context->{"silence_threshold"};
	my $sox_cmd = "sox $input_file $output_folder/$input_file\_out.wav silence 1 0.2 $silence_threshold\%	1 0.2 $silence_threshold\% : newfile : restart";
	print "Sox cmd: $sox_cmd\n";
	`$sox_cmd`;	
	
}

sub get_combined{
	my ($input_file_number) = @_;
		
	print "tmp_output:" .  $context->{"output_folder"}->{$input_file_number} . "\n";	
	print "Input file:" .  $context->{"input_file"}->{$input_file_number} . "\n";
	
	my $split_count_cmd = "ls " . $context->{"output_folder"}->{$input_file_number} . "/*.wav | wc -l";
	$context->{"split_count"}->{$input_file_number} = `$split_count_cmd`;
	chomp $context->{"split_count"}->{$input_file_number};
	
	print "split_count: " . $context->{"split_count"}->{$input_file_number} . "\n";
	#print Dumper $context; 
	$context->{"number_of_files"} = int((1 / $context->{"multiplier"}) + 0.5);
	if($context->{"number_of_files"} eq 0){
		$context->{"number_of_files"} = 1;
	}
	
	print "number_of_files: " . $context->{"number_of_files"} . "\n";	
	
	if($context->{"multiplier"} > 1){
		
		for($j = 0; $j < $context->{"number_of_files"}*2; $j++){
			my $output_file_number = $j + 1;
			print "Running file number $output_file_number\n";
			
			combine_files($input_file_number, $output_file_number);
		}	
	}else{
		print Dumper $context;
		$context->{"parts_per_file"} = $context->{"split_count"}->{$input_file_number} / $context->{"number_of_files"};
		print "parts_per_file: " . $context->{"parts_per_file"} . "\n";
			
		
		for($j = 0; $j < $context->{"number_of_files"}; $j++){
			
			my $output_file_number = $j + 1;
			print "Running file number $output_file_number\n";		
			
			combine_files2($input_file_number, $output_file_number);
		}		
	}
}

sub combine_files{
	
	my ($input_file_number, $output_file_number) = @_;
	
	my $split_count = $context->{"split_count"}->{$input_file_number};
	my $part_offset = int((($split_count * $context->{"multiplier"}) * ($output_file_number)) + 0.5);
	print "part_offset: $part_offset\n";
			
	
	my $total_parts = int($split_count * $context->{"multiplier"}) + $part_offset;
	
	print "Total parts: $total_parts\n";
	
	my $input_file = $context->{"input_file"}->{$input_file_number};
	my $output_folder = $context->{"output_folder"}->{$input_file_number};
	
	my $combine_cmd = "sox " . $context->{"silence_folder"} . "/intro_silence.wav ";
	if($input_file_number eq 1){
		for ($i = $part_offset; $i < $total_parts; $i++){
			my $part_number = ($i % $split_count) + 1;
			$part_number = sprintf("%03d", $part_number);
			my $part_file_name = "$output_folder/$input_file\_out$part_number.wav";
			$combine_cmd .= "$part_file_name " . $context->{"silence_folder"} . "/silence.wav ";
		}
	}else{
		for ($i = $total_parts; $i > $part_offset; $i--){
			my $part_number = ($i % $split_count) + 1;
			$part_number = sprintf("%03d", $part_number);
			my $part_file_name = "$output_folder/$input_file\_out$part_number.wav";
			$combine_cmd .= "$part_file_name " . $context->{"silence_folder"} . "/silence.wav ";
		}
	}
	my $output_file_path = $context->{"combined_parts_folder"} . "/$input_file\_combined\_$output_file_number.wav";
	$combine_cmd .= " " . $output_file_path;
	$context->{"output_file"}->{$input_file_number}->{$output_file_number} = $output_file_path;
	
	
	
	print "combine cmd: $combine_cmd\n";
	
	`$combine_cmd`;
}

sub combine_files2{
	
	my ($input_file_number, $output_file_number) = @_;
	my $range_end = $output_file_number * $context->{"parts_per_file"}; 
	
	my $range_start = $range_end - $context->{"parts_per_file"} + 1;
	print "range_start: $range_start\n";
	print "range_end: $range_end\n";
	
	my $input_file = $context->{"input_file"}->{$input_file_number};
	my $output_folder = $context->{"output_folder"}->{$input_file_number};
	
	
	my $combine_cmd = "sox " . $context->{"silence_folder"} . "/intro_silence.wav ";	
		
	if($input_file_number eq 1){         
		for ($i = $range_start; $i < $range_end; $i++){
			
			my $part_number = $i;
			$part_number = sprintf("%03d", $part_number);
			my $part_file_name = "$output_folder/$input_file\_out$part_number.wav";
			$combine_cmd .= "$part_file_name " . $context->{"silence_folder"} . "/silence.wav ";
		}
	}else{	
		for ($i = $range_end; $i > $range_start; $i--){
			
			my $part_number = $i;
			$part_number = sprintf("%03d", $part_number);
			my $part_file_name = "$output_folder/$input_file\_out$part_number.wav";
			$combine_cmd .= "$part_file_name " . $context->{"silence_folder"} . "/silence.wav ";
		}
	}
	
	my $output_file_path = $context->{"combined_parts_folder"} . "/$input_file\_combined\_$output_file_number.wav";
	$combine_cmd .= " " . $output_file_path;
	$context->{"output_file"}->{$input_file_number}->{$output_file_number} = $output_file_path;
	
	print "combine cmd: $combine_cmd\n";
	
	`$combine_cmd`;
}

sub get_length{
	
	my ($file) = @_;
	
	my $sox_cmd = "soxi -D $file";
	
	my $length  = `$sox_cmd`;
	chomp $length;
	return $length;	
}

sub mix_audio{
	
	print "Mixing down audio tracks...\n";
	my $output_file_1 = $context->{"output_file"}->{1}->{1};
	my $output_file_2 = $context->{"output_file"}->{1}->{2};
	my $output_file_3 = $context->{"output_file"}->{2}->{1};
	my $output_file_4 = $context->{"output_file"}->{2}->{2};
	
	my $binaural_file_l = $context->{"binaural_file_l"};
	my $binaural_file_r = $context->{"binaural_file_r"};
	
	my $outfile = $context->{"outfile"};
	
	my $male_voice_track_level = $context->{"male_voice_track_level"};
	my $female_voice_track_level = $context->{"female_voice_track_level"};
	my $binaural_track_level = $context->{"binaural_track_level"};
	
	my $sox_remix_cmd = "sox -M -v $male_voice_track_level \"$output_file_1\" -v $male_voice_track_level \"$output_file_2\" -v $female_voice_track_level \"$output_file_3\" -v $female_voice_track_level \"$output_file_4\" -v $binaural_track_level \"$binaural_file_l\" -v $binaural_track_level \"$binaural_file_r\"  $outfile remix -m 1v1,2v0,3v0.7,4v0.3,5v1,6v0 1v0,2v1,3v0.3,4v0.7,5v0,6v1";
	
	print "remix command: " . $sox_remix_cmd . "\n";
	`$sox_remix_cmd`;

}

sub cleanup{

	$file_1_part_cleanup_cmd = "rm " . $context->{"output_folder"}->{1} . "/*";
	print "Cleanup file 1 parts: $file_1_part_cleanup_cmd\n";
	`$file_1_part_cleanup_cmd`;
	
	$file_2_part_cleanup_cmd = "rm " . $context->{"output_folder"}->{2} . "/*";                                                                                   
	print "Cleanup file 2 parts: $file_2_part_cleanup_cmd\n";
	`$file_2_part_cleanup_cmd`;
	
	$silence_cleanup_cmd = "rm " . $context->{"silence_folder"} . "/*";
	print "Silence file cleanup: $silence_cleanup_cmd\n";
	`$silence_cleanup_cmd`;

	$combined_cleanup_cmd = "rm " . $context->{"combined_parts_folder"} . "/*";
	print "Combined file cleanup: $combined_cleanup_cmd\n";
	`$combined_cleanup_cmd`;

	
	
}