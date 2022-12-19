#!/bin/bash

grep '>' uniprot_sprot.fasta | sed 's/>//g' | awk '{print $1}' > seq.txt
grep '>' uniprot_sprot.fasta | sed 's/>//g' | awk -F"OX=" '{print $2}' | awk '{print $1}' > taxid.txt

paste seq.txt taxid.txt > taxidmap.txt
rm seq.txt taxid.txt

exit
