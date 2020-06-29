#!/bin/bash
#SBATCH --job-name=randomise
#SBATCH --output=%x_%A.out
#SBATCH --time=1-00:00:00
#SBATCH --partition=ncf
#SBATCH --mail-type=END,FAIL
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#
#
#COMMAND LINE ARGUMENTS ARE USED TO SET THESE VALUES.
#NO NEED TO EDIT THEM DIRECTLY.
#SEE THE HELP TEXT BELOW OR BY RUNNING
#  bash thisscriptname.bash -h
#
set -e
gfeatdir=""
copenumber=""
analysis=""
cope4d=""
dryrun=""
onesample=""
outpre="randomise"
NPERM=10000
mask="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"

if [ $# -eq 0 ]; then
	echo "No arguments supplied. Run this script with -h for help."
	exit 1
fi

while getopts ":g:c:f:m:p:hn1" flag
do
	case "${flag}" in
		h )
			echo "  Please read the FSL Randomize user guide before using this script:"
			echo "    - https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/UserGuide"
			echo ""
			echo "  Run randomise with 10,000 permutations using design of group-level"
			echo "  feat model. Given the design.fsf file, this script attempts to"
			echo "  locate the cope*.nii.gz files specified in the fsf file, concatenate"
			echo "  them into the requisite 4d file, and submit them to randomise along"
			echo "  with the design. The files that are normally required, and that are"
			echo "  generated by the group-level feat model are:"
			echo ""
			echo "   - design.con"
			echo "   - design.fsf"
			echo "   - design.grp"
			echo "   - design.mat"
			echo ""
			echo "  If the fsf file contains full paths to the first level feat but not"
			echo "  specific cope*.nii.gz, the user must specify which cope number to"
			echo "  use. In that case, the script assumes the cope file is found in"
			echo "  [group-level feat directory/reg_standard/stats/. If the user"
			echo "  specifies '-c 1', it will use cope1.nii.gz in that directory for"
			echo "  each first level feat directory in the design.fsf file. If the user"
			echo "  has already created a 4d file that corresponds to the design.mat"
			echo "  the script can use that rather than using fslmerge to create a new"
			echo "  one. If a one-sample t-test is requested, the user can bypass the"
			echo "  design.mat file with the -1 option, in which case only enough info"
			echo "  for the script to find or create the 4d cope is required."
			echo "  "
			echo "  Usage:"
			echo "    bash script.bash [options]"
			echo "  "
			echo "  Options are:"
			echo "    -h                              Show this message."
			echo "    -g [group-level feat directory] Specify group-level feat dir."
			echo "    -c [cope number as integer]     Specify cope number from first-level."
			echo "    -f [4d nii.gz]                  Path of 4d nii.gz with first-level data."
			echo "    -m [mask]                       Path of the mask to use. Defaults to FSL MNI 2mm" 
			echo "    -p [Number of permutations]     Default is 10,000, which is recommended."
			echo "    -o [outfile prefix]             Default is 'randomise'"
			echo "    -1                              One sample t-test."
			echo "    -n                              Dry run."
			exit 0
			;;
		g ) 
			gfeatdir=${OPTARG}
			;;
		c ) 
			copenumber=${OPTARG}
			if [[ ! $copenumber =~ ^[0-9]$ ]]; then
			       echo "ERROR: $copenumber is not a valid integer"
			       exit 1
			fi
			;;
		f ) 
			cope4d=${OPTARG}
			;;
		m )
			mask=${OPTARG}
			;;
		p )
			NPERM=${OPTARG}
			if [[ ! $NPERM =~ ^[0-9]$ ]]; then 
				echo "ERROR: $NPERM is not a valid integer"
				exit 1
			fi
			;;
		o)
			outpre=${OPTARG}
			;;
		1 )
			onesample="onesample"
			;;	
		n )
			dryrun="dryrun"
			;;	
		\? )
			echo "Invalid option: ${OPTARG}" 1>&2
			exit 1
			;;
		: )
			echo "Invalid option: ${OPTARG} requires an argument" 1>&2
			exit 1
			;;	
	esac
done
shift $((OPTIND -1))

if [ -z "$dryrun" ]; then
	echo "Loading FSL"
#	module load centos6/0.0.1-fasrc01  ncf/1.0.0-fasrc01 fsl/6.0.2-ncf
fi
echo "Executing in $(pwd)"

firstlevel4d=""
if [ $cope4d ]; then
	echo "Using user specified 4d file for input: ${cope4d}"
	firstlevel4d=${cope4d};
elif [ $gfeatdir ]; then
	echo "Copying fsf file from ${gfeatdir}"
	cp -v "${gfeatdir}/design.fsf" ./ 
	inputs=`cat design.fsf | grep feat_file | awk -F " " '{print $3}' | sed -e 's/\"//g'`
	if grep -q "nii.gz$" <<< "${inputs}"; then
		if [ $copenumber ]; then
			echo "Cope number supplied, but fsf file contains specific references to nii.gz files. Ignoring user-supplied cope number."
		fi
		echo "Creating 4d file from nii.gz files specified in design.fsf..."
		firstlevel4d="first_level4d_fsf.nii.gz"
	elif [ $copenumber ]; then
		echo "design.fsf does not specify nii.gz files. Using cope number: ${copenumber}"
		inputs=`cat design.fsf | grep feat_file | awk -F " " '{print $3}' | sed -e 's/\"//g' | sed -e "s/$/\/reg_standard\/stats\/cope${copenumber}.nii.gz/g"`
		firstlevel4d="first_level4d_cope${copenumber}.nii.gz"
		echo "Creating 4d file from nii.gz specified by user: ${firstlevel4d} ..."
	else
		echo "ERROR: design.fsf does not contain nii.gz files, and no cope number supplied. Aborting."
		exit 1;
	fi
	if [ $dryrun ]; then
		echo fslmerge -t first_level4d.nii.gz ${inputs}
	else
		fslmerge -t ${firstlevel4d} ${inputs}
	fi
	echo "Done."
else
	echo "ERROR: Must provide group-feat level directory or 4d file."
	exit 1
fi

if [ -z $onesample ]; then
	echo "Copying design files from ${gfeatdir}"
	cp -v "${gfeatdir}/design.con" ./
	cp -v "${gfeatdir}/design.grp" ./
	cp -v "${gfeatdir}/design.mat" ./
	echo "Contrasts are:"
	cat design.con
	echo "Running Randomise (${NPERMS} per contrast)..."
	if [ $dryrun ]; then
		echo randomise -i ${firstlevel4d} -o ${outpre} -d design.mat -t design.con -e design.grp -m "${mask}" -n $NPERM -T
	else
		randomise -i ${firstlevel4d} -o ${outpre} -d design.mat -t design.con -e design.grp -m "${mask}" -n ${NPERM} -T
	fi
else
	if [ $dryrun ]; then
		echo randomise -i ${firstlevel4d} -o ${outpre} -1 -m "${mask}" -n ${NPERM} -T
	else
		randomise -i ${firstlevel4d} -o ${outpre} -1 -m "${mask}" -n ${NPERM} -T
	fi
fi


