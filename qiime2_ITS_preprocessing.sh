
#!/bin/bash
# script for pre-processing ITS (ITS1F-ITS2) amplicons sequencing using Qiime 2 v2.0
#Originally created by Ezgi Özkurt ozkurt@evolbio.mpg.de
#Qiime2 version used: qiime2-2019.1

#Loading modules:
source activate qiime2-2019.1


#Importing fastq files as a Qiime artifact

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ./ --source-format CasavaOneEightSingleLanePerSampleDirFmt --output-path demux-paired-end.qza


#Trimming the reads with the q2-itsxpress plugin

qiime itsxpress trim-pair-output-unmerged --i-per-sample-sequences demux-paired-end.qza --p-region ITS1 --p-taxa F --p-threads 12 --o-trimmed trimmed_demux.qza


# Denoising the data with Dada2:

qiime dada2 denoise-paired --i-demultiplexed-seqs trimmed_demux.qza --p-trim-left-f 0 --p-trim-left-r 0 --p-trunc-len-r 0 --p-trunc-len-f 0  --p-n-threads 0 --verbose --o-representative-sequences rep-seqs.qza --o-table table.qza --o-denoising-stats denoised-stats.qza


#Mergeing the datasets from two different sequencing runs


qiime feature-table merge --i-tables table.qza --i-tables table2.qza --o-merged-table table_merged.qza

qiime feature-table merge-seqs --i-data rep-seqs.qza --i-data rep-seqs2.qza --o-merged-data rep-seqs_merged.qza

#Do not forget to merge the sample data as well


#Exporting the table for the downstream analysis

qiime tools export table_merged.qza --output-dir exported-feature-table

#Converting the biom file into txt file
biom convert -i exported-feature-table/feature-table.biom -o table.from_biom.txt --to-tsv


 
#Training the UNITE database on full length ITS sequences
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads unite_12.01.17/ITS_99_otus.qza  \
  --i-reference-taxonomy ITS_99_ref-taxonomy.qza \
  --o-classifier classifier_ITS_99.qza

#Producing the Qiime2 taxonomy artifact

qiime feature-classifier  classify-sklearn --i-classifier unite_12.01.17/classifier_ITS_99.qza --i-reads rep-seqs_merged.qza --o-classification taxonomy99.qza






































