#!/bin/bash

# Creates a directory for updated dbs
mkdir databases_$(date -I)
cd databases_$(date -I)

######################
##### Rfam update ####
######################

read -r -p "Do you want to update Rfam database? [Y/n] " response
case $response in
    [yY][eE][sS]|[yY])
    
    # Create a directory for database
    mkdir human_RNA
    rfam=human_RNA
    
    # Download the family.txt file from current rfam version containing the types of RNAs and family asession numbers
    wget -q -O - ftp://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/database_files/family.txt.gz | gunzip -c > $rfam/family.tmp 

    # Please describe the types of RNAs which you want to retrieve
    read -p "Please enter RNA types which you want to retrieve from Rfam database (e.g.: rRNA tRNA or other). If NOT press [ENTER] and rRNAs, tRNAs, snRNAs and sRNA will be retrieved by default. Please make sure that your entered RNA types are space-separated : " RNAs

    if [ -z "$RNAs" ];
      then
      RNAs=(rRNA tRNA snRNA sRNA)
    fi

    # File check-up
    echo "Rfam family.txt file check-up..."
    for i in ${RNAs[@]}
    do
    if cat $rfam/family.tmp | cut -f19 | grep -q -i "$i"; then
      echo "file check-up successful: $i was found"
    else 
      echo "error: $i were not found, please check if 19th column of ftp://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/database_files/family.txt.gz file contains $i molecule type."
    fi		
    done

    # Retrieve Rfam accession numbers for selected RNAs   
    IDs_t="" 
    for i in ${RNAs[@]}
    do
    echo "Rfam accession numbers of ${i} were retrieved"
    IDs_t="$IDs_t $(awk -F$'\t' 'BEGIN{IGNORECASE=1} $19 ~/'$i'/ {print $1}' $rfam/family.tmp)"
    IDs=($IDs_t)
    done
  
    echo "Number of Rfam accessions to download: ${#IDs[@]}" 
    
    echo "Downloading files from current Rfam database version. This may take a while..."
    echo -n > $rfam/Rfam.fa
    for i in ${IDs[@]}
    do
    wget -q -O - ftp://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/fasta_files/$i.fa.gz | zcat -c >> $rfam/Rfam.fa 
    done
    
    # Extract only human sequnces
    echo "Extracting human sequences..."
    awk '/^>/ { p = ($0 ~ /Homo sapiens/)} p' $rfam/Rfam.fa >$rfam/Rfam.tmp && mv $rfam/Rfam.tmp $rfam/Rfam.fa
    # Filtering out sequences which doesn't belong to human
    awk '/^>/ { p = ($0 !~ /from Homo sapiens/)} p' $rfam/Rfam.fa > $rfam/Rfam.tmp && mv $rfam/Rfam.tmp $rfam/Rfam.fa

    # File check-up
    if test -s $rfam/Rfam.fa
      then
    echo "Rfam.fa file containing only human sequences was successfully created."
      else
    echo "error: Rfam.fa containing only human sequences was not created."
    fi
    
    # Database indexes
    echo "Creating Rfam database indexes..."
    formatdb -i $rfam/Rfam.fa -pF -oT -n $rfam/Rfam.db
    mv formatdb.log $rfam/formatdb_rfam.log
    
    # File check-up
    if test -s $rfam/Rfam.db.nhr
      then
    echo "Rfam was successfully updated to the newest version."
      else
    echo "error: Rfam was not updated, please make sure that you have installed formatdb software."
    fi
    ;;
 *)
    echo "Skipping Rfam database update..."
    ;;
esac

################################
##### Viral database update ####
################################

read -r -p "Do you want to update Viral RefSeq database? [Y/n] " response
case $response in
    [yY][eE][sS]|[yY])
    
    # Create a directory for database
    mkdir viral_RNA
    viral=viral_RNA
    
    # Download viral genome sequnces directly from NCBI refseq
    echo "Downloading files from NCBI RefSeq database..."
    esearch -db nucleotide -query "Viruses [PORG] AND srcdb_refseq [PROP] AND complete genome [WORD]" | efetch -format fasta | grep '.' > $viral/viral_genome_RefSeq.fa
    
    # File check-up
    if test -s $viral/viral_genome_RefSeq.fa
      then
    echo "The newest version of viral_genome_RefSeq.fa file was successfully downloaded."
      else
    echo "error: viral_genome_RefSeq.fa file was not downloaded."
    fi
        
    # Database indexes
    echo "Creating Viral RefSeq database indexes..."
    formatdb -i $viral/viral_genome_RefSeq.fa -pF -oT -n $viral/viral_genome_RefSeq.db
    mv formatdb.log $viral/formatdb_genome.log
    
     # File check-up
     echo "file check-up..."
    if test -s $viral/viral_genome_RefSeq.db.nhr
      then
    echo "Viral RefSeq database was successfully updated."
      else
    echo "error: Viral RefSeq database was not updated."
    fi
    ;;
 *)
    echo "Skipping Viral RefSeq database update..."
    ;;
