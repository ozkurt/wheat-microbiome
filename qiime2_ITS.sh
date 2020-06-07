source activate qiime2-2019.1


qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ./ --source-format CasavaOneEightSingleLanePerSampleDirFmt --output-path demux-paired-end.qza


qiime demux summarize --i-data demux-paired-end.qza --o-visualization demux.qzv


qiime itsxpress trim-pair-output-unmerged --cluster_id 0.995 --i-per-sample-sequences demux-paired-end.qza --p-region ALL --p-taxa F --p-threads 12 --o-trimmed trimmed_demux.qza

qiime quality-filter q-score \
 --i-demux trimmed_demux.qza \
 --o-filtered-sequences demux-filtered.qza \
 --o-filter-stats demux-filter-stats.qza





