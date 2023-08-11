# Chromosome level mutation rate estimation with delphinids
# Sophie Garrote and Amy Van Cise
# 11 Aug 2023

# Short-finned pilot whale, Risso's dolphin and Indo-Pacific humpback dolphin aligned
# to a killer whale genome

# mutation rate calculation script derived from Robinson et al. 2022

# Counting/processing of chromosome-level SNPs done in bash

################################################################################

library(tidyverse)

setwd("C:/Users/Intern/Downloads")

#accessing processed files containing SNPs partioned by chromosome
data_files <- list.files("chrom_snps", pattern = ".txt")

data <- list()

# altering data frame to create correct column titles + chromosome numbers
for (f in 1:length(data_files)){
data[[f]] <- read.delim(paste0("chrom_snps/",data_files[f]), sep = " ", header = FALSE) %>% 
  dplyr::rename("length" = 1, "hets" = 2, "hom" = 3, "aallele" = 4) %>% 
  mutate(chrom_number = row_number()) %>% 
  mutate(chrom_number = as.character(chrom_number)) %>% 
  mutate(chrom_number = case_when(chrom_number == 22 ~ "X", TRUE ~ chrom_number))
}

species <- c("Gg", "Gm", "Sc") #species abbrev. in the order of the files
G<-c(19.6, 23.5, 20.4) #generation times in the same order
Split = 9.7e6 #split time from killer whale

#data frame for chromosome mutation rates
species_chrom_mutation_data <- data.frame()

# loop that iterates through each species
for (k in 1:length(species)) {
  G_sp=G[k]
  tempdata <- data[[k]]
  chrom_mutation_data <- data.frame()
  
  # loop that iterates through mutation rate calculation w/ info from each row
  for (i in 1:nrow(tempdata)) {
    AALLELE=tempdata$aallele[i]
    TOTAL=tempdata$length[i] - AALLELE
    HET=tempdata$hets[i]
    HOMALT=tempdata$hom[i]
    HOMREF=TOTAL-(HOMALT+HET)
    
    # Heterozygosity
    PI=HET/TOTAL
    
    # Divergence (number of alt alleles in hets and hom. alt divided by the total number of 
    # alleles)
    DIV=(HET+(2*HOMALT))/(2*TOTAL)
    
    #Time to coalesence
    T=Split/G_sp
    
    #noPi mutation rate
    noPI_mutation <- DIV/(2*T)
    
    #Pi mutation rate
    PI_mutation <- (DIV-PI)/(2*T)
    
    temp_chrom_data <- data.frame(species = rep(species[k],2), chrom = rep(tempdata$chrom_number[i],2), method = c("noPI","PI"), rate = c(noPI_mutation, PI_mutation))
                                  
    chrom_mutation_data <- rbind(chrom_mutation_data, temp_chrom_data)
  }
#appending data from species and row iterations to overall data frame
species_chrom_mutation_data <- rbind(species_chrom_mutation_data, chrom_mutation_data)    
}

################################################################################

#changing character vector to factor to correct graph chrom order
species_chrom_mutation_data$chrom <- factor(species_chrom_mutation_data$chrom, 
                                            levels=c("1","2","3","4","5","6","7","8","9","10","11",
                                                     "12","13","14","15","16","17","18","19","20","21","X"))
## graph time!
library(ggplot2)
library(PNWColors)

# data frame for previous estimations of mutation rate
est_mr <- data.frame(yint=1.08e-8)

ggplot(data=species_chrom_mutation_data, aes(x=chrom,y=rate,shape=method,color=species)) +
  geom_point(size=3.5) +
  theme_light() +
  labs(x="Chromosome", y="Mutations/site/generation", 
       title="Chromosome-Level Mutation Rate") +
  scale_shape_discrete(labels=c('w/o ancestral\nheterozygosity', 'w/ ancestral\nheterozygosity'), name="Method") +
  scale_color_manual(values=pnw_palette(n=3,name="Sunset2"), 
                     labels=c("Risso's dolphin","Short-finned\npilot whale","Indo-Pacific\nhumpback dolphin"),
                     name="Species") +
  theme(axis.title.y = element_text(margin = margin(t=0,r=8,b=0,l=5)),
        axis.title.x = element_text(margin = margin(t=8,r=0,b=5,l=0))) +
  theme(text = element_text(size = 20)) +
  geom_hline(data=est_mr, mapping=aes(yintercept=yint, linetype="A")) +
  scale_linetype_discrete(labels=c('Odontocete nuclear\nmutation rate\n(Dornburg et al. 2012)'), 
                          name="Estimates")

# OPTIONAL:what is the range in mutation rate for species vs. chromosomes?
  species_chrom_mutation_data %>% 
    group_by(species) %>% 
    summarise(minmax = range(rate)) %>% 
    group_by(species) %>% 
    summarise(range = max(minmax)-min(minmax))
  
  species_chrom_mutation_data %>% 
    group_by(chrom) %>% 
    summarise(minmax = range(rate)) %>% 
    group_by(chrom) %>% 
    summarise(range = max(minmax)-min(minmax))
  
  