#!/bin/bash

function USAGE {
	echo ""
	echo "miRpipe.sh script is the main script of miRpipe. This script pipes the following steps: process reads," 
	echo "filter reads, quantify known miRNAs,  predict novel miRNAs and generate statistics of filtered sequences."
	echo ""
	echo "Usage: miRpipe.sh -o /home/user/results/project_ID_results/ -i /home/user/sample/project_ID/ -e /home/user/miRpipe/ -d /home/user/miRpipe/databases/ -v 20 -r -f -q -s -c -n 1"
	echo "    Options for miRpipe"
	echo "        -o  <str>   path/to/results/folder/ eg.: /home/user/results/project_ID_results/"
	echo "        -i  <str>   path/to/samples/folder/ eg.: /home/user/sample/project_ID_samples/"
    echo "        -e  <str>   path/to/miRpipe/ eg.: /home/user/miRpipe/"
    echo "        -d  <str>   path/to/databases/ eg.: /home/user/miRpipe/databases/"
	echo "        -v  <int>   mirbase version (20 or 21 version)"
	echo "        -r          enable process step"
	echo "        -f          enable filtering step"
	echo "        -q          enable quantification by quantifier"
    echo "        -s          enable quantification by mirAligner"
	echo "        -p          enable prediction of novel miRNAs"
	echo ""
	echo "    Options for Blastn and Bowtie:"
	echo "        -n  <int>   number of processors to use, default=1"
	echo ""
}

if [ $# -eq 0 ]; then
echo "No parameters provided"
	USAGE;
	exit 192;
fi

declare -rx SCRIPT=${0##*/}
declare -r OPTSTRING="o:i:e:d:v:r,f,q,s,p,n:h"
declare SWITCH
declare path_to_output
declare raw_data
declare mirbase
declare path_to_script_folder
declare path_to_databases
declare -i run_process=0
declare -i run_filters=0
declare -i run_quantifier=0
declare -i run_miraligner=0
declare -i run_prediction=0
declare -i threads=1

while getopts "$OPTSTRING" SWITCH ; do
	case $SWITCH in
		h) USAGE;
		   exit 0
		;;
		o) path_to_output="$OPTARG"
		;;
		i) raw_data="$OPTARG"
		;;
		v) mirbase="$OPTARG"
		;;
        e) path_to_script_folder="$OPTARG"
		;;
        d) path_to_databases="$OPTARG"
        ;;
		r) run_process=1
		;;
		f) run_filters=1
		;;
		q) run_quantifier=1
		;;
        s) run_miraligner=1
		;;
		p) run_prediction=1
		;;
		n) threads="$OPTARG"
		;;
		\?) exit 192
		;;
		*) printf "miRpipe.sh: $LINENO: %s\n" "script error: unhandled argument"
		exit 192
		;;
	esac
done

# # # # # # # # # # # # # # # # # 
# # # # assign databases: # # # #
# # # # # # # # # # # # # # # # #

reference_genome=$path_to_databases'hg19/hg19_f'

mirna_hairpin_20=$path_to_databases'hairpin/hsa_hairpin_v20.fa'
mirna_mature_20=$path_to_databases'mature/hsa_mature_mirbase_v20.fa'
related_species_mature_20=$path_to_databases'mature/hominidae_mature_mirbase_v20.fa'
mysql_20=$path_to_databases'mySQL_parse_mirbase_v20'

mirna_hairpin_21=$path_to_databases'hairpin/hsa_hairpin_v21.fa'
mirna_mature_21=$path_to_databases'mature/hsa_mature_mirbase_v21.fa'
related_species_mature_21=$path_to_databases'mature/hominidae_mature_mirbase_v21.fa'
mysql_21=$path_to_databases'mySQL_parse_mirbase_v21/'

mirAligner_DB=$path_to_databases'DB/'

echo "#############"
echo "   miRpipe   "
echo "#############"
echo

if [ $mirbase == 20 ];then
	echo "mirbase v20 version was chosen."
	mirna_hairpin=$mirna_hairpin_20
	mirna_mature=$mirna_mature_20
	related_species_mature=$related_species_mature_20
	mysql=$mysql_20
elif [ $mirbase == 21 ]; then 
	echo "mirbase v21 version was chosen."
	mirna_hairpin=$mirna_hairpin_21
	mirna_mature=$mirna_mature_21
	related_species_mature=$related_species_mature_21
	mysql=$mysql_21
else 
	echo "Please make sure that your chosen mirbase version is 20 or 21"
	exit 192
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # calling process_reads.sh (Process reads for downstream analysis. Necessary step for IKMB mirdeep2 pipeline v2.0)  # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [  $run_process -eq 1  ]; then
	echo "Processing reads..."
	bash ${path_to_script_folder}process_reads.sh -o $path_to_output -i $raw_data -s $path_to_script_folder
	echo
else 
	echo "Skipping processing step..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  calling filter_reads.sh (removes viral sequences and other small ncRNA)  # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [  $run_filters -eq 1  ]; then
	echo "Filtering reads..."
	bash ${path_to_script_folder}filter_reads.sh -o $path_to_output -d $path_to_databases -s $path_to_script_folder -b -v -r -a -c -n $threads
	echo
else
	echo "Skipping filtering step..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # calling run_quantifier.sh (known miRNA quantification)  # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [  $run_quantifier -eq 1 ]; then
	echo "Generating known miRNA profile..."
	bash ${path_to_script_folder}run_quantifier.sh -o $path_to_output -d $mirna_mature -a $mirna_hairpin 
	echo
else
	echo "Skipping quantification of known miRNAs..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # calling run_miraligner.sh (isomiR quantification) # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [  $run_quantifier -eq 1 ]; then
	echo "Quantifying isomiRs..."
	bash ${path_to_script_folder}run_miraligner.sh -i $path_to_output -d $mirAligner_DB
	echo
else
	echo "Skipping quantification of isomiRs..."
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # calling predict_reads.sh (mirDeep2 prediction of de novo miRNAs)  # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [  $run_prediction -eq 1 ]; then
	echo "Performing de novo miRNA prediction..."
	bash ${path_to_script_folder}predict_reads.sh -o $path_to_output -d $mirna_mature -s $related_species_mature -a $mirna_hairpin -r $reference_genome -m -p -n $threads
	echo
else
	echo "Skipping de novo prediction of miRNAs..."
fi


echo
echo "Finished."
