#!/bin/bash

function USAGE {
	echo ""
	echo "This script predicts novel miRNAs using mapper.pl and miRDeep2.pl modules from miRDeep2 software."
	echo "predict_reads.sh takes as input a deep sequencing reads which were processed by process_reads.sh and/or filter_reads.sh scripts." 
	echo ""
	echo "Usage: predict_reads.sh -o /home/user/results/project_ID_results/ -d /home/user/databases/mature.fasta -s /home/user/databases/related_species_mature.fasta -a home/user/databases/hairpin.fasta"
	echo "-r reference_genome=/home/user/databases/hg19/hg19_f -q -m -p -n 1"
	echo "    Options for predict reads"
	echo "        -o  <str>   path/to/results/folder/ eg.: /home/user/results/project_ID_results/"
	echo "        -d  <str>   path/to/mature.fasta eg.: /home/user/databases/mature.fasta"
	echo "        -a  <str>   path/to/hairpin.fasta eg.: /home/user/databases/hairpin.fasta"
	echo "        -s  <str>   path/to/related_species_mature.fasta eg.: /home/user/databases/related_species_mature.fasta"		
	echo "        -r  <str>   path/to/bowtie/indexed/reference/genome eg.: /home/user/databases/hg19/hg19_f"	
	echo "        -m          enable mapper.pl module (maps sequences to reference human genome)"
	echo "        -p          enable miRDeep2.pl module (core algorithm for novel miRNA prediction)"
	echo "    Options for Bowtie:"
	echo "        -n  <int>   number of processors to use, default=1"
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="o:d:a:s:r:m,p,n:h"
declare SWITCH
declare main_dir
declare mirna_mature=''
declare mirna_hairpin=''
declare related_species_mature=''
declare reference_genome
declare -i mapper=0
declare -i mirdeep2=0
declare -i threads=1

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
		s) related_species_mature="$OPTARG"
		;;
		r) reference_genome="$OPTARG"
		;;
		m) mapper=1
		;;
		p) mirdeep2=1
		;;
		n) threads="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "predict_reads.sh: $LINENO: %s\n" "script error: unhandled argument"
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
			echo ""
			echo "Processing sample: $sample"
			# In case one sample had been processed more than once - more output folders exist. Choose the newest for prediction
			NEWEST_quant=($work_dir/$sample/miRpipe_out_*)
 			# count the miRpipe_out_* folders
			quant_dir_count=$(find $work_dir/$sample -type d -name 'miRpipe_out_*' | wc -l)
			if [[ $quant_dir_count > 1 ]]; then
				# In case of more than one miRpipe_out_*, find the newest mirdeep2_*
				echo "There are more than one miRpipe_out_ folders! Taking the newest files for novel miRNA prediction..."
				echo
				NEWEST_quantt=$(ls -t $work_dir/$sample/miRpipe_out_* | head -1)
				NEWEST_quant=${NEWEST_quantt%?} # remove the colon at the end of the string
			else
			echo 
			fi
						
			# Get the most fresh reads from directory
			reads=$(ls -t $NEWEST_quant/*.fa | head -1)
			
			# enter to output directory
			cd $NEWEST_quant
							
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			# # # # # # # # # # # # #  mapper.pl  # # # # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
				
			if [ $mapper -eq 1 ]; then
			echo "Mapping reads to the reference human genome ..."
			mapper.pl $reads -c -j -p $reference_genome -t reads_collapsed_vs_genome.arf -o $threads -u -n
			
			# File check-up
			if [ -s reads_collapsed_vs_genome.arf ]; then
				echo "Reads of $sample were successfully mapped to the genome."
				echo ""
				else
				echo "error: failed to map the reads of $sample to the human reference genome."
				exit 192		
				echo ""
				fi
			else
			echo
			fi		
				
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			# # # # # # # # # # # #  miRDeep2.pl  # # # # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
				
			if [ $mirdeep2 -eq 1 ]; then
			echo "Predicting de novo miRNAs ..."
                        miRDeep2.pl $reads $reference_genome.fasta reads_collapsed_vs_genome.arf $mirna_mature $related_species_mature $mirna_hairpin -t Human 2>report.log
					
			# File check-up
			file=`ls result_* 2>/dev/null | wc -l`
			if [ "$file" != "0" ]; then
				 echo "De novo miRNA prediction of $sample was successfull."
				 echo ""
				 else
				 echo "error: failed to predict novel miRNAs of $sample, please make sure that you have provided mapped reads to the genome in .arf format."
				 exit 192		
				 echo ""
				 fi
			else
			echo
			fi

			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo

	done
done

