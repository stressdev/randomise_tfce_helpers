#!/bin/bash

################################
# USAGE & PURPOSE
################################
#
# USAGE ------------------------------------------------------------
#
# Prereq: you have already run a group-level feat model generated
# using the "inputs are lower-level feat directories" option, rather
# than "inputs are lower-level copes" option
#
# Copy this script to the dir you want the output to be in.
#
# In that output dir:
#  $ sbatch run_randomise_cope_tfce.bash <file path to group .feat dir>
#    cope<number of cope you want analyzed>
#    <1=within-group analysis e.g. whole group; 2=between-group analysis e.g. control vs. trauma>
#
# Example:
#  $ sbatch run_randomise_cope_tfce.bash /mnt/stressdevlab/new_fear_pipeline/Group/FearLearning/All_n147/WholeRun/FearWR_All_n147_p05.gfeat cope15 1
#
#
# PURPOSE ----------------------------------------------------------
#
# Run TFCE correction for multiple comparisons on one contrast/cope
#
# This code:
#  1) Takes first-level copes (registered into standardized space) and
#     concatenates the group(s)
#  2) Runs FSL's randomise command on that cope
#
#
# BATCH JOB PARAMETERS ---------------------------------------------
#
#SBATCH --job-name=randomise
#SBATCH --output=%x_%A.out
#SBATCH --error=%x_%A.err
#SBATCH --time=1-00:00:00
#SBATCH --partition=ncf
#SBATCH --mail-type=END,FAIL
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G
#
# DETAILS ---------------------------------------------------------
#
# The first argument to this file is a gfeat directory. The script copies the
# necessary design files and makes a new 4d image file which will all be saved
# to the directory from which this script is run (along with the output from
# Randomise).
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


################################
# CODE
################################

module load centos6/0.0.1-fasrc01  ncf/1.0.0-fasrc01 fsl/6.0.2-ncf

# CHANGE THIS IF YOU NEED A DIFFERENT MASK
mask=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

gfeatdir="${1}"
copename="${2}"
analysis="${3}"

echo "Executing in $(pwd)"
echo "Copying design files from ${gfeatdir}"
cp -v "${gfeatdir}/design.con" ./
cp -v "${gfeatdir}/design.fsf" ./
cp -v "${gfeatdir}/design.grp" ./
cp -v "${gfeatdir}/design.mat" ./

# Where design.fsf lists feat_files that are the file paths to feat dirs (not indiv copes)
# Grabs feat dir names and reformats, appends file path with var for specified cope, makes all slashes the same, saves as file
# Fun fact, can't sed with variables and read into var $inputs in same command, need to save as txt file output and read back in
cat design.fsf | grep feat_file | awk -F " " '{print $3}' | sed -e 's/\"//g' | sed -e 's|$|\\reg_standard\\stats\\'${copename}'.nii.gz|g' | sed 's=\\=/=g' > inputfiles.txt
inputs=`cat inputfiles.txt`
#echo $inputs

echo "Combining first level models..."
fslmerge -t first_level4d.nii.gz ${inputs}

echo "Running Randomise..."
if [ $analysis == 2 ]
then
    randomise -i first_level4d.nii.gz -o `basename ${gfeatdir}` -d design.mat -t design.con -e design.grp -m "${mask}" -n 10000 -T
elif [ $analysis == 1 ]
then
    randomise -i first_level4d.nii.gz -o `basename ${gfeatdir}` -1 -e design.grp -m "${mask}" -n 10000 -T
else
    echo "Please specify analysis type for randomise"
fi

    
