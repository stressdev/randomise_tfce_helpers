# randomise_tfce_helpers

Want to get started with threshold free cluster enhancment using FSL's Randomise? Start here.

First, read the [user guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/UserGuide). When you're done, return here.

# Why use Randomise and TFCE?

Permutation testing allows you to relax the assumptions underlying the parametric models used by FEAT/FLAME to derive _p_-values and test statistics. Randomise generates a null distribution from the data you have by mixing it up so that the expected association between your independent and dependent variables is 0. This allows you to derive a _p_-value that is not invalidated by violations of the parametric assumptions of other models. It is almost always the case that if the _p_-value differs between the parametric null and the permutation null distribution, it's the permutation distribution that is the correct reference. This means more confidence in the statistic, and often times greater statistical power

It also allows you to generate the _spatial_ distribution of null test statistics, which further enables threshold free cluster enhancement (TFCE). Typical corrections for multiple comparisons do not take into account the spatial autocorrelation of test statistics, which often means that the adjustment is made for more tests than necessary. Cluster corrections for multiple comparisons take this spatial information into account. TFCE, specifically, combines information about the signal height (that is, that inverse of the size of the _p_-value) and extent (how big an area is occupied by _p_-values at least that big). The intuition is that you can infer that a set of _p_-values should be made _more significant_ if there are more of them in one place than would be expected by chance (which you can tell by the permuted maps). The big inovation with TFCE is that it does this without having to set a particular _p_-value cutoff so you can find very small but, but very significant clusters and very big but not so significant clusters at the same time. This is almost a certainly garbled explanations, so you should go read [the original paper](https://doi.org/10.1016/j.neuroimage.2008.03.061).

# What can I do with this repository?

If you've generated a group-level model with FEAT, you have all the information you need to run Randomise on Harvard's supercomputing cluster. At it's simplest, all you need to do is `sbatch` the `run_randomise_tfce.bash` script with your gfeat directory. The script copies the files specifying first-level model locations, contrasts, covariates, and group-dependence structure to the directory you're running the script from, and runs Randomise using 10,000 permutations. It might take a day to run, but at the end you get a pretty robust set of results.

## Usage: Randomise and TFCE

(Assuming you're logged into ncf...)

_Note well:_ The default is to run 10,000 permutations; this is done for each and every contrast you've requested. You can hack in some parallelization if you split up your contrasts between different design files (I assume---I havedn't tried it yet).

1. Clone this repository to your home directory, or wherever you keep your code: `git clone https://github.com/stressdev/randomise_tfce_helpers`
2. Copy the bash script to the directory you want to store the results: `cd randomise_tfce_helpers; cp run_randomise_tfce.bash ~/folder/where/your/results/go`
3. Travel to the results directory and edit the script if you want to change some of the options. If you expect the process to take a long time, for example, increase the allowed time at the top of the script (e.g., change `#SBATCH --time=1-00:00:00` to `#SBATCH --time=5-00:00:00` if you think it might take 5 days to run): `cd ~/folder/where/your/results/go; nano run_randomise_tfce.bash`
4. Run the script, providing one argument specifying the location of your group-level FEAT: `sbatch run_randomise_tfce.bash /directory/holding/your/experiment.gfeat/`

The script loads FSL, set's the mask to FSL's MNI152_T1_2mm_brain.nii.gz (which you can change if you need), copies the necessary `design.*` files, pulls the first level model names from `design.fsf`, creates a 4d NIFITI from those first-level models and runs Randomise requesting `-n 10000` permutations and TFCE (`-T`) output.

## Usage: Thresholding and reporting clusters

The script `threshold_and_cluster.bash` is there to help you threshold your raw _t_-statistic image using the TFCE _p_-value image, which is really useful if you've requested a lot of contrasts.

To run it, simply execute: `bash threshold_and_cluster.bash` in the directory your TFCE images are. All it does is search that directory for all files that match `"*tfce_corrp_tstat*"`, reconstructs the _t_-statistic filename, uses `fslmaths` to compute a new thresholded _t_-statistic image named `*tstat*_thresh.nii.gz`, and then runs `cluster` to get various cluster output.

# Outputs

**run_randomise_tfce.bash**

`*tfce_corrp_tstat*.nii.gz` TFCE 1-_p_ images  
`*tstat*.nii.gz` Raw _t_-statistic images

**threshold_and_cluster.bash**

`*tstat*_thresh.nii.gz` Thresholded _t_-statistic image  
`*tstat*_cluster_index.nii.gz` Cluster index image  
`*tstat*_cluster_size.nii.gz` Cluster size image  
`*tstat*_lmax.txt` Local maxima text file  
`*tstat*_clusters.txt` Clusters table

# Learn more

For more details about options and how to interpret the output, see the Randomise [user guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/UserGuide).

