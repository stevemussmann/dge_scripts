#!/bin/bash

./swissprot2go.py blastx.results.all.col2.uniq.sort.tsv
./swissprot2go.py blastx.results.danio.col2.uniq.sort.tsv
./swissprot2go.py blastx.results.human.col2.uniq.sort.tsv

exit
