############################################################
R Scripts written by Ezgi Ozkurt ozkurt@evolbio.mpg.de
############################################################

#required packages for the analysis the analysis

pkg=c("ggplot2", "phyloseq", “ape”,”vegan”,"metagenomeSeq”, ”ampviis2”,”PMCMR")

lapply(pkg, library, character.only = TRUE)



rm(list = ls()[grep("*.*", ls())])


#Input files: Files produced by qiime2 (feature_table.txt, taxonomy.txt, tree.nwk) and sample metadata (sample_metadata.txt).


#Pre-defined parameters for producing  plots:

color_palette<-c("#000000","#806600","#803300","666666","#EF5656","#47B3DA","#F7A415","#2BB065")



theme_new <- theme (
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  legend.position="none",
  axis.text.x = element_text(angle=90, vjust=1)
)




#####Importing the files into R:

sample_data=read.table(“sample_metadata.txt”,head=T,row.names=1)
tax=read.table("taxonomy.txt",head=T,row.names=1)
table=read.table(“feature_tabletxt", row.names=1)
                  tree=read.tree("tree.nwk")
                  
                  
                  
 ######Creating the phyloseq object:

tax=as.matrix(tax)
table=as.matrix(table)
otu_mat=otu_table(table,taxa_are_rows=T)
taxa_mat=tax_table(tax)
sd=sample_data(sample_data)
physeq=phyloseq(otu_mat,taxa_mat,sd, tree)
                  
                  
 ###### Filtering of the phyloseq object:
                  
 #Remove samples with less than a certain number (1000 reads for V5 and 200 reads for ITS reads):
 physeq1 = prune_samples(sample_sums(physeq) > 1000, physeq)
                  
#Removing the unassigned reads at domain level and mitochondrial reads:
taxa=c("Unassigned")
physeq2=subset_taxa(physeq1 Kingdom != "Unassigned")
physeq2=subset_taxa(physeq2, Family != " mitochondria")
                  
                  
###### Rarafaction of the feature table to its min number of readsfor  alpha diversity calculations (we rarefied seeds and seedlings data separately since they are originating from different sequencing runs):
rf=min(sample_sums(physeq_V5_leaves_roots))
physeq.rrf=rarefy_even_depth(physeq2, rf, replace=TRUE, rngseed = 699)
                  
                  
                  
###### Plotting alpha diversity estimates:
p=plot_richness(physeq2.rrf 'HostSpecies', 'HostType', measures=c("Shannon","Observed"))
                  
                  
subp1 =	ggplot(data=p$data[p$data$variable=="Observed",], aes(x=HostSpecies, y=value, color=c("black")))+
                  geom_boxplot(width=1)+ theme_new+
                  geom_point(size=4) +
                  scale_colour_manual(values=color_palette) + 
                  facet_wrap(~variable)
                  
                  
                  
##### Calculating the significance of the alpha diversity comparisons and correcting for multiple comparisons:
                  
                  
kruskal.test(data=subp1$data, value ~ HostType) #Global significance
posthoc.kruskal.conover.test(data=subp1$data, value ~ HostSpecies, method="BH" ) #Conover test as a posthoc
                  
                  
 ##### Normalizing the feature table for beta diversity calculations:
otumat=as(otu_table(physeq2),"matrix")
mp=newMRexperiment((otumat))
physeq_norm=phyloseq(otu_table(MRcounts(cumNorm(mp,p=cumNormStat(mp)),norm=T,log=TRUE), taxa_are_rows=TRUE), taxa_mat, sd,tree)


##### Generating the PCoA plots based on beta-diversity estimates:

ord_norm=ordinate(physeq_norm, "PCoA", "bray")
plot_ordination(physeq_norm, ord_norm, shape='Tissues', color='HostSpecies')+geom_point(size=6)+scale_color_manual(values=c("#de2d26","#fc9272","#3182bd"))
ord_norm1=ordinate(physeq_norm, "PCoA", Unifrac="unifrac")
plot_ordination(physeq_norm, ord_norm1, shape='Tissues', color='HostSpecies')+geom_point(size=6)+scale_color_manual(values=c("#de2d26","#fc9272","#3182bd"))


##### PERMANOVA test for the analysis of variation:

## An example for testing the impact of Tissues, HostSpecies and SoilOrigin and Their Interactions:

metadata <- as(sample_data(physeq2), "data.frame")
adonis(distance(physeq2, method="bray") ~ Tissues*SoilOrigin*HostSpecies,
       data = metadata)


###### Producing the heatmaps of relative abundances with ampvis2 package:


table_amp <- read.delim(“feature_table.txt")
                         tax_amp <- read.delim(“taxonomy.txt”)
                         sd_amp <- read.delim(“sample_metadata.txt")


amp_data=merge(table_amp, tax_amp,by.x="OTU.ID",by.y="Feature.ID")


###### Loading the ampvis object:
d <- amp_load(otutable =amp_ data, metadata = sd_amp)


##### Generating the heatmap aggreated at Family level:

amp_heatmap(
  data = d,
  group_by = "HostSpecies",
  facet_by = "Tissues",
  tax_show = 20,
  tax_aggregate = "Family",
  tax_add = "Phylum",tax_empty="remove",
  plot_values = TRUE,
  plot_colorscale = "sqrt",
  color_vector = c("royalblue3",
                   "whitesmoke",
                   "red3")
)

##### Plots are further edited and merged together.
