#!/bin/bash

#####################################################################################################
##REQUIREMENTS - programs used with their versions
#####################################################################################################

#HISAT 2.2.1 (http://daehwankimlab.github.io/hisat2/)
#note: the hisat2-build script requires python v2.7.x

#TRIMMOMATIC 0.39 (http://www.usadellab.org/cms/?page=trimmomatic)

#PRINSEQ 0.20.4 (http://prinseq.sourceforge.net/)

#STRINGTIE 2.2.1 (https://ccb.jhu.edu/software/stringtie/#install)

#SAMTOOLS 1.15.1 (https://github.com/samtools/samtools/releases/tag/1.15.1)

#CUFFLINKS 2.2.1 (http://cole-trapnell-lab.github.io/cufflinks/install/)

#GFFCOMPARE 0.12.6 (https://github.com/gpertea/gffcompare)

#name of log file
DATE=`date +%s` #get date in Unix epoch time for naming log file
LOGFILE="RNAseq_assembly_pipeline_${DATE}.log"

#number of processors to use in multithreaded applications
NP=8

#prefix of all fastq.gz files that will be analyzed in this pipeline
FILEPREFIX="Tank_"

#filename for list of .gtf files to be merged (stringtie)
MERGELIST="mergelist.txt"

#file that will hold merged transcriptome data for all samples (stringtie)
MERGEDGTF="rbs_merged.gtf"

#file that will hold inputs for prepDE.py
PREPDE="prepDEinput.txt"

#####################################################################################################
##Directories and files - set locations for reading/writing data
#####################################################################################################
#project directory - root directory that will contain all subfolders for this assembly
PROJDIR="${HOME}/scratch01/dx2104"

##Reference Genome
#Directory holding the reference genome
#GENOMEDIR="${PROJDIR}/genomes/myxocyprinus_asiaticus/ncbi-genomes-2022-03-13"
GENOMEDIR="${PROJDIR}/genomes/xyrauchen_texanus"

#Reference genome file name
#GENOME="GCA_019703515.1_MX_HiC_50CHRs.fa_genomic.fna"
GENOME="Xyrauchen_texanus.faa"

#Reference genome index prefix
#GENOMEINDEX="m_asiaticus"
GENOMEINDEX="x_texanus"

##Reference Annotation
#Reference gff annotation file in gff3 format
GFFANNO="Xyrauchen_texanus_annos1-cds0-id_typename-nu1-upa1-add_chr0.gid56101.gff"
GTFANNO="Xyrauchen_texanus_anno.gtf"

#directory containing adapter sequences (needed for trimmomatic)
#IMPORTANT: adapter sequences for Illumina RNA Prep kit are in TruSeq3-PE-2.fa file
#source for adapter sequences: https://support-docs.illumina.com/SHARE/AdapterSeq/Content/SHARE/AdapterSeq/TruSeq/UDIndexes.htm
adapterdir="${HOME}/local/src/trimmomatic/Trimmomatic-0.39/adapters"
trimmomaticPath="${HOME}/local/src/trimmomatic/Trimmomatic-0.39"

#file to track which fastq have been processed through prinseq
princomplete="prinseq_complete.txt"

##Directories that will hold intermediates and final products
RAWDIR="${PROJDIR}/raw"
TRIMDIR="${PROJDIR}/trimmomatic"
PRINSEQDIR="${PROJDIR}/prinseq"
HISATDIR="${PROJDIR}/hisat2"
BAMDIR="${PROJDIR}/samtools"
STRINGTIEDIR="${PROJDIR}/stringtie"
BALLGOWNDIR="${PROJDIR}/ballgown"

#make directories that will contain output
mkdir $TRIMDIR
mkdir $PRINSEQDIR
mkdir $HISATDIR
mkdir $BAMDIR
mkdir $STRINGTIEDIR
mkdir $BALLGOWNDIR

##delete and rebuild the $MERGELIST and $PREPDE each time the pipeline is run.
#this prevents duplicate records in $MERGELIST and $PREPDE
rm $PROJDIR/$MERGELIST
rm $PROJDIR/$PREPDE


