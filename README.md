[![DOI](https://zenodo.org/badge/535760345.svg)](https://zenodo.org/badge/latestdoi/535760345)

# dge_scripts
This repository includes code associated with Gilbert et al. 2024: 

Gilbert, E.I., Diver, T.A., Mussmann, S.M., Saltzgiver, M.J., Knight, W.K., Durst, S.L., Farrington, M.A., Clark Barkalow, S.L., Tobler, M. and Franssen, N.R. (2024), Why is it too cold? Towards a mechanistic understanding of cold-water pollution effects on recruitment of an imperiled warmwater fish. Molecular Ecology e17588. https://doi.org/10.1111/mec.17588

##List of Scripts:

1. **RNAseq_assembly_pipeline.sh** - used to trim/filter RNAseq fastq data, align to Razorback Sucker reference genome, and estimate transcript abundance
2. **getLongestTranscript.pl** - returns longest transcript of each gene from the reference-guided hisat2/stringtie transcriptome assembly. 
3. **busco.sh** - used to run BUSCO v5.4.2 on longest transcripts from all hisat2/stringtie assemblies.
4. BLAST scripts
    1. **makeTaxIDMap.sh** - extracts taxon ID numbers associated with sequences from the Swissprot database.
    2. **makeBlastDB.sh** - prepares a BLAST database from the Swissprot sequences using the output from makeTaxIDMap.sh
    3. **runBlastx.sh** - use BLASTX to conduct local alignment of sequences to the Swissprot custom BLAST database
5. Reference Swissprot database BLAST results to Gene Ontology (GO) terms
    1. Get Swissprot IDs from tab-delimited (-outfmt 6) BLAST output with command `awk '{print $2}' blast_result.tsv | sort | uniq`
    2. **swissprot2go.py** - Programatically accesses online GO database to recover GO terms for Swissprot IDs. This script was modified from code available at https://2-bitbio.com/post/how-to-get-go-terms-from-refseq-ids/. Instructions for further modifying URL request (if necessary) in swissprot2go.py are available at: https://www.uniprot.org/help/api_queries.
    3. **swissprot2go.sh** - operates swissprot2go.py script. 

## dependency installation
Most dependencies for **RNAseq_assembly_pipeline.sh** can be installed from conda. Cufflinks has compatibility issues with the other programs due to python and may need to be installed in a separate conda environment. 

Conda environment `rnaseq` with hisat2, trimmomatic, prinseq, stringtie, samtools, and gffcompare:
```
conda create -n rnaseq -c conda-forge -c bioconda hisat2=2.2.1 trimmomatic=0.39 prinseq=0.20.4 stringtie=2.2.3 samtools=1.21 gffcompare=0.12.6
```

Conda environment `cufflinks`:
```
conda create -n cufflinks -c conda-forge -c bioconda cufflinks
```
