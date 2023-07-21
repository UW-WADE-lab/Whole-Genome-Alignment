# Whole-Genome-Alignment
Pipeline workflow to download whole genome sequence data from NCBI Genbank and align to a reference fasta using bwa, samtools, and bcftools

# Pre-Alignment Documentation
Install sratoolkit after downloading the tar file from ncbi (necessary for accessing ncbi files)
```
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -vxzf sratoolkit.tar.gz
```
If sratoolkit is in a different location
```
export PATH=$PATH:$PWD/sratoolkit.<release>-<platform>/bin
which fastq-dump
```
Downloading fastq files
```
#optional: create directory for fastq files to download into
#mkdir [dirname]
#cd [dirname]

fastq-dump --gzip --origfmt --split-files SRR[# from ncbi]
fastq-dump --gzip --origfmt --split-files SRR[# from ncbi]
```
Install BBMap after downloading the tar file from https://sourceforge.net/projects/bbmap/ (for editing the /s into the fastq file sequences)
```
sudo apt-get update
sudo apt-get -y install bbmap
```
Reformatting fastq file with /s
```
reformat.sh addslash=t in1=[filename]1.fq.gz in2=[filename]2.fq.gz out1=fixed.[filename]1.fq.gz out2=fixed.[filename]2.fq.gz
```
Transfer new files to Hyak
```
scp /path/to/fixed.[filename]?.fq.gz [UW NetID]@klone.hyak.uw.edu:/path/to/directory
```
