#!/bin/bash

module load centos6/0.0.1-fasrc01  ncf/1.0.0-fasrc01 fsl/6.0.2-ncf

#CHANGE THIS IF YOU NEED TO SELECT DIFFERENT TFCE CORRECTED P VALUE IMAGES
TFCEsearch="*tfce_corrp_tstat*"

thresh=$(ls $TFCEsearch)

for t in $thresh; do
	tstat=$(echo ${t} | sed -e 's/_tfce_corrp//')
	threshed=${tstat%.nii.gz}_thresh.nii.gz
	clustindex=${tstat%.nii.gz}_cluster_index
	lmax=${tstat%.nii.gz}_lmax.txt
	clustsize=${tstat%.nii.gz}_cluster_size
	clusterout=${tstat%.nii.gz}_clusters.txt
	echo "Thresholding $tstat using $t..."
	echo "Output: $threshed"
	fslmaths "${t}" -thr 0.95 -bin -mul "${tstat}" "${threshed}"
	cluster --in=$threshed --thresh=0.0001 --oindex=$clustindex --olmax=$lmax --osize=$clustsize > $clusterout
done

