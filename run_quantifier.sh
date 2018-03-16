#!/bin/bash

function USAGE {
	echo ""
	echo "run_quantifier.sh is a runner of quantifier.pl module from mirdeep2 which quantifies known miRNAs from used miRBase database."
	echo "This script takes as input deep sequencing reads which were processed by process_reads.sh and/or filter_reads.sh scripts." 
	echo ""
	echo "Usage: run_quantifier.sh -o /home/user/results/project_ID_results/ -d  /home/user/miRpipe/databases/mature.fasta -a  /home/user/miRpipe/databases/hairpin.fasta"
	echo "    Options for quantify reads"
	echo "        -o  <str>   path/to/results/folder/ eg.: /home/user/results/project_ID_results"
	echo "        -d  <str>   path/to/mature.fasta eg.:  /home/user/miRpipe/databases/mature.fasta"
	echo "        -a  <str>   path/to/hairpin.fasta eg.:  /home/user/miRpipe/databases/hairpin.fasta"	
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="o:d:a:h"
declare SWITCH
declare main_dir
declare mirna_mature=''
declare mirna_hairpin=''

while getopts "$OPTSTRING" SWITCH ; do
	case $SWITCH in
		h) USAGE;
		   exit 0
		;;
		o) main_dir="$OPTARG"
		;;
		d) mirna_mature="$OPTARG"
		;;
		a) mirna_hairpin="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "mirdeep2_reads.sh: $LINENO: %s\n" "script error: unhandled argument"
		exit 192
		;;
	esac
done


# Start of the loop
for sub in $(ls $main_dir);
	# sub is the project name
	do

		work_dir=$main_dir$sub
		for sample in $(ls $work_dir/)
		do

			echo "Starting to quantify sample: $sample"
			# In case one sample had been processed more than once - more output folders exist. Choose the newest for quantification.
			NEWEST_quant=($work_dir/$sample/miRpipe_out_*)
 			# count the miRpipe_out_* folders
			quant_dir_count=$(find $work_dir/$sample -type d -name 'miRpipe_out_*' | wc -l)
			if [[ $quant_dir_count > 1 ]]; then
				# In case of more than one miRpipe_out_*, find the newest miRpipe_out_*
				echo "There are more than one miRpipe_out_ folders! Taking the newest files for miRNA quatification..."
				echo
				NEWEST_quantt=$(ls -t $work_dir/$sample/miRpipe_out_* | head -1)
				NEWEST_quant=${NEWEST_quantt%?} # remove the colon at the end of the string
			else
			echo 
			fi
						
			# Get the most fresh reads from directory
			reads=$(ls -t $NEWEST_quant/*.fa | head -1)
            #reads=$NEWEST_quant/reads_filtered.fa

			# enter to output directory
			cd $NEWEST_quant
							
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			# # # # # # # # # # # quantifier.pl # # # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
				
			echo "Quantifying known human miRNAs from miRBase..."
			quantifier.pl -p $mirna_hairpin -m $mirna_mature -r $reads -d -U
			
			# File check-up
			file=`ls miRNAs_expressed_all_samples_* 2>/dev/null | wc -l`
			if [ "$file" != "0" ]; then
				echo ""				
				echo "Known miRNAs of $sample were successfully quantified."
				else
				echo "error: failed to quantify known miRNAs of $sample."
				fi
				
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo

	done
done

