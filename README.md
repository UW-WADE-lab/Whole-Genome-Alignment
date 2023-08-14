# Whole-Genome-Alignment
Pipeline workflow to download whole genome sequence data from NCBI Genbank and align to a reference fasta using bwa, samtools, and bcftools

### Steps for Alignment and Mutation Rate Calculation
1. Pre-alignment documentation steps (see below)
2. Run alignment script (ceetacean_genome_alignment.txt)
3. Use alignment script vcf file output in the script for counting whole genome SNPs (WG_count_snps.txt)
4. Use alignment script vcf file output in script for counting individual chromosome SNPs (chromsome_level_variant_count.txt)
5. Outputs from steps 3 and 4 can be used in R scripts for whole-genome (whole-genome-mutation-rate-delphinids.R) and chromosome-level (mutation-rate-by-chromosome.R) mutation rate calculation

# Pre-Alignment Documentation
### Download and install SRAtoolkit
```
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -vxzf sratoolkit.tar.gz
```
Once SRAtoolkit is downloaded, you need to add it to your PATH:
```
export PATH=$PATH:$PWD/sratoolkit.<release>-<platform>/bin
```
Test to make sure that the download and unzip worked properly and the PATH has been updated:
```
which fastq-dump
```
If this worked correctly, you should see something similar to the following:
```
/Users/JoeUser/sratoolkit.3.0.0-mac64/bin/fastq-dump
```
Next, test that the toolkit is functional:
```
fastq-dump --stdout -X 2 SRR390728
```
This should produce exactly the following, no more or less:
```
Read 2 spots for SRR390728
Written 2 spots for SRR390728
@SRR390728.1 1 length=72
CATTCTTCACGTAGTTCTCGAGCCTTGGTTTTCAGCGATGGAGAATGACTTTGACAAGCTGAGAGAAGNTNC
+SRR390728.1 1 length=72
;;;;;;;;;;;;;;;;;;;;;;;;;;;9;;665142;;;;;;;;;;;;;;;;;;;;;;;;;;;;;96&&&&(
@SRR390728.2 2 length=72
AAGTAGGTCTCGTCTGTGTTTTCTACGAGCTTGTGTTCCAGCTGACCCACTCCCTGGGTGGGGGGACTGGGT
+SRR390728.2 2 length=72
;;;;;;;;;;;;;;;;;4;;;;3;393.1+4&&5&&;;;;;;;;;;;;;;;;;;;;;<9;<;;;;;464262
```
### Downloading fastq files using SRAtoolkit

The first step to download fastq files with SRAtoolkit is to find the SRR accession numbers for the species/sequences that you want to download. You can do that manually, or via the command line by installing edirect. [This page](https://bioinformaticsworkbook.org/dataAcquisition/fileTransfer/sra.html#gsc.tab=0) includes instructions for both options. 

Once you have found the SRR accessions numbers for files you want to download, open a terminal interface, create directory for fastq files to download into, and move into that directory:
```
mkdir [dirname]
cd [dirname]
```
One in the new directory, use fastq-dump to download SRR files from NCBI and back-process them into fastq files. The flags specified here will zip the files to save space (--gzip), convert them to their original format (--origfmt), and split the files in the forward and reverse reads (--split-files). Fastq-dump is slow and can take a long time if the SRR files are very large, so using a command like 'tmux' can make sure that your connection doesn't break midway through a download. Alternatively, you can use `prefetch` from the SRAtoolkit to download the SRR files before processing them with fastq-dump.

```
#open a tmux terminal
tmux

#start fastq download
fastq-dump --gzip --origfmt --split-files SRR[# from ncbi]
fastq-dump --gzip --origfmt --split-files SRR[# from ncbi]
```
Files downloaded from NCBI may be missing sequence information that defines forward and reverse reads, which is used by bwa to pair reads. To fix this, first install [BBMap](https://sourceforge.net/projects/bbmap/) using apt-get:
```
sudo apt-get update
sudo apt-get -y install bbmap
```
One BBMap is installed, use 'reformat.sh' to reformat fastq files, adding a /1 or /2 to filenames:
```
reformat.sh addslash=t in1=[filename]1.fq.gz in2=[filename]2.fq.gz out1=fixed.[filename]1.fq.gz out2=fixed.[filename]2.fq.gz
```
Once files are reformatted, they can be transferred to Hyak and used in the genome alignment pipeline:
```
scp /path/to/fixed_[filename]?.fq.gz [UW NetID]@klone.hyak.uw.edu:/path/to/directory
```