## RUN hisat2-build to index the reference genome
echo "##################################################################################" >> $LOGFILE
echo "## Indexing genome $GENOME" >> $LOGFILE
echo "##################################################################################" >> $LOGFILE
echo "" >> $LOGFILE

##index the reference genome using the hisat2-build script (without annotation)
#hisat2-build -p $NP $GENOMEDIR/$GENOME $GENOMEDIR/$GENOMEINDEX 2>&1 | tee -a $LOGFILE

##index the reference genome using the hisat2-build script (with annotation)
#check if the GTF file conversion has already been completed
if [ ! -f "$GENOMEDIR/$GTFANNO" ]
then
	# convert GFF3 format to GTF (uses gffread from cufflinks)
	gffread $GENOMEDIR/$GFFANNO -T -o $GENOMEDIR/$GTFANNO
	# for RBS file, fix identifiers in resulting GTF so stringtie can later match to reference sequences
	sed -i 's/RBS_Chr/lcl|RBS_Chr/g' $GENOMEDIR/$GTFANNO
else
	echo "$GENOMEDIR/$GTFANNO already exists." >> $LOGFILE
fi

#check if splice sites file already exists
if [ ! -f "$GENOMEDIR/${GENOMEINDEX}.ss" ]
then
	#extract splice sites
	extract_splice_sites.py $GENOMEDIR/$GTFANNO > "$GENOMEDIR/${GENOMEINDEX}.ss"
else
	echo "$GENOMEDIR/${GENOMEINDEX}.ss already exists." >> $LOGFILE
fi

# check if exons file already exists
if [ ! -f "$GENOMEDIR/${GENOMEINDEX}.exon" ]
then
	#extract exons
	extract_exons.py $GENOMEDIR/$GTFANNO > "$GENOMEDIR/${GENOMEINDEX}.exon"
else
	echo "$GENOMEDIR/${GENOMEINDEX}.exon already exists." >> $LOGFILE
fi

#check if index already exists
if [ ! -f "$GENOMEDIR/${GENOMEINDEX}.1.ht2" ]
then
	#do the indexing
	hisat2-build -p $NP --ss "$GENOMEDIR/${GENOMEINDEX}.ss" \
		--exon "$GENOMEDIR/${GENOMEINDEX}.exon" \
		$GENOMEDIR/$GENOME $GENOMEDIR/$GENOMEINDEX 2>&1 | tee -a $LOGFILE
else
	echo "hisat2 index of $GENOMEINDEX already exists. Skipping indexing." >> $LOGFILE
fi

## RUN trimmomatic to trim raw reads for quality and adapter sequence
echo "##################################################################################" >> $LOGFILE
echo "## Running Trimmomatic" >> $LOGFILE
echo "##################################################################################" >> $LOGFILE
echo "" >> $LOGFILE

for file in ${RAWDIR}/${FILEPREFIX}*_R1_001.fastq.gz
do
	#get the file names
	read1=$file
	read2=${file%_R1_001.fastq.gz}_R2_001.fastq.gz

	#get basenames of files
	bn1="$(basename -- $read1)"
	bn2="$(basename -- $read2)"
	
	#check if files already trimmed
	if [ ! -f $TRIMDIR/$bn1 ] || [ ! -f $TRIMDIR/$bn2 ]
	then
		#run trimmomatic on each pair of files
		java -jar ${trimmomaticPath}/trimmomatic-0.39.jar \
			PE -threads $NP $read1 $read2 \
			$TRIMDIR/$bn1 $TRIMDIR/${bn1%.fastq.gz}_unpaired.fastq.gz \
			$TRIMDIR/$bn2 $TRIMDIR/${bn2%.fastq.gz}_unpaired.fastq.gz \
			ILLUMINACLIP:$adapterdir/TruSeq3-PE-2.fa:2:30:10 \
			LEADING:20 TRAILING:20 \
			SLIDINGWINDOW:4:20 MINLEN:60 2>&1 | tee -a $LOGFILE
	else
		echo "Trimmomatic already run for $TRIMDIR/$bn1 and $TRIMDIR/$bn2" >> $LOGFILE
	fi
