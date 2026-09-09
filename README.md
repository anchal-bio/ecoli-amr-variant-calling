# AMR-Seq: An E. coli Antibiotic Resistance Variant Calling Pipeline

## Overview

This project explores variant calling using E. coli as a simple starting genome — walking through the full process from raw sequencing reads to identifying mutations that might affect antibiotic resistance genes
.
**Research question:** Does this E. coli isolate carry mutations in genes known to be linked with antibiotic resistance, and what do these mutations suggest about how resistance might be occurring (e.g., changes to the antibiotic's target, or to the pump that removes the drug from the cell)?
## Data

| Item | Details |
|---|---|
| Reference genome | *E. coli* K-12 MG1655, NCBI RefSeq [GCF_000005845.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000005845.2/) |
| Sample | SRA run [SRR40354247](https://www.ncbi.nlm.nih.gov/sra/?term=SRR40354247) — Illumina NextSeq 500, paired-end, antibiotic-resistant *E. coli* isolate from a slaughterhouse surveillance study (Nigeria) |
| Reads | ~881,788 read pairs, 118 MB |

## Tools Used

Managed via Conda (`environment.yml`):

- **FastQC** — raw read quality control
- **fastp** — read trimming
- **BWA** — read alignment to reference
- **samtools** — BAM sorting/indexing
- **bcftools** — variant calling and filtering
- **SnpEff** — variant annotation
- **IGB (Integrated Genome Browser)** — visual verification of variant calls

## Pipeline

1. Quality check raw reads (FastQC)
2. Trim low-quality bases/adapters (fastp)
3. Index reference genome (BWA)
4. Align reads to reference (BWA-MEM) → SAM
5. Convert, sort, and index alignments (samtools) → sorted BAM
6. Call variants (bcftools mpileup + call, `--ploidy 1` since *E. coli* is haploid)
7. Filter low-confidence variants (QUAL < 20 or DP < 10)
8. Annotate variants by gene/effect (SnpEff)
9. Screen annotated variants for known resistance genes
10. Visually verify key variants in IGB

## Results

- **33,763** high-confidence variants identified after filtering (from an initial 34,474)
- **51** of these variants fall within genes classically associated with antibiotic resistance

| Gene | Variants | Notable effects |
|---|---|---|
| gyrA | 12 | 2 stop-gained (HIGH impact) |
| parC | 13 | missense |
| parE | 8 | missense |
| gyrB | 7 | 1 frameshift (HIGH impact) |
| ampC | 8 | 3 stop-gained (HIGH impact) |
| tolC | 2 | missense |
| acrB | 1 | missense |

## Interpretation

This project analyzes whole-genome sequencing data (SRR40354247) from an antibiotic-resistant *E. coli* isolate collected in a slaughterhouse surveillance study in Nigeria. Reads were quality-checked (FastQC), trimmed (fastp), and aligned to the *E. coli* K-12 MG1655 reference genome (BWA-MEM). Variants were called using bcftools and annotated with SnpEff to identify their functional impact and gene location.

The pipeline identified 33,763 high-confidence variants relative to the K-12 MG1655 reference genome after quality filtering. Of these, 51 variants were located within genes classically associated with antibiotic resistance, including *gyrA*, *gyrB*, *parC*, *parE*, *ampC*, *tolC*, and *acrB*.

Notably, *gyrA*, *gyrB*, *parC*, and *parE* together encode DNA gyrase and topoisomerase IV — the direct molecular targets of fluoroquinolone antibiotics. The concentration of missense mutations in these genes, including two stop-gained variants in *gyrA* and one frameshift in *gyrB*, is consistent with a fluoroquinolone-resistance phenotype. Additionally, three stop-gained mutations in *ampC* suggest possible disruption of this beta-lactamase gene, while missense variants in the efflux pump component *tolC* and *acrB* may further influence drug efflux efficiency.

### Visual verification

Two of the *gyrA* variants (positions 2,328,652 and 2,328,655) were manually inspected in IGB by loading the reference genome and sorted BAM file. Both positions showed a consistent base change across nearly all aligned reads (as opposed to scattered, single-read mismatches seen elsewhere, which reflect sequencing noise) — supporting these as genuine variants rather than artifacts.

![gyrA variant in IGB](results/igb_gyrA_variant.png)

## Limitations

This analysis is exploratory and based on gene-level annotation rather than validated resistance-mutation databases (e.g., CARD, ResFinder). Confirming actual phenotypic resistance would require comparing specific variant positions against known resistance-conferring mutation catalogs, which is outside the scope of this beginner pipeline project.

Using a single reference strain (K-12 MG1655) means some detected variants may reflect normal inter-strain genetic diversity rather than resistance-specific mutations. Confirming which variants are resistance-causing would require checking against known resistance-conferring codon positions (e.g., QRDR positions in gyrA) rather than treating all missense variants in these genes as equally significant.

## Reproducing this pipeline

```bash
git clone (https://github.com/anchal-bio/ecoli-amr-variant-calling.git)
cd variant_calling_project
conda env create -f environment.yml
conda activate variant_calling
```

Then run the commands listed under [Pipeline](#pipeline) in order, using the reference and sample data described under [Data](#data).

## Project Structure

```
variant_calling_project/
├── environment.yml
├── README.md
├── reference/
│   └── ecoli_reference.fna
├── raw_data/
│   ├── SRR40354247_1.fastq
│   ├── SRR40354247_2.fastq
│   └── filtered_variants.vcf, annotated_variants_v2.vcf, ...
├── results/
│   └── igb_gyrA_variant.png
└── scripts/
    └── (pipeline commands)
```
