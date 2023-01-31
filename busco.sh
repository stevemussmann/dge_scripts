#!/bin/bash
#SBATCH --job-name=xtex_busco
#SBATCH --partition condo
#SBATCH --qos condo
#SBATCH --constraint='douglas&256gb'
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --exclusive
#SBATCH --time=240:00:00
#SBATCH -e %j.err
#SBATCH -o %j.out

module purge
source ~/miniconda3/etc/profile.d/conda.sh
conda activate busco542

STORAGE="/storage/mussmann/dx_projects/dx2104"
SCRATCH="/scratch/$SLURM_JOB_ID"
PROGRAM="busco/actinopterygii"

TRANSDIR="$STORAGE/gffread"

PROC=16

mkdir -p $SCRATCH/$PROGRAM

rsync $TRANSDIR/*.longest.fasta $SCRATCH/$PROGRAM/.

cd $SCRATCH/$PROGRAM

# run busco
for file in *.longest.fasta
do
        OUT=`echo $file | awk -F "." '{print $1}'`
        busco -c $PROC -m transcriptome -i $file -o $OUT -l actinopterygii_odb10
done

rm $SCRATCH/$PROGRAM/*.longest.fasta

mkdir -p $STORAGE/$PROGRAM
rsync -r $SCRATCH/$PROGRAM/ $STORAGE/$PROGRAM/.

exit