done

## RUN prinseq to trim poly A/T tails
echo "##################################################################################" >> $LOGFILE
echo "## Running prinseq" >> $LOGFILE
echo "##################################################################################" >> $LOGFILE
echo "" >> $LOGFILE

touch $PRINSEQDIR/$princomplete

for file in ${TRIMDIR}/${FILEPREFIX}*_R1_001.fastq.gz
do
	#get the file names
	read1=$file
	read2=${file%_R1_001.fastq.gz}_R2_001.fastq.gz

	#get basenames of files
	bn1="$(basename -- $read1)"
	bn2="$(basename -- $read2)"

	if grep -q $bn1 $PRINSEQDIR/$princomplete
	then
		echo "prinseq already run for $bn1 and $bn2" >> $LOGFILE
	else
		#copy file to prinseq folder
		cp $read1 ${PRINSEQDIR}/$bn1
		cp $read2 ${PRINSEQDIR}/$bn2

		#unzip files because prinseq cannot operate on zipped files
		gunzip ${PRINSEQDIR}/$bn1
		gunzip ${PRINSEQDIR}/$bn2

		#run prinseq on each pair of files
		echo "Running prinseq on ${bn1%.gz} and ${bn2%.gz}" >> $LOGFILE
		prinseq-lite.pl -fastq ${PRINSEQDIR}/${bn1%.gz} -fastq2 ${PRINSEQDIR}/${bn2%.gz} \
			-out_format 3 -trim_tail_left 5 -trim_tail_right 5 -min_len 50 2>&1 | tee -a $LOGFILE
		echo "" >> $LOGFILE

		#cleanup
		rm $PRINSEQDIR/*_bad_*.fastq
		rm $PRINSEQDIR/*_good_singletons_*.fastq

		#fix filenames
		for fq in ${PRINSEQDIR}/*_prinseq_good_*.fastq
		do
			#probably not the best way of fixing the file names, but it works for now
			f=`echo $fq | awk -F"_prinseq_" '{print $1}'`
			mv $fq $f.fastq

			#zip fastq files to save space
			gzip $f.fastq
		done

		#record that prinseq completed processing the files successfully
		echo $bn1 >> $PRINSEQDIR/$princomplete
		echo $bn2 >> $PRINSEQDIR/$princomplete
	fi

done


## RUN hisat2 to map reads to reference genome
echo "##################################################################################" >> $LOGFILE
echo "## Running hisat2" >> $LOGFILE
echo "##################################################################################" >> $LOGFILE
echo "" >> $LOGFILE

for file in ${PRINSEQDIR}/${FILEPREFIX}*_R1_001.fastq.gz
do
	#get the file names
	read1=$file
	read2=${file%_R1_001.fastq.gz}_R2_001.fastq.gz

	sam="$(basename -- $read1)"
	sam=${sam%_L00M_R1_001.fastq.gz}.sam

	#echo sample name to log file
	echo $sam >> $LOGFILE
		
	unsortedBAM=${sam%.sam}_unsorted.bam
	BAM=${sam%.sam}.bam

	if [ ! -f $BAMDIR/$BAM ]
	then
		#run hisat to align each sample to the reference genome
		hisat2 -p $NP --dta --very-sensitive -x $GENOMEDIR/$GENOMEINDEX \
			-1 $read1 \
			-2 $read2 \
			--rna-strandness RF \
			-S $HISATDIR/$sam 2>&1 | tee -a $LOGFILE

		#convert to .bam
		samtools view -bS $HISATDIR/$sam > $BAMDIR/$unsortedBAM

		#sort the .bam file
		samtools sort -@ $NP -o $BAMDIR/$BAM $BAMDIR/$unsortedBAM

		##cleanup
		#get rid of unsorted bam file
		rm $BAMDIR/$unsortedBAM

		#zip the .sam file to save space. Alternatively, you could delete this intermediate file to save more space since the .sam can be reconstructed from the .bam if the sam to bam conversion completes successfully
		#gzip $HISATDIR/$sam

		#Instead of zipping, you could delete this intermediate file to save more space since the .sam can be reconstructed from the .bam if the sam to bam conversion completes successfully
		rm $HISATDIR/$sam

		#echo empty line to logfile to make it more readable
		echo "" >> $LOGFILE
	else
		echo "hisat2 alignment already completed for $BAM" >> $LOGFILE
	fi

done

## RUN stringtie to assemble transcriptome and quantify transcripts
echo "##################################################################################" >> $LOGFILE
echo "## Running stringtie" >> $LOGFILE
echo "##################################################################################" >> $LOGFILE
echo "" >> $LOGFILE


for file in $BAMDIR/*.bam
do
	#make name for .gtf file for each sample
	bn="$(basename -- $file)"
	outname=${bn%.bam}.gtf

	#works to get file name for this project - likely would need modified for work on other data
	label=`echo $outname | awk -F"_" '{print $1"_"$2}'`

	if [ ! -f $STRINGTIEDIR/$outname ]
	then
		#echo sample name to log file
		echo $bn >> $LOGFILE

		#run stringtie
		stringtie -p $NP -G $GENOMEDIR/$GTFANNO -o $STRINGTIEDIR/$outname --rf -l $label  $file 2>&1 | tee -a $LOGFILE

		echo $STRINGTIEDIR/$outname >> $PROJDIR/$MERGELIST
	else
		echo "stringtie already completed for $outname" >> $LOGFILE
		echo $STRINGTIEDIR/$outname >> $PROJDIR/$MERGELIST
	fi

done

echo "" >> $LOGFILE
echo "Done with stringtie runs per sample. Now merging outputs for all individual samples" >> $LOGFILE
echo "" >> $LOGFILE

# check if stringtie merged output already exists
if [ ! -f $STRINGTIEDIR/$MERGEDGTF ]
then
	#merge the outputs of all individual samples
	stringtie --merge -p $NP -G $GENOMEDIR/$GTFANNO -o $STRINGTIEDIR/$MERGEDGTF $PROJDIR/$MERGELIST 2>&1 | tee -a $LOGFILE
else
	echo "merging of stringtie outputs already completed." >> $LOGFILE
fi

echo "Done with stringtie merge operation." >> $LOGFILE
echo "" >> $LOGFILE

# see how transcripts compare with reference annotation
gffcompare -r $GENOMEDIR/$GTFANNO -G -o "$STRINGTIEDIR/${GENOMEINDEX}_merged" $STRINGTIEDIR/$MERGEDGTF 2>&1 | tee -a $LOGFILE

echo "gffcompare completed." >> $LOGFILE
echo "" >> $LOGFILE

#estimate transcript abundances
for file in $BAMDIR/*.bam
do
	#get basename of file
	bn="$(basename -- $file)"

	#get tank name from filename
	#works to get file name for this project - likely would need modified for work on other data
	label=`echo $bn | awk -F"_" '{print $1"_"$2}'`

	#make directory that will hold transcript abundances (i.e., input for ballgown)
	mkdir -p $BALLGOWNDIR/$label

	echo "Exporting ballgown output for ${bn%.bam}.gtf" >> $LOGFILE

	stringtie -e -B -p 8 -G $STRINGTIEDIR/$MERGEDGTF \
		-o $BALLGOWNDIR/$label/${bn%.bam}.gtf \
		$file 2>&1 | tee -a $LOGFILE
	
	# echo information to input file for prepDE.py
	echo -n "$label" >> $PROJDIR/$PREPDE
	echo -ne "\t" >> $PROJDIR/$PREPDE
	echo $BALLGOWNDIR/$label/${bn%.bam}.gtf >> $PROJDIR/$PREPDE

done

echo "ballgown output completed." >> $LOGFILE
echo "" >> $LOGFILE

prepDE.py -i $PROJDIR/$PREPDE \
	-g "$BALLGOWNDIR/gene_count_matrix.csv" \
	-t "$BALLGOWNDIR/transcript_count_matrix.csv"

echo "finished writing prepDE.py output" >> $LOGFILE

exit
