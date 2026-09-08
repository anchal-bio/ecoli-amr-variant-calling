#!/bin/bash
# E. coli Antibiotic Resistance Variant Calling Pipeline
# Run this from inside the activated conda environment: conda activate variant_calling

set -e  # stop the script if any command fails

# ---- 1. FastQC for checking quality of raw reads ----
cd raw_data
fastqc SRR40354247_1.fastq SRR40354247_2.fastq

# ---- 2. Trim reads ----
fastp -i SRR40354247_1.fastq -I SRR40354247_2.fastq \
      -o trimmed_1.fastq -O trimmed_2.fastq

# ---- 3. Index reference genome ----
cd ../reference
bwa index ecoli_reference.fna

# ---- 4. Align reads to reference ----
cd ../raw_data
bwa mem ../reference/ecoli_reference.fna trimmed_1.fastq trimmed_2.fastq > aligned.sam

# ---- 5. Convert, sort, index alignment ----
samtools view -bS aligned.sam > aligned.bam
samtools sort aligned.bam -o sorted.bam
samtools index sorted.bam

# ---- 6. Call variants (haploid organism) ----
bcftools mpileup -f ../reference/ecoli_reference.fna sorted.bam > raw_calls.vcf
bcftools call -mv --ploidy 1 -o variants.vcf raw_calls.vcf

# ---- 7. Filter low-confidence variants ----
bcftools filter -e 'QUAL<20 || DP<10' -o filtered_variants.vcf variants.vcf

# ---- 8. Rename chromosome to match SnpEff database, then annotate ----
echo "NC_000913.3 Chromosome" > chr_rename.txt
bcftools annotate --rename-chrs chr_rename.txt filtered_variants.vcf > filtered_renamed.vcf
snpEff Escherichia_coli_k_12 filtered_renamed.vcf > annotated_variants_v2.vcf

# ---- 9. Screen for known antibiotic resistance genes ----
grep -E "(missense_variant|stop_gained|frameshift_variant)\|(HIGH|MODERATE)\|(acrA|acrB|acrR|marR|marA|ampC|tolC|gyrA|gyrB|parC|parE)\|" \
     annotated_variants_v2.vcf > resistance_gene_hits.txt

echo "Pipeline complete. See resistance_gene_hits.txt for resistance-gene variant hits."
