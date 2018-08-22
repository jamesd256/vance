#!/bin/bash

base_name=$1

############
# Pre process text
###################
echo "Creating sub texts"
./pronouncer.pl ./text/$base_name.txt
./i2y.pl ./text/$base_name.txt_pronouncer.txt


mkdir text/$base_name\_tmp
cd text/$base_name\_tmp

split -d -l 40 ../$base_name.txt_pronouncer.txt $base_name\_split
split -d -l 40 ../$base_name.txt_pronouncer.txt_you.txt $base_name\_you_split
cd ../../


#################
# Start emulator phase
###############

echo "Starting emulator"
#printf "Run : \n\n ~/Android/Sdk/emulator/emulator -avd Pixel_XL_API_26  -use-system-libs\n\n"
~/Android/Sdk/emulator/emulator -avd Pixel_API_26  -use-system-libs & 

echo "Clearing logs"
adb logcat -c
#read -p "Press enter to continue"

echo "Pushing sub texts to emulator"

for i in $(ls ./text/$base_name\_tmp/);	do adb push ./text/$base_name\_tmp/$i /sdcard/Download/vance ; done


#adb push ./text/$base_name\_tmp/$base_name.txt_pronouncer.txt /sdcard/Download/$base_name\_i.txt
#adb push ./text/$base_name\_tmp/$base_name.txt_pronouncer.txt_you.txt /sdcard/Download/$base_name\_y.txt


echo "Starting tts2wav activity"
adb shell am start -n  com.imaginine.tts2wav.tts2wav/com.imaginine.tts2wav.tts2wav.MainActivity
echo "awaiting all done message"
adb logcat | while read LOGLINE; do [[ "${LOGLINE}" == *"ALL Finished"* ]] && pkill -P $$ adb; done
echo "wavs generated"	

echo "Retreiving audio from emulator"
mkdir wav/$base_name\_tmp
cd wav/$base_name\_tmp
adb shell 'ls /sdcard/Download/vance/*.wav' | tr -d '\r' | xargs -n1 adb pull
#adb pull /sdcard/Download/$base_name\_i.wav
#adb pull /sdcard/Download/$base_name\_y.wav

cd ../../

echo "Concatenating audio from emulator"

sox wav/$base_name\_tmp/$base_name\_split0* $base_name\_i.wav
sox wav/$base_name\_tmp/$base_name\_you_split0* $base_name\_y.wav



#############
#
# Build
#
############


echo "Building wav"

#read -p "Press enter to continue"

./build_audio.pl $base_name\_i.wav $base_name\_y.wav $base_name.wav

echo "Creating MP3"
ffmpeg -i $base_name.wav  $base_name.mp3



#read -p "Finished building, press enter to continue with cleanup"
#############
#
# Cleanup
#
############

echo "Removing audio from emulator"
#adb shell rm /sdcard/Download/$base_name\_i.wav
#adb shell rm /sdcard/Download/$base_name\_y.wav

echo "Removing texts from emulator"
#adb shell rm /sdcard/Download/$base_name\_i.txt
#adb shell rm /sdcard/Download/$base_name\_y.txt

adb shell rm /sdcard/Download/*

echo "Removing sub texts"
rm ./text/$base_name.txt_pronouncer.txt
rm ./text/$base_name.txt_pronouncer.txt_you.txt

echo "Removing tmp audio"
rm -rf wav/$base_name\_tmp/

echo "Removing tmp text"
rm -rf text/$base_name\_tmp/

echo "Remove I/You wavs"

rm $base_name.wav

echo "Remove output wavs"
rm $base_name\_i.wav
rm $base_name\_y.wav

echo "Clear emulator"	
adb shell rm /sdcard/Download/vance/*

echo "Close emulator"

kill `ps aux | grep -v grep | grep emulator | grep qemu | awk '{ print $2 }'`
