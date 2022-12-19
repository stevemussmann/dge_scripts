#!/bin/bash

FASTA="rbs_merged.longest.fasta"
DB="/home/aftc/Desktop/projects/dx2104/blast/sprot_blastdb/uniprot_sprot.fasta"

# all of swissprot database
blastx -query $FASTA -db $DB -out blastx.results.all.tsv \
	-evalue 0.0001 -num_threads 12 -max_target_seqs 1 -outfmt 6

#danio ox=7955
blastx -query $FASTA -db $DB -out blastx.results.danio.tsv \
	-evalue 0.0001 -num_threads 12 -max_target_seqs 1 -outfmt 6 -taxids 7955

#human ox=9606
blastx -query $FASTA -db $DB -out blastx.results.human.tsv \
	-evalue 0.0001 -num_threads 12 -max_target_seqs 1 -outfmt 6 -taxids 9606

exit
