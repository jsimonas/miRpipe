#!/bin/bash

function USAGE {
	echo ""
	echo "This script takes as an input deep sequencing reads in fastq.gz format. The script then processes the reads in the following order:"
	echo "unzips, cuts adaptor sequences, converts fastq to fasta and colapses the reads by holding the information about the number of sequences. "
	echo ""
	echo "Usage: process_reads.sh -o /home/user/results/project_ID_results/ -i home/user/samples/project_ID/ -s /home/user/pipe/inhouse_scripts/ "
	echo "    Options for process reads:"
	echo "        -o  <str>   path/to/results/folder/ eg.: /home/user/results/project_ID_results/"
	echo "        -i  <str>   path/to/raw_data/folder/ eg.: /home/user/user/samples/project_ID/"
	echo "        -s  <str>   path/to/script/folder/ eg.: /home/user/mirdeep2/inhouse_scripts/"
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="o:i:s:h"
declare SWITCH
declare output_folder
declare raw_data
declare script_folder

while getopts "$OPTSTRING" SWITCH ; do
	case $SWITCH in
		h) USAGE;
		   exit 0
		;;
		o) output_folder="$OPTARG"
		;;
		i) raw_data="$OPTARG"
		;;
		s) script_folder="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "process_reads.sh: $LINENO: %s\n" "script error: unhandled argument"
		exit 192
		;;
	esac
done

# # # create output folder if not exists # # #
IFS=$old_IFS     # restore default field separator 


if [ -e $output_folder ]; then
	echo "Accessing raw data..."
else
	mkdir $output_folder
	echo "Creating folder $output_folder"
fi

# # # create folders for each experiment run # # #
IFS=$'\r\n'

for run in $(ls $raw_data)
do
	cd $output_folder
	mkdir $run
	echo "The experiment run ID is: $run"

	path=$raw_data$run
	out_path=$output_folder$run

	for i in $(ls $path);
	do

		# # # define the input and output paths for each sample # # #
		stamp_path=$out_path/$i/miRpipe_out_$(eval date +%y%m%d%H%M)
		source_path=$path/$i
		copy_path=$out_path/$i

        # # # create folders for each sample # # #
		echo ""
		echo "The sample ID is: $i"
		if [[ -e $copy_path ]]; then
			echo
		else
			mkdir $copy_path
		fi
		cd $copy_path

		# # # create individual folders for each run # # #
		if [ -e $stamp_path ]; then
			echo
		else
			mkdir $stamp_path
		fi

		# go inside of each Sample subfolder, do the copy of the .gz file into the output directory and unzip the .gz there.
		cd $source_path
		for j in $(ls *.gz);
		do

			# # # copy unzipped files # # #
			cd $copy_path
			# # # check if .gz was copied # # #
			if [ -e $j ]; then
			echo
			else
				echo "Operating..."
				cp $source_path/$j .
			fi

			# # # unzipping files # # #
			echo "Un-zipping .gz file $j..."

			# # # check if .gz was unzipped # # #
			if [ -e *.fastq ]; then
			echo "$j was unzipped!"
            rm $j
			else
				gzip -d $j
				echo "Unzipping finished."
				echo
                rm $j
			fi
			
			# # # copy unzipped files to the stamp folder # # #
			echo "Move unzipped file as unclipped.fastq to $stamp_path."
			cp *.fastq $stamp_path/unclipped.fastq
			echo

			# # # start the process # # #
			cd $stamp_path

			# # # cut adapt # # #
			echo "cutadapt"
			cutadapt -b TGGAATTCTCGGGTGCCAAGG -m 18 -q 20 --discard-untrimmed unclipped.fastq > clipped.fastq
			rm unclipped.fastq
			echo "trimmed for adapters "

			echo

			# # # convert format # # # 
			echo "Converting fastq to fasta..."
			fastq2fasta.pl clipped.fastq > reads.fa
			rm clipped.fastq
			 
			# # # colapse reads # # #
			echo "Colapsing reads..."
			collapse_reads_md.pl reads.fa seq > reads_colapsed.fa
			
			# file check-up
			if [ -s reads_colapsed.fa ]; then
			echo "Reads of $i were colapsed and succesfully processed."
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			else
			echo "error: reads of  $i were not collapsed "
			exit 192
			fi
			
		done
	done

done

