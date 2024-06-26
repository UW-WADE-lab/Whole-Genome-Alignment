# Whole-Genome-Alignment
Pipeline workflow to download whole genome sequence data from NCBI Genbank and align to a reference fasta using bwa, samtools, and bcftools

### Steps for Alignment and Mutation Rate Calculation
1. Pre-alignment documentation steps (see below)
2. Run alignment script (mrate_align_shortread.slurm OR mrate_align_HiC.slurm, depending on the format of your sample file)
3. Use alignment script vcf file output in the script for counting whole genome SNPs (WG_count_snps.txt)
4. Use alignment script vcf file output in script for counting individual chromosome SNPs (chromsome_level_variant_count.txt)
5. See the "Mutation-rate-variability-in-cetaceans" repository for further analysis and documentation beyond alignment

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
Files downloaded from NCBI may be missing sequence information that defines forward and reverse reads, which is used by bwa to pair reads. Specifically, we've noticed that the sequence names in these files are often missing the flag that denotes whether a sequence is forward or reverse. You can verify whether your downloaded files have this flag using the following code:
```
zcat [SRR_number]_1.fastq.gz | head -n 4
```
For example, once I've downloaded SRR10331559, using the following code:
```
zcat SRR10331559_1.fastq.gz | head -n 4
```
will read the top four lines of the file:
```
@1
CNGGTATGTATTTCTTGTGATAATGAAGGATTTTTATAAGAATGTGATTCACAAAGGTGTGCAAATGTATCAGTCTAGGCAATGTACATAGAGTTCAGGCTTTTCTTTAAAGGTACATGTTTCTTTATATCAACAGGAGTAGAAAAATAGT
+1
F#FFFFFFFFFF:FF,,FFFFFFFFFFFFFFFFFFFFFFFF:FFFFFFFFFFFFF:FFFFF:FFFFFFFFFFFF:FFFF:FFFFFF:FFFFFFFFFF:FFFFFFFFFFFFF:FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
```
Each entry in a fastq file contains four lines (read more about fastq file format [here](https://support.illumina.com/help/BaseSpace_OLH_009008/Content/Source/Informatics/BS/FileFormat_FASTQ-files_swBS.htm)). The top line is the sequence identifier starting with '@' and can contain a variety of information. In this example, the sequences are identified sequentially, and the first sequence is identified simply as '@1'. In addition to this, bwa looks for a flag in the sequence identifier to determine whether a sequence is forward (/1) or reverse (/2). If those don't exist, bwa doesn't know how to pair the reads. Luckily, we can fix this easily by reformating the files using a tool called BBMap.

First, install [BBMap](https://sourceforge.net/projects/bbmap/) using apt-get:
```
sudo apt-get update
sudo apt-get -y install bbmap
```
One BBMap is installed, use ['reformat.sh'](https://github.com/BioInfoTools/BBMap/blob/master/sh/reformat.sh) to reformat fastq files, adding a /1 or /2 to filenames:
```
reformat.sh addslash=t in1=[filename]1.fq.gz in2=[filename]2.fq.gz out1=fixed.[filename]1.fq.gz out2=fixed.[filename]2.fq.gz
```
Once files are reformatted, they can be transferred to Hyak and used in the genome alignment pipeline:
```
scp /path/to/fixed_[filename]?.fq.gz [UW NetID]@klone.hyak.uw.edu:/path/to/directory
```
### Indexing reference genomes using bwa
Once files have been transferred to Hyak, the reference genome which will be aligned to the sample genome needs to be aligned using bwa-mem. First, open an interactive computing session and load the modules required (bwa and bwa-mem2).
```
salloc -A mylab -p compute -N 1 -c 4 --mem=10G --time=2:30:00
module load coenv/bwa-mem2
module load stf/bwa
```
If you are aligning the reference genome to a Hi-C sample genome, indexing using both bwa and bwa-mem2 is necessary. However, if you are aligning a short-read format sample to your reference, only bwa indexing is required. Below, option '-a' is required, but use 'bwtsw' if the genome is long and 'is' if the genome is short. Note that the input reference genome could be .fasta OR .fna.
```
bwa index [-a bwtsw OR is] [input_reference].fasta index_prefix
bwa-mem2 index [input_reference].fasta
```
Additionally, generating a .fai file is required for the Hi-C alignment script, and for post processing of any alignment. To do this, load the samtools module and use the following command:
```
module load coenv/samtools
samtools faidx [input_reference].fasta
```
