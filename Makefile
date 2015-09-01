# switches used for Repeat resolution on or off
# for first and second step
$REPEAT_RES_1 = 0
$REPEAT_RES_2 = 0


$INPUT_DIR = /vol/scratch/rozovr/M_res/
$READS_DIR = /home/gaga/rozovr/recycle_paper_data/


all: fetch_scripts

clean:
	rm fetch_*

#### fetch scripts used for processing bam file ####
# output bams used either for 2 step assembly or input
# to recycler
fetch_scripts: fetch_joins fetch_ands

fetch_joins: extract_contig_joining_pairs.c
	gcc -o $@ $^ -L. -lbam -lz

fetch_ands: extract_mate_pair_type_reads.c
	gcc -o $@ $^ -L. -lbam -lz

# filtered_bams: fetch_joins fetch_ands *.bam
# 	fetch_ands 

#### 2 step assembly process ####
# inputs: reads, initial spades assembly directory
# aligns reads to assembly
# filters reads to proper vs improper

ifeq $(REPEAT_RES_1, 0)
$INPUT1 = before_rr.fasta
else
$INPUT1 = contigs.fasta
endif

ifeq $(REPEAT_RES_2, 0)
$INPUT2 = before_rr.fasta
$GRAPH2 = before_rr.fastg
else
$INPUT2 = contigs.fasta
$GRAPH2 = contigs.fastg
endif


#map reads to contigs:
two_step_assemble: index_reads map_reads split_bam bams_to_fq re_assemble

index_reads:
	cd $(INPUT_DIR)
	~/bwa/bwa index $(INPUT1)


map_reads: $(INPUT1).bwt $(INPUT1).ann $(INPUT1).amb $(INPUT1).sa
	~/bwa/bwa mem -t 16 $(INPUT1) \
	$(READS_DIR)/M_1_trimmed.fastq \
	$(READS_DIR)/M_2_trimmed.fastq | \
	samtools view -buS - > reads_to_$(INPUT1).bam

split_bam: reads_to_$(INPUT1).bam
	samtools view -bf 66 -F 4 reads_to_$(INPUT1).bam | samtools sort -n - reads_to_$(INPUT1).proper-r1
	samtools view -bf 130 -F 4 reads_to_$(INPUT1).bam | samtools sort -n - reads_to_$(INPUT1).proper-r2
	samtools view -bf 64 -F 6 reads_to_$(INPUT1).bam | samtools sort -n - reads_to_$(INPUT1).flagged-r1
	samtools view -bf 128 -F 6 reads_to_$(INPUT1).bam | samtools sort -n - reads_to_$(INPUT1).flagged-r2

bams_to_fq: reads_to_$(INPUT1).proper-r1.bam reads_to_$(INPUT1).proper-r2.bam reads_to_$(INPUT1).flagged-r1.bam reads_to_$(INPUT1).flagged-r2.bam
	$gaga/bedtools2-2.20.1/bin/bamToFastq -i reads_to_$(INPUT1).proper-r1.bam -fq reads_to_$(INPUT1).proper-r1.fastq
	$gaga/bedtools2-2.20.1/bin/bamToFastq -i reads_to_$(INPUT1).proper-r2.bam -fq reads_to_$(INPUT1).proper-r1.fastq
	$gaga/bedtools2-2.20.1/bin/bamToFastq -i reads_to_$(INPUT1).flagged-r1.bam -fq reads_to_$(INPUT1).flagged-r1.fastq
	$gaga/bedtools2-2.20.1/bin/bamToFastq -i reads_to_$(INPUT1).flagged-r1.bam -fq reads_to_$(INPUT1).flagged-r2.fastq

re_assemble:
	/home/gaga/rozovr/SPAdes-3.5.0-Linux/bin/spades.py --pe1-1 \
	reads_to_$(INPUT1).proper-r1.fastq \
	--pe1-2 reads_to_$(INPUT1).proper-r2.fastq \
	--mp1-1 reads_to_$(INPUT1).flagged-r1.fastq \
	--mp1-2 reads_to_$(INPUT1).flagged-r2.fastq \
	-s $(READS_DIR)/M_U1_trimmed.fastq \
	-s $(READS_DIR)/M_U1_trimmed.fastq -o \
	$(INPUT_DIR)/iter2_on_$(INPUT1)/

recycle: $(INPUT_DIR)/iter2_on_$(INPUT1)/$(INPUT2) $(INPUT_DIR)/iter2_on_$(INPUT1)/$(GRAPH2) 






