#!/bin/bash
set -o errexit
set -o pipefail


thisdir=`pwd`
wdir=results/pacbio_ontemu_subsample31X
srcdir=$thisdir/../utils/src

help=$1


if [[ $help != '' ]]; then
        echo; echo "  Usage:" $(basename $0) 
        echo "  "This script generates an s288c PacBio subsample with same read depth and  
        echo "    "similar read length distribution as s288c ont pass2D sample \(31X\)
	echo "    "output will be in $wdir
   	exit 1
fi

### check python version
pyversion=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(major);'`
if [[ $pyversion != 2 ]] && [[ $pyversion != 3 ]]; then
        pyv=`python -c 'import platform; print(platform.python_version())'`
	echo; echo " "Warning!! This script needs python 2 or 3 ! 
	echo "  "python version found is $pyv
	echo "  "Please change python version!!
	exit 1
fi



pbreads=$thisdir/../fastqs/pacbio/s288c/s288c_pacbio.fastq
ontreads=$thisdir/../fastqs/ont/s288c/s288c_pass2D.fastq

mkdir -p $wdir
cd $wdir
echo " Results will be in " $wdir; echo
python $srcdir/random_subreads/subrand.py -i $pbreads -x $ontreads 


