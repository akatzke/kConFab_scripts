#!/bin/bash
# Bash script to run flair
# The script should only be executed in the activate anaconda environment
# Anna-Lena Katzke, 02/2022

# Set paths to reference data
FA=/home/MHH_NGS_Daten/User/katzkean/database_GRCh38/GRCh38.fa
GTF=/home/MHH_NGS_Daten/User/katzkean/database_GRCh38/GRCh38_gencode.gtf

# Set variables
OUT_DIR="flair"
OUT_NAME="flair_opti"
GEN="ENSG00000012048"

READS="output_guppy/pass/*fastq.gz"
OUTPUT="$OUT_DIR/$OUT_NAME"
#DIR=$(pwd)

######
# Start execution of flair
######

# Preparation
source /home/mh-hannover.local/katzkean/miniconda3/etc/profile.d/conda.sh
conda activate flair_env
export PATH="$PATH:/usr/bin/samtools-1.9"
if ! [[ -d "./output_guppy/pass" ]];then
	echo "output_guppy/pass doesn't exist"
	exit 1
fi
if ! [[ -d $OUT_DIR ]];then
	echo "Directory doesn't exist. Creating directory"
	mkdir $OUT_DIR
fi

echo "Start alignment"
OUTPUT_ALIGN="${OUTPUT}.bed"
if [[ -f $OUTPUT_ALIGN ]];then
	  echo "Skipping; File already exists"
else
	  python /home/flair/flair/flair.py align -g $FA -r $READS -o $OUTPUT -v1.3
fi

## Start correction
echo "Start correct"
OUTPUT_COR="${OUTPUT}_all_corrected.bed"
OUTPUT_ALIGN="${OUTPUT}.bed"
if [[ -f $OUTPUT_ALIGN ]];then
	  echo "Using the following aligned file:"
    echo $OUTPUT_ALIGN
    if [[ -f $OUTPUT_COR ]];then
	      echo "Skipping; File already exists"
    else
	      python /home/flair/flair/flair.py correct -g $FA -q $OUTPUT_ALIGN -f $GTF -o $OUTPUT
    fi
else
    echo "Couldn't find aligned file:"
    echo $OUTPUT_ALIGN
    exit 1
fi

## Start collapse
echo "Start collapse"
OUTPUT_COL="${OUTPUT}.isoforms.fa"
if [[ -f $OUTPUT_COL ]];then
	echo "Skipping; File already exists"
else
  echo $OUTPUT_COL
	python /home/flair/flair/flair.py collapse -g $FA -q $OUTPUT_COR -r $READS -f $GTF -o $OUTPUT --filter nosubset --no_redundant best_only
fi

## Start quantify
echo "Start quantify"
OUTPUT_QUA="${OUTPUT}_counts_matrix.tsv"
SAMPLES="/home/MHH_NGS_Daten/Projects/MinIon/HerediVar_RNASeq/kConFab_BRCA1/Samples_guppy.tsv"
if [[ -f $OUTPUT_QUA ]];then
	echo "Skipping; File already exists"
else
	if ! [[ -f "./output_guppy/all_files.fastq.gz" ]];then
		cat ./output_guppy/pass/*fastq.gz > ./output_guppy/all_files.fastq.gz
	fi
	if ! [[ -f $SAMPLES ]];then
		echo "Samples.tsv doesn't exist. Please create before continuing"
		echo $SAMPLES
		exit 1
	fi
	python /home/flair/flair/flair.py quantify -r $SAMPLES -i $OUTPUT_COL -o $OUTPUT_QUA --salmon /home/mh-hannover.local/katzkean/miniconda3/envs/flair_env/bin/salmon
fi

## Start diffSplice
echo "Start diffSplice"
OUTPUT_DIFF="${OUTPUT}.alt5.events.quant.tsv"
OUTPUT_COL_BED="${OUTPUT}.isoforms.bed"
if [[ -f $OUTPUT_DIFF ]];then
	echo "Skipping; File already exits"
else
	python /home/flair/flair/flair.py diffSplice -i $OUTPUT_COL_BED -q $OUTPUT_QUA -o $OUTPUT
fi

## Start plot_isoform_usage
echo "Start plotting"
OUTPUT_PLOT="${OUTPUT}_usage.png"
OUTPUT_PLOT_ALL="${OUTPUT}_all_isoforms"
if [[ -f $OUTPUT_PLOT ]];then
	echo "Skipping; File already exists"
else
	python /home/flair/flair/bin/plot_isoform_usage_bk.py $OUTPUT_COL_BED $OUTPUT_QUA $GEN -o $OUTPUT
	python /home/flair/flair/bin/plot_isoform_usage.py $OUTPUT_COL_BED $OUTPUT_QUA $GEN -o $OUTPUT_PLOT_ALL --palette /home/MHH_LW_O/RNA_Seq/Script/colours.txt
fi

## Donw
echo "Finished"
