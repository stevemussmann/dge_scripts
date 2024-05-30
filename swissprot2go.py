#!/usr/bin/python3

import sys, os
import ssl #nonsense required to make this work on the DOI network
from urllib.request import urlopen

##
## refseq2go.py
## By: Jake Warner
## Script obtained from https://2-bitbio.com/post/how-to-get-go-terms-from-refseq-ids/

## This script takes a list of Refseq with IDs and outputs a tab deliminated file with the following fields:

# Refseq ID
# Uniprot ID
# Uniprot description
# GO IDs
# GO Biological process
# GO Molecular function
# GO Cellular Compartment

infile = open(sys.argv[1],'r')
outfile = open('%s_go.txt' %(sys.argv[1][:-4]), 'w')

# isolate refseq ID
linecount=0
uprothits=0
uprotmissing=0
#loop the query IDs
for line in infile:
    linecount+=1
    if linecount==1:
        outfile.write('refseq_id\tuniprot_id\tuniprot_description\tGO_ids\tGO_BP\tGO_MF\tGO_CC\n')
    line=line.rstrip()
    refseq_id=line
    context = ssl._create_unverified_context() # nonsense required to make this work on the DOI network
    page = urlopen('https://rest.uniprot.org/uniprotkb/stream?fields=accession%2Cid%2Cgo_id%2Cgo%2Cgo_p%2Cgo_f%2Cgo_c&format=tsv&query=%28accession%3A'+refseq_id+'%29', context=context).read()
    #page = urlopen('https://www.uniprot.org/uniprot/?query=database%3A%28type%3Arefseq+'+refseq_id+'%29&sort=score&columns=id,entry%20name,go-id,go,go(biological%20process),go(molecular%20function),go(cellular%20component)&format=tab').read()
    try:
        page = page.decode('utf-8').splitlines()[1]
        uprothits+=1
    except:
        uprotmissing+=1
    try:
        uprot_id =page.split('\t')[0]
    except:
        uprot_id ='No_Uniprot_ID'
    try:
        uprot_description=page.split('\t')[1]
    except:
        uprot_description='No_Uniprot_description'
    try:
        go_id=page.split('\t')[2]
    except:
        go_id='No_GO_Codes'
    try:
        go_bp=page.split('\t')[4]
    except:
        go_bp='No_GO_codes'
    try:
        go_mf=page.split('\t')[5]
    except:
        go_mf='No_GO_codes'
    try:
        go_cc=page.split('\t')[6]
    except:
        go_cc='No_GO_codes'
    outfile.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\n'%(refseq_id,uprot_id,uprot_description,go_id,go_bp,go_mf,go_cc))
print("Read "+str(linecount)+" Refseq IDs")
print(str(uprothits) +" had a match in Uniprot")
print(str(uprotmissing) + " had no Uniprot match")
outfile.close()

raise SystemExit
