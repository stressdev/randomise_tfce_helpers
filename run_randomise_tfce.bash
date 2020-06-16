#!/bin/bash
#SBATCH --job-name=randomise
#SBATCH --output=%x_%A.out
#SBATCH --time=1-00:00:00
#SBATCH --partition=ncf
#SBATCH --mail-type=END,FAIL
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G

# The fist argument to this file is a gfeat directory. The script copies the
# necessary design files and makes a new 4d image file which will all be saved
# to the directory from which this script is run (along with the output from
# Randomise.
# 
# The files it copies from the gfeat directory are:
#
# design.con
# design.fsf
# design.grp
# design.mat
#
# The 4d files with all first level models is called first_level4d.nii.gz.
#
# Note well from the Randomise help (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/UserGuide):
#
# "If your design is simply all 1s (for example, a single group of subjects)
# then randomise needs to work in a different way. Normally it generates random
# samples by randomly permuting the rows of the design; however in this case it
# does so by randomly inverting the sign of the 1s. In this case, then, instead
# of specifying design and contrast matrices on the command line, use the -1
# option."
#
# If the above is the case for you, please edit the randomise command below accordingly.
#

module load centos6/0.0.1-fasrc01  ncf/1.0.0-fasrc01 fsl/6.0.2-ncf

#CHANGE THIS IF YOU NEED A DIFFERENT MASK
mask=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

gfeatdir="${1}"

echo "Executing in $(pwd)"
echo "Copying design files from ${gfeatdir}"
cp -v "${gfeatdir}/design.con" ./
cp -v "${gfeatdir}/design.fsf" ./
cp -v "${gfeatdir}/design.grp" ./
cp -v "${gfeatdir}/design.mat" ./

inputs=`cat design.fsf | grep feat_file | awk -F " " '{print $3}' | sed -e 's/\"//g'`

echo "Combining first level models..."
fslmerge -t first_level4d.nii.gz ${inputs}

echo "Running Randomise..."
randomise -i first_level4d.nii.gz -o `basename ${gfeatdir}` -d design.mat -t design.con -e design.grp -m "${mask}" -n 10000 -T
