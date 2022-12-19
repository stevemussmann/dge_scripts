#!/bin/bash

#uniprot database downloaded 9/2/2022

makeblastdb -in uniprot_sprot.fasta -dbtype prot -taxid_map taxidmap.txt -parse_seqids

exit
