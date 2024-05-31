#!/bin/bash
#SBATCH --account=coenv
#SBATCH --partition=compute # Queue selection
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --mem=75G
#SBATCH --time=72:00:00 # Time limit hrs:min:sec\

#SBATCH --job-name=shortread_align # Job name
#SBATCH --mail-type=ALL # Mail events (BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=sgarrote@uw.edu # Where to send mail\
#SBATCH --output=shortread_alignment.log # Standard output/error\
#SBATCH --chdir=/gscratch/coenv/sgarrote
#SBATCH --export=all
#SBATCH --error=shortread_align_error.log # Standard error

#BEFORE RUNNING THIS SCRIPT:
#mkdir /gscratch/scrubbed/sgarrote/cachedir

export APPTAINER_CACHEDIR=/gscratch/scrubbed/sgarrote/cachedir

module load coenv/samtools stf/bwa/0.7.17 coenv/bcftools stf/seqtk/1.3 coenv/jdk stf/bedtools

#set sample ID
sample=[sample name]

#align to reference genome
bwa mem -t 32 -k 19 /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna ${sample}_1.fastq.gz ${sample}_2.fastq.gz > ${sample}_aligned.sam

#convert to bam file
samtools view -@ 40 -T /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna -b ${sample}_aligned.sam | samtools sort -@ 40 -o ${sample}_aligned_sorted.bam
rm ${sample}_aligned.sam

#picard remove duplicates
java -Xmx8G -jar -Djava.io.tmpdir=/gscratch/scrubbed/sgarrote \
/mmfs1/home/sgarrote/src/picard.jar MarkDuplicates -I ${sample}_aligned_sorted.bam -O ${sample}_dedup.bam -M ${sample}_dedup_metrics.txt -REMOVE_DUPLICATES true

#repeat masker w/ bedtools
bedtools intersect -abam /gscratch/coenv/sgarrote/${sample}_dedup.bam -b /gscratch/scrubbed/sgarrote/Pmac_GCA_002837175.5_ASM283717v5_rm.bed -v > ${sample}_dedup_noRepeats.bam 2>/gscratch/coenv/sgarrote/${sample}_RM_log.txt

#index bam file
samtools index ${sample}_dedup_noRepeats.bam

#samtools pileup for a single sample and call SNPs
bcftools mpileup -Ou --threads 32 --max-depth 500 -f /gscratch/scrubbed/sgarrote/Pmac_reference/GCF_002837175.3_ASM283717v5_genomic.fna ${sample}_dedup_noRepeats.bam | bcftools call -vm -Ob -o ${sample}_variants.bcf

#filter variants
bcftools view ${sample}_variants.bcf | vcfutils.pl varFilter -d 10 -D 500 > ${sample}_flt.vcf

