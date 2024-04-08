# kConFab_scripts

## Exon coverage
Contains python command line script to compute exon coverage per exon.
Example bed files for both BRCA1 and BRCA2 are included.
The position of the first and last exon are corrected for the primers that are in use by us (Lab Hanover and Cologne).

The script will automatically find all files matching the pattern in the directory and quantify the coverage of each exon defined in the bed file for each of the files.

Dependencies:
- Samtools
- Pandas

Please use as follows:

    python exon_coverage.py -r path/BRCA1.bed -d path/directory/ -p dir_bam/file.bam

## FLAIR script

FLAIR scripts for executing FLAIR with optimised parameters.
One script is defined for basecalling with Guppy and one for basecalling with Dorado.
