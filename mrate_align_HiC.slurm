#!/bin/bash
#SBATCH --account=coenv
#SBATCH --partition=compute # Queue selection
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --mem=50G
#SBATCH --time=96:00:00 # Time limit hrs:min:sec\

#SBATCH --job-name=HiC_align # Job name
#SBATCH --mail-type=ALL # Mail events (BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=sgarrote@uw.edu # Where to send mail\
#SBATCH --output=HiC_alignment.log # Standard output/error\
#SBATCH --chdir=/gscratch/scrubbed/sgarrote
#SBATCH --export=all
#SBATCH --error=HiC_align_error.log # Standard error

#BEFORE RUNNING THIS SCRIPT:
#mkdir /gscratch/scrubbed/sgarrote/cachedir

export APPTAINER_CACHEDIR=/gscratch/scrubbed/sgarrote/cachedir

module load coenv/samtools stf/bwa/0.7.17 coenv/bcftools stf/seqtk/1.3 coenv/jdk stf/bedtools coenv/bwa-mem2

#set sample ID
sample=[sample name]

#Hi-C steps for aligning genomes
echo "### Step 1.A: FASTQ to BAM (1st)"
bwa-mem2 mem -t 40 /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna ${sample}_1.fastq.gz | samtools view -@ 40 -Sb - > ${sample}_aligned_1.bam

echo "###Step 1.B: FASTQ to BAM (2nd)"
bwa-mem2 mem -t 40 /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna ${sample}_2.fastq.gz | samtools view -@ 40 -Sb - > ${sample}_aligned_2.bam

echo "### Step 2.A: Filter 5' end (1st)"
samtools view -h ${sample}_aligned_1.bam | perl filter_five_end.pl | samtools view -Sb - > ${sample}_aligned_filt_1.bam

echo "### Step 2.B: Filter 5' end (2nd)"
samtools view -h ${sample}_aligned_2.bam | perl filter_five_end.pl | samtools view -Sb - > ${sample}_aligned_filt_2.bam

echo "### Step 3A: Pair reads & mapping quality filter"
perl two_read_bam_combiner.pl ${sample}_aligned_filt_1.bam ${sample}_aligned_filt_2.bam samtools 10 | samtools view -bS -t GCF_002837175.3_ASM283717v5_genomic.fna.fai - | samtools sort -@ 40 -o ${sample}_aligned_filt.bam -

echo "### Step 3.B: Add read group"
java -Xmx8G -Djava.io.tmpdir=/gscratch/scrubbed/sgarrote/ -jar '/mmfs1/home/sgarrote/src/picard.jar' AddOrReplaceReadGroups INPUT=${sample}_aligned_filt.bam OUTPUT=${sample}_aligned_filt_readgrp.bam ID=${sample} LB=${sample} SM=$${sample} PL=ILLUMINA PU=none

#remove duplicates w/ picard
java -Xmx8G -jar -Djava.io.tmpdir=/gscratch/scrubbed/sgarrote \
/mmfs1/home/sgarrote/src/picard.jar MarkDuplicates I=${sample}_aligned_filt_readgrp.bam O=${sample}_dedup.bam M=${sample}_dedup_metrics.txt REMOVE_DUPLICATES=true

#repeat masker w/ bedtools
bedtools intersect -abam ${sample}_dedup.bam -b Pmac_GCA_002837175.5_ASM283717v5_rm.bed -v > ${sample}_dedup_noRepeats.bam 2>${sample}_RM_log.txt

#index bam file
samtools index ${sample}_dedup_noRepeats.bam

#samtools pileup for a single sample and call SNPs
bcftools mpileup -Ou --threads 32 --max-depth 500 -f /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna ${sample}_dedup_noRepeats.bam | bcftools call -vm -Ob -o ${sample}_variants.bcf

#filter variants
bcftools view ${sample}_variants.bcf | vcfutils.pl varFilter -d 10 -D 500 > ${sample}_flt.vcf

