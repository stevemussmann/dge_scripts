# dge_scripts
Scripts for differential gene expression analysis

Instructions for modifying URL request (if necessary) in refseq2go.py:
https://www.uniprot.org/help/api_queries

1. **RNAseq_assembly_pipeline.sh** - used to trim/filter RNAseq fastq data, align to Razorback Sucker reference genome, and estimate transcript abundance
2. **getLongestTranscript.pl** - returns longest transcript of each gene from the reference-guided hisat2/stringtie transcriptome assembly. 
3. BLAST scripts
    1. **makeTaxIDMap.sh** - extracts taxon ID numbers associated with sequences from the Swissprot database.
