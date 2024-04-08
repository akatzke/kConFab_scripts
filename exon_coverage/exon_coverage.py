#!/usr/bin/env python3

import os
import pathlib
import argparse

import pandas as pd


parser = argparse = argparse.ArgumentParser()

parser.add_argument(
    "-r",
    "--region",
    default="",
    help="path to bed file containing regions of interest",
    type=str,
)
parser.add_argument(
    "-d",
    "--dir",
    help="path to directory of interest containing bam files with pattern specified using --pattern or -p",
    type=str,
)
parser.add_argument(
    "-p",
    "--pattern",
    help="pattern of bam file of interest, the directory will be searched for",
    type=str,
)
args = parser.parse_args()


def get_exon_converage(path_bed: pathlib.Path, path_bam: pathlib.Path):
    """
    Get coverage of each exon defined in bed file in bam file
    Using ~samtools coverage~ function
    """
    header = ["chr", "start", "stop", "ID", "exon_nr", "strand"]
    bed = pd.read_csv(path_bed, sep="\t", names=header)
    all_results = pd.DataFrame()
    for _, entry in bed.iterrows():
        print(entry)
        entry = get_samtools_count(entry, path_bam)
        all_results = pd.concat([all_results, entry])
    results_out = path_bam.parent.parent / "exon_coverage.csv"
    all_results.to_csv(results_out, sep="\t", index=False)


def get_samtools_count(entry: pd.Series, path_bam: pathlib.Path) -> pd.DataFrame:
    """
    Create command for samtools coverage
    """
    out_name = f"coverage_exon_{entry.exon_nr}.csv"
    out_path = path_bam.parent / out_name
    region = f"{entry.chr}:{entry.start}-{entry.stop}"
    command = f"samtools coverage -r {region} {str(path_bam)} > {str(out_path)}"
    os.system(command)
    coverage = pd.read_csv(out_path, sep="\t")
    return coverage


def run_get_exon_coverag_kConFab(
    path_bed: pathlib.Path, path_dir: pathlib.Path, pattern: str
):
    """
    Execute get_exon_coverage_kConFab for all files in the given directory
    """
    files = list(path_dir.rglob(pattern))
    for file_path in files:
        print(file_path)
        get_exon_converage(path_bed, file_path)


def main():
    if args.region == "":
        raise ValueError("No bed file with regions provided.")
    if args.dir == "":
        raise ValueError("No directory provided.")
    if args.pattern == "":
        raise ValueError("No pattern provided.")
    path_bed = pathlib.Path(args.region)
    if not path_bed.exists():
        raise ValueError("Path to bed file with regions does not exist.")
    path_dir = pathlib.Path(args.dir)
    if not path_dir.exists():
        raise ValueError("Directory path does not exist.")
    run_get_exon_coverag_kConFab(path_bed, path_dir, pattern)


if __name__ == "__main__":
    main()