esac    

###############################
##### Viral hairpin update ####
###############################
    
read -r -p "Do you want to update Viral hairpin database? [Y/n] " response
case $response in
    [yY][eE][sS]|[yY])
    
    if [ -d "viral_RNA" ]; then
      viral=viral_RNA
    else 
      mkdir viral_RNA
      viral=viral_RNA
    fi
    
    # mirbase version
    version=$(curl -silent  ftp://mirbase.org/pub/mirbase/CURRENT/ | grep "RELEASE" | awk '{ print substr( $0, length($0) - 1, length($0) ) }')
    
    # Download files from miRBase current version
    echo "Downloading files from mirbase $version version..."
    wget -q -O - ftp://mirbase.org/pub/mirbase/CURRENT/hairpin.fa.gz | gunzip -c > $viral/virus_hairpin.fa
    
    # File check-up
    if test -s $viral/virus_hairpin.fa
      then
    echo "file virus_hairpin.fa was successfully generated from current mirbase_v$version verssion." 
      else
    echo "error: virus_hairpin.fa file was not successfully generated from current mirbase_v$versione verssion."
    fi
    
    # Extract viral sequences
    awk '/^>/ { p = ($0 ~ /virus/)} p' $viral/virus_hairpin.fa >  $viral/virus_hairpin.tmp && mv $viral/virus_hairpin.tmp $viral/virus_hairpin.fa
    
    # Database indexes
    echo "Creating viral hairpin database indexes..."
    formatdb -i $viral/virus_hairpin.fa -pF -oT -n $viral/virus_hairpin.db
    mv formatdb.log $viral/formatdb_hairpin.log
    
    # File check-up
    echo "file check-up..."
    if test -s $viral/virus_hairpin.db.nhr
      then
    echo "Viral hairpin database was successfully updated."
      else
    echo "error: Viral hairpin database was not updated."
    fi
    ;;
 *)
    echo "Skipping Viral hairpin database update..."
    ;;
esac    

#####################################################
##### nonHuman nonVirus miRNA precursor database ####
#####################################################

read -r -p "Do you want to update nonHuman nonVirus miRNA precursor database? [Y/n] " response
case $response in
    [yY][eE][sS]|[yY])
    
    # Create a directory for database
    mkdir nonHuman_nonVirus
    alien=nonHuman_nonVirus
    
    # Download files from miRBase current version
    echo "Downloading files from mirbase_v$version..."
    wget -q -O - ftp://mirbase.org/pub/mirbase/CURRENT/hairpin.fa.gz | gunzip -c > $alien/nonHuman_nonVirus.fa
     
    # File check-up
    if test -s $alien/nonHuman_nonVirus.fa
      then
    echo "file nonHuman_nonVirus.fa was successfully generated from current mirbase_v$version version." 
      else
    echo "error: nonHuman_nonVirus.fa file was not successfully generated from current mirbase_v$version version."
    fi
    
    # Discard human miRNA precursor sequences viral
    awk '/^>/ { p = ($0 !~ /hsa-/)} p' $alien/nonHuman_nonVirus.fa > $alien/nonHuman_nonVirus.tmp && mv $alien/nonHuman_nonVirus.tmp $alien/nonHuman_nonVirus.fa
    # Discard viral miRNA precursor sequences viral
    awk '/^>/ { p = ($0 !~ /virus/)} p' $alien/nonHuman_nonVirus.fa > $alien/nonHuman_nonVirus.tmp && mv $alien/nonHuman_nonVirus.tmp $alien/nonHuman_nonVirus.fa

    # database indexes
    echo "Creating nonHuman nonVirus miRNA precursor database indexes..."
    formatdb -i $alien/nonHuman_nonVirus.fa -pF -oT -n $alien/nonHuman_nonVirus.db
    mv formatdb.log $alien/formatdb_alien.log
    
    # File check-up
    echo "file check-up..."
    if test -s $alien/nonHuman_nonVirus.db.nhr
      then
    echo "nonHuman nonVirus miRNA precursor database was successfully updated."
      else
    echo "error: nonHuman nonVirus miRNA precursor database was not updated."
    fi
    ;;
 *)
    echo "Skipping nonHuman nonVirus miRNA precursor database update..."
    ;;
esac   

#########################################################
##### miRBase update and MySQL miRBase parser update ####
#########################################################

