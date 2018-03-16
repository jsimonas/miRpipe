#!/bin/bash

function USAGE {
	echo ""
	echo "This is a miraligner's runner"
	echo ""
	echo "Usage: miraligner_pipe.sh -i /home/user/results/project_ID_results/ -db_mirna /home/user/DB/ "
	echo "    Options for process reads:"
	echo "        -i	<str>   path/to/samples/folder/ eg.: /home/user/samples/project_ID_results/"	
	echo "        -d	<str>   path/to/db/ which contains miRNA.str and hairpin.fa files"
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="i:d:h"
declare SWITCH
declare main_dir 
declare mirna_str=''

while getopts "$OPTSTRING" SWITCH ; do
	case $SWITCH in
		h) USAGE;
		   exit 0
		;;
		i) main_dir="$OPTARG"
		;;
		d) mirna_str="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "miraligner_pipe.sh $LINENO: %s\n" "script error: unhandled argument"
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
				NEWEST_quant=${NEWEST_quantt%?} # remove the column at the end of the string
			else
			echo 
			fi
			
			# Get the most fresh reads from directory
			reads=$(ls -t $NEWEST_quant/*.fa | head -1)
            #reads=$NEWEST_quant/reads_filtered.fa
            echo "The reads used for quantification are following:"
            echo $reads    
			# enter to output directory
			cd $NEWEST_quant
			
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			# # # # # # # # # # # #  miraligner # # # # # # # # # # # 
			# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
				
                        java -jar miraligner.jar -sub 1 -trim 3 -add 3 -s hsa -i $reads -db $mirna_str -o "isomir_$sample" -freq		
                        
				
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo

	done
done


