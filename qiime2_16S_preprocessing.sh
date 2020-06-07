source activate qiime2-2019.1


#Importing fastq files as a Qiime artifact:

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ./ --source-format CasavaOneEightSingleLanePerSampleDirFmt --output-path demux-paired-end.qza



#Visualizing the quality score of the reads and set the denoising parameters accordingly:

qiime demux summarize --i-data demux-paired-end.qza --o-visualization demux.qzv




#Denoising the reads with dada2:

qiime dada2 denoise-paired --i-demultiplexed-seqs demux-paired-end.qza --p-trim-left-f 0 --p-trim-left-r 0 --p-trunc-len-f 260 --p-trunc-len-r 260 --p-n-threads 12 --o-representative-sequences rep-seqs.qza --o-table table.qza --o-denoising-stats denoised-stats.qza



# Further filtering: Removal of the features that are less than 10 in abundance & Remove the samples that has less than 10 features:


qiime feature-table filter-features   --i-table table.qza   --p-min-frequency 10  --o-filtered-table frequency-filtered-table.qza


qiime feature-table filter-samples   --i-table frequency-filtered-table.qza   --p-min-features 10  --o-filtered-table freq_feat_filt_table.qza



#Exporting the feature table: 

qiime tools export frequency-filtered-table.qza --output-dir exported-feature-table


#Converting it to biom format:

biom convert -i feature-table.biom -o table.from_biom.txt --to-tsv





##### TAXONOMIC CLASSIFICATION #####


#Importing the Greengenes database as qiime2 artifacts:


qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path /home/ozkurt/Documents/databases/gg_13_5_otus/rep_set/99_otus.fasta \
  --output-path /home/ozkurt/Documents/databases/unite_12.01.17/16S_99_otus.qza




qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --source-format HeaderlessTSVTaxonomyFormat \
  --input-path /home/ozkurt/Documents/databases/gg_13_5_otus/taxonomy/99_otu_taxonomy.txt  \
  --output-path /home/ozkurt/Documents/databases/gg_13_5_otus/16S_99_ref-taxonomy.qza




#Extracting reads from the database based on the matches to the primer pair:


qiime feature-classifier extract-reads \
  --i-sequences /home/ozkurt/Documents/databases/gg_13_5_otus/16S_99_otus.qza \
  --p-f-primer AACMGGATTAGATACCCKG \
  --p-r-primer ACGTCATCCCCACCTTCC \
  --p-trunc-len 300 \
  --o-reads /home/ozkurt/Documents/databases/gg_13_5_otus/V5-99-ref-seqs.qza


# Training the naive-bayes classifier:

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads /home/ozkurt/Documents/databases/gg_13_5_otus/V5-99-ref-seqs.qza  \
  --i-reference-taxonomy /home/ozkurt/Documents/databases/gg_13_5_otus/16S_99_ref-taxonomy.qza \
  --o-classifier V5_99_classifier.qza





#Producing nd exporting the taxonomic classification:

qiime feature-classifier  classify-sklearn --i-classifier /home/ozkurt/Documents/databases/gg_13_5_otus/V5_99_classifier.qza --i-reads rep-seqs.qza --o-classification taxonomy99.qza


qiime metadata tabulate --m-input-file taxonomy99.qza --o-visualization taxonomy99.qzv



#### PHYLOGENETIC TREE######


#Aligning the reads:


qiime alignment mafft --i-sequences rep-seqs.qza --o-alignment aligned-rep-seqs.qza




#Maskng the alignment to remove positions that are highly variable:


qiime alignment mask --i-alignment aligned-rep-seqs.qza --o-masked-alignment masked-aligned-rep-seqs.qza



#Generating a phylogenetic tree from the masked alignment by using FastTree:


qiime phylogeny fasttree  --i-alignment masked-aligned-rep-seqs.qza --o-tree unrooted-tree.qza



#Rooting the tree: "midpoint rooting to place the root of the tree at the midpoint of the longest tip-to-tip distance in the unrooted tree":


qiime phylogeny midpoint-root --i-tree unrooted-tree.qza --o-rooted-tree rooted-tree.qza


#Exporting the tree:


qiime tools export unrooted-tree.qza --output-dir exported-tree