read -r -p "Do you want to update miRBase or download older versions of miRBase ? [Y/n] " response
case $response in
    [yY][eE][sS]|[yY])
    
    # Create a directories for database
    mkdir mature
    mkdir hairpin
    mature=mature
    hairpin=hairpin
    
    # Please describe the types of RNAs which you want to retrieve
    read -p "Please enter miRBase version/versions which you want to download (e.g.: 20 21 or other). If NOT press [ENTER] and the newiest version will be retrieved by default. Please make sure that your entered versions are space-separated : " mirbase

    if [ -z "$mirbase" ];then
      mirbase=$(curl -silent  ftp://mirbase.org/pub/mirbase/CURRENT/ | grep "RELEASE" | awk '{ print substr( $0, length($0) - 1, length($0) ) }')
    fi

    for i in ${mirbase[@]}
	do
	
	   # find version
	   version=$(curl -silent  ftp://mirbase.org/pub/mirbase/$i/ | grep "RELEASE" | awk '{ print substr( $0, length($0) - 1, length($0) ) }')
	
	   if [ ! -z "$version" ];then
	       echo "miRBase $version version was found on miRBase ftp server"
	   else 
	       echo "$version was not found in miRBase, please make sure that your entered version exists in miRBase ftp server"
	   exit 192
	   fi  
	
	   # # # Download mature miRNA sequences from miRBase
	   echo "Downloading mature miRNA from mirbase_v$version version..."
	   wget -q -O - ftp://mirbase.org/pub/mirbase/$i/mature.fa.gz | gunzip -c > $mature/mature_mirbase_v$version.fa
       
	   # File check-up
	   if [ -s $mature/mature_mirbase_v$version.fa ]; then
	       echo "mature_mirbase_v$version.fa file was successfully downloaded from current "mirbase_v$version" version." 
	   else
	       echo "error: mature_mirbase_v$version.fa file failed to download from from "mirbase_v$version", please make sure if ftp://mirbase.org/pub/mirbase/$i/mature.fa.gz file exists."
	   exit 192		
	   fi
    
	   # # # preparing hsa- and hominidae- mature.fa files
	   awk '/^>/ { p = ($0 ~ /^>hsa/)} p' $mature/mature_mirbase_v$version.fa >  $mature/hsa_mature_mirbase_v$version.fa
	   awk '{print $1}' $mature/hsa_mature_mirbase_v$version.fa > $mature/hsa_mature_mirbase_v$version.tmp && mv $mature/hsa_mature_mirbase_v$version.tmp $mature/hsa_mature_mirbase_v$version.fa
	   awk '/^>/ { p = ($0 ~ /^>ggo|^>ppa|^>ppy|^>ptr|^>ssy/)} p' $mature/mature_mirbase_v$version.fa >  $mature/hominidae_mature_mirbase_v$version.fa
	   awk -F" " -v OFS='_' ' NR % 2 == 1 { print $1, $2} NR % 2 ==0 {print $1}' $mature/hominidae_mature_mirbase_v$version.fa > $mature/hominidae_mature_mirbase_v$version.tmp && mv $mature/hominidae_mature_mirbase_v$version.tmp $mature/hominidae_mature_mirbase_v$version.fa
	   rm $mature/mature_mirbase_v$version.fa
    
	   # File check-up
	   if [ -s $mature/hsa_mature_mirbase_v$version.fa ] && [ -s $mature/hominidae_mature_mirbase_v$version.fa ]; then
	       echo "hsa_mature_mirbase_v$version.fa and hominidae_mature_mirbase_v$version.fa files were successfully generated from current "mirbase_v$version" version." 
	   else
	       echo "error: hsa_mature_mirbase_v$version.fa and hominidae_mature_mirbase_v$version.fa failed to generate from from "mirbase_v$version"."
	   fi
	
	   # # # Download hairpin sequences from miRBase current version
	   echo "Downloading miRNA precursors from mirbase_v$version version..."
	   wget -q -O - ftp://mirbase.org/pub/mirbase/$i/hairpin.fa.gz | gunzip -c > $hairpin/hsa_hairpin_v$version.fa
       	
	   # preparing hsa- hsa_hairpin.fa files
	   awk '/^>/ { p = ($0 ~ /hsa/)} p' $hairpin/hsa_hairpin_v$version.fa > $hairpin/hsa_hairpin_v$version.tmp && mv $hairpin/hsa_hairpin_v$version.tmp $hairpin/hsa_hairpin_v$version.fa
	   awk '{print $1}' $hairpin/hsa_hairpin_v$version.fa > $hairpin/hsa_hairpin_v$version.tmp && mv $hairpin/hsa_hairpin_v$version.tmp $hairpin/hsa_hairpin_v$version.fa
	
	   # File check-up
	   if [ -s $hairpin/hsa_hairpin_v$version.fa ]; then
	       echo "hsa_hairpin_v$version.fa file was successfully downloaded from current "mirbase_v$version" version." 
	   else
	       echo "error: hsa_hairpin_v$version.fa file failed to download from from "mirbase_v$version" version."
	   exit 192		
	   fi   
	  
    done	
	;;
 *)
    echo "Skipping mirbase update..."
    ;;
esac    

echo "There is nothing more to update."
    
    
    
    
    


