#!/bin/bash

function USAGE {
	echo ""
	echo "This script takes as an input deep sequencing reads in fasta format. The script using blastn filters out the reads which map to the chosen databases:"
	echo "Viral miRNA precursors (miRBase), Viral genomes (NCBI) and Rfam (EMBL-EBI)"
	echo ""
	echo "Usage: filter_reads.sh -o /home/user/results/project_ID_results/ -d home/user/pipe/databases/ -s /home/user/pipe/scripts/ -b -v -r -a -c -n 1"
	echo "    Options for filter"
	echo "        -o  <str>   path/to/results/folder/ eg.: /home/user/results/project_ID_results/"
	echo "        -d  <str>   path/to/databases/ eg.: /home/user/pipe/databases/"
	echo "        -s  <str>   path/to/script/folder eg.: /home/user/pipe/inhouse_scripts/"	
	echo "        -b          enable Viral haipin database filter"
	echo "        -v          enable Viral genome database filter"
	echo "        -r          enable Rfam database filter"
	echo ""
	echo "    Options for Blastn:"
	echo "        -n  <int>   number of processors to use, default=1"
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="o:d:s:b,v,r,n:h"
declare SWITCH
declare main_dir=" "
declare databases_dir
declare script_folder
declare -i viral_hairpin=0
declare -i viral_genome=0
declare -i rfam=0
declare -i alien=0
declare -i cali=0
declare -i threads=1

while getopts "$OPTSTRING" SWITCH ; do
	case $SWITCH in
		h) USAGE;
		   exit 0
		;;
		o) main_dir="$OPTARG"
		;;
		d) databases_dir="$OPTARG"
		;;
		s) script_folder="$OPTARG"
		;;
		b) viral_hairpin=1
		;;
		v) viral_genome=1
		;;
		r) rfam=1
		;;
		n) threads="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "filter_reads.sh: $LINENO: %s\n" "script error: unhandled argument"
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

			echo "Filtering sample: $sample"
			# In case one sample had been processed more than once - more output folders exist. Choose the newest for filtering.
			NEWEST_quant=($work_dir/$sample/miRpipe_out_*)
 			# count the mirdeep2_* folders
			quant_dir_count=$(find $work_dir/$sample -type d -name 'miRpipe_out_*' | wc -l)
			if [[ $quant_dir_count > 1 ]]; then
				# In case of more than one miRpipe_out_, find the newest miRpipe_out_*
				echo "There are more than one miRpipe_out folders! Taking the newest files for filtering..."
				echo
				NEWEST_quantt=$(ls -t $work_dir/$sample/miRpipe_out_* | head -1)
				NEWEST_quant=${NEWEST_quantt%?} # remove the colon at the end of the string
			else
			echo 
			fi
		
			# Create a directory for blastn results 
			mkdir $NEWEST_quant/dir_blastn_$(eval date +%y%m%d%H%M%S)
			out_path=$NEWEST_quant/dir_blastn_$(eval date +%y%m%d%H%M%S)
				
			# Create a temporary directory for formatdb indexes of reads 
			mkdir $NEWEST_quant/tmp
			tmp=$NEWEST_quant/tmp
			
			# Create a directory for statistics mirdeepdir directory
			mkdir $NEWEST_quant/for_general_statistics
			
			# Get the most fresh reads from directory
			reads=$(ls -t $NEWEST_quant/*.fa | head -1)

			# store the number of pre-filtered sequences
			prereads=$(find_read_count.pl $reads) 

				
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
			# # # # # # # # blastn viral hairpin database # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
						
			if [ $viral_hairpin -eq 1 ]; then
			echo "Filtering reads mapped to viral hairpin database..."
			# blast sequences to viral hairpins
			blastn -num_threads $threads -query $reads -db $databases_dir/viral_RNA/virus_hairpin.db -word_size=18 -out $out_path/blastn_viral_hairpin.out
            
            # get sequence IDs that are not mapped to viral hairpins
            grep -B5 "***** No hits" $out_path/blastn_viral_hairpin.out | grep '^Query=' | sed 's/^Query= //' > $out_path/no_hit_viral_hairpin_id.txt
            
            # retrieve unmapped sequences
            fastacmd -d $reads -i $out_path/no_hit_viral_hairpin_id.txt -D 1 -o $NEWEST_quant/reads_filtered.fa

			# overwrite reads with filtered reads
			reads=$NEWEST_quant/reads_filtered.fa
			
			# store the information about filtered sequences						
			vihair=$(find_read_count.pl $reads)
			
			# File check-up
			if [ -s $NEWEST_quant/no_hit_viral_hairpin_id.txt ]; then
				echo "Mapped reads to viral mirna precursor database were successfully filtered out."
				else
				echo "error: failed to filter reads mapped to viral hairpin."
				fi
			else
			echo 
			fi
				
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
			# # # # # # # # blastn viral genome database  # # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
						
			if [ $viral_genome -eq 1 ]; then
			echo "Filtering reads mapped to viral genome database..."
			# blast sequences to viral genomes
			blastn -num_threads $threads -query $reads -db $databases_dir/viral_RNA/viral_genome_RefSeq.db -word_size=25 -out $out_path/blastn_viral_genome.out
            
            # get sequence IDs that are not mapped to viral genomes
            grep -B5 "***** No hits" $out_path/blastn_viral_genome.out | grep '^Query=' | sed 's/^Query= //' > $out_path/no_hit_viral_genome_id.txt
            
            # retrieve unmapped sequences
            fastacmd -d $reads -i $out_path/no_hit_viral_genome_id.txt -D 1 -o $NEWEST_quant/reads_filtered.fa

			# overwrite reads with filtered reads
			reads=$NEWEST_quant/reads_filtered.fa
			
			# store the information about filtered sequences			
			vigeno=$(find_read_count.pl $reads)
				
			# File check-up
			if [ -s $out_path/no_hit_viral_genome_id.txt ]; then
				echo "Mapped reads to viral genome database were successfully filtered out."
				else
				echo "error: failed to filter reads mapped to viral genomes."
				fi
			else
			echo
			fi		
				
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			# # # # # # # # # # blastn Rfam database  # # # # # # # # # # #
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
								
			if [ $rfam -eq 1 ]; then
			echo "Filtering reads mapped to Rfam database ..."
			# blast sequences to Rfam
			blastn -num_threads $threads -query $reads -db $databases_dir/human_RNA/Rfam.db -word_size=18 -out $out_path/blastn_rfam.out

            # get sequence IDs that are not mapped to Rfam database
            grep -B5 "***** No hits" $out_path/blastn_rfam.out | grep '^Query=' | sed 's/^Query= //' > $out_path/no_hit_Rfam_id.txt
            
            # retrieve unmapped sequences
            fastacmd -d $reads -i $out_path/no_hit_Rfam_id.txt -D 1 -o $NEWEST_quant/reads_filtered.fa

			# overwrite reads with filtered reads
			reads=$NEWEST_quant/reads_filtered.fa
			
			# store the information about filtered sequences			
			rfamseq=$(find_read_count.pl $reads)
					
			# File check-up
			if [ -s $out_path/no_hit_Rfam_id.txt ]; then
				 echo "Mapped reads to Rfam database were successfully filtered out."
				 else
				 echo "error: failed to filter reads mapped to Rfam."
				 fi
			else
			echo
			fi
            
			
			# remove tmp directory
			rm -rf $tmp
            
						
			# Generate table of reads after main proccesing steps
			fastq=$((`wc -l < $work_dir/$sample/*.fastq` / 4))			
			reads=$(grep "^>" $NEWEST_quant/reads.fa | wc -l)
			reads_colapsed=$(grep "^>" $NEWEST_quant/reads_colapsed.fa | wc -l)			
			reads_filtered=$(cat $NEWEST_quant/reads_filtered.fa |awk 'NR%2==1' | awk '{gsub(">seq_[0-9]*_x", "")} {print $0}' | paste -sd+ | bc )
			
			echo -ne "Sample\tInitial_reads\tPre_filtered_reads\tUnique_reads\tFiltered_reads\n" > $NEWEST_quant/for_general_statistics/general_read_stat.txt #| column -t
			echo -ne "$sample\t$fastq\t$reads\t$reads_colapsed\t$reads_filtered" >> $NEWEST_quant/for_general_statistics/general_read_stat.txt
			
			# Generate table of filtered sequences
			echo -ne "Sample\tAfter_viral_hairpin\tAfter_viral_genome\tAfter_Rfam\tAfter_calibrator\n" > $NEWEST_quant/for_general_statistics/reads_after_filters.txt #| column -t			
			echo -ne "$sample\t$vihair\t$vigeno\t$rfamseq\t$caliseq" >> $NEWEST_quant/for_general_statistics/reads_after_filters.txt
						
			# Remove fastq file
			rm $work_dir/$sample/*.fastq
			
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo

	done
done


