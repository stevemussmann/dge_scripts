#!/bin/bash

#uniprot database downloaded 9/2/2022
#NCBI BLAST version 2.12.0+

makeblastdb -in uniprot_sprot.fasta -dbtype prot -taxid_map taxidmap.txt -parse_seqids

exit
