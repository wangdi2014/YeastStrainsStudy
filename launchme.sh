#!/bin/bash
set -o errexit
set -o pipefail

thisdir=`pwd`

source $thisdir/runlist.sh
singlestrain=$1


if [ $# -lt 1 ]  || [ $1 == '-h' ]; then
    echo; echo "  Usage:" $(basename $0) \<strain\> 
    echo "  strain: Download data for this strain [s288c] (s288c,sk1,cbs,n44,all,none)"
    exit
fi

if  [ $singlestrain == "none" ]; then
    strains=( )
elif [ $singlestrain != "all" ]; then
    strains=( $singlestrain )
else
    strains=( s288c sk1 cbs n44 )
fi


function validate_url(){
  if [[ `wget -S --spider $1  2>&1  | grep exists` ]]; then echo "true"; else echo "false"; fi
}


##########################################
####### download some utilities ##########
##########################################
echo; echo " Downloading some utilities..."
mkdir -p $thisdir/src
cd $thisdir/src

if [ ! -f locpy/bin/activate ]; then
    pyversion=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(major);'`
    minor=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(minor);'`


    if [[ $pyversion != 2 ]] && [[ $pyversion != 3 ]]; then
        pyv=`python -c 'import platform; print(platform.python_version())'`
        echo; echo " "Warning!! This script needs python version > 2.7 ! 
        echo "  "python version found is $pyv
        echo "  "Please change python version!!
        exit 1
    elif [[ $pyversion == 2 ]] && [[ $minor < 7 ]]; then
        pyv=`python -c 'import platform; print(platform.python_version())'`
        echo; echo " "Warning!! This script needs python version > 2.7 ! 
        echo "  "python version found is $pyv
        echo "  "Please change python version!!
        exit 1
    fi
    

    virtualenv locpy
    source $thisdir/src/locpy/bin/activate
    pip install --upgrade pip
    pip install --upgrade distribute
    pip install cython
    pip install numpy
    pip install pandas
    pip install panda
    pip install matplotlib
    pip install seaborn
    deactivate
    
fi
source $thisdir/src/locpy/bin/activate

if [ ! -d  $thisdir/src/poretools ] ; then
    cd $thisdir/src/
    git clone https://github.com/arq5x/poretools.git
    cd poretools/
    git reset --hard 4e04e25f22d03345af97e3d37bd8cf2bdf457fc9   
    python setup.py install
fi
	

if [ ! -d  $thisdir/src/fq2fa ] ; then
    ## fastq 2 fasta
    cd $thisdir/src
    git clone -b nogzstream https://github.com/fg6/fq2fa.git
    cd fq2fa
    make
fi
	
if [ ! -d  $thisdir/src/random_subreads ] ; then
     ## subsample generator
    cd $thisdir/src
    git clone -b YeastStrainsStudy https://github.com/fg6/random_subreads.git
fi

echo "   ... ready!"


if [[ ${#strains[@]} -eq 0 ]]; then exit; fi


###################################################
  echo; echo " Downloading and preparing data..."
###################################################


###########################################
########## Download data from ENA #########
###########################################
cd $thisdir
source locpy/bin/activate


#******************* ONT ******************* #

folder=$thisdir/fastqs/ontfast5
	
mkdir -p $folder
cd $folder

for strain in "${strains[@]}"; do
    mkdir -p $folder/$strain
    cd  $folder/$strain

    thislist=ont${strain}[@]
    for tarfile  in "${!thislist}"; do
	file=$ontftp/$tarfile
	fold=$(basename "$tarfile" .tar.gz)

	if [ ! -f $tarfile ] && [ ! -f $fold.fastq ] ; then
	    if [[ `wget -S --spider $file 2>&1  | grep exists` ]]; then
	    	wget $ontftp/$tarfile
	    else 
		echo "Could not find url " $file
	    fi
	fi

	if [ ! -d $fold ] && [ ! -f $fold.fastq ] ; then
	    tar -xvzf $tarfile
	    echo untar
	fi
	    	    
	if [ ! -f $fold.fastq ]; then
	    echo poretools fastq --type 2D $fold  ">" $fold.fastq
	fi ## poretools
	    
    done # runs
    
    echo all done, now merge
    fqs=`ls *fastqs | wc -l` 
    
    if [ ! -z ${fqs-x} ]; then  
	echo ok $fqs
    else
	echo no fastqs
    fi


done # strain

exit
#******************* PacBio ******************* #

folder=$thisdir/fastqs/pbh5
mkdir -p $folder
cd $folder


for strain in "${strains[@]}"; do
    mkdir -p $folder/$strain
    cd  $folder/$strain

    runs=pb${strain}[@]

    for run in "${!runs}"; do
	mkdir -p  $folder/$strain/$run
	cd  $folder/$strain/$run

	thislist=pb$strain\_${run}[@]
	for tarfile  in "${!thislist}"; do
	    if [[ `wget -S --spider $tarfile 2>&1  | grep exists` ]]; then
	        #wget $ontftp/$tarfile
		echo $strain $tarfile ok
	    else 
		echo "Could not find url " $tarfile
	    fi
	done
    done
done

exit
#******************* MiSeq ******************* #

folder=$thisdir/fastqs/miseq
	
mkdir -p $folder
cd $folder

for strain in "${strains[@]}"; do
    mkdir -p $folder/$strain
    cd  $folder/$strain

    thislist=miseq${strain}[@]
    for cramfile  in "${!thislist}"; do
	file=$miseqftp/$cramfile
	if [ -f $cramfile ]; then
	    if [[ `wget -S --spider $file 2>&1  | grep exists` ]]; then
	    	#wget $miseqftp/$cramfile
		echo "   " $strain $file ok
	    else 
		echo "Could not find url " $file
	    fi
	fi
    done
done
