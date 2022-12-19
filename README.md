# dge_scripts
Scripts for differential gene expression analysis

Instructions for modifying URL request (if necessary) in refseq2go.py:
https://www.uniprot.org/help/api_queries

1. **RNAseq_assembly_pipeline.sh** - used to trim/filter RNAseq fastq data, align to Razorback Sucker reference genome, and estimate transcript abundance
2. **getLongestTranscript.pl** - returns longest transcript of each gene from the reference-guided hisat2/stringtie transcriptome assembly. 
3. BLAST scripts
    1. **makeTaxIDMap.sh** - extracts taxon ID numbers associated with sequences from the Swissprot database.
    2. **makeBlastDB.sh** - prepares a BLAST database from the Swissprot sequences using the output from makeTaxIDMap.sh
    3. **runBlastx.sh** - use BLASTX to conduct local alignment of sequences to the Swissprot custom BLAST database
4. Reference Swissprot database BLAST results to Gene Ontology (GO) terms
    1. **swissprot2go.py** - Programatically accesses online GO database to recover GO terms for BLAST results. This script was modified from code available at https://2-bitbio.com/post/how-to-get-go-terms-from-refseq-ids/
    2. **swissprot2go.sh** - operates swissprot2go.py script. 
