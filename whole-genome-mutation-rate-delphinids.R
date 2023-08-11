# Divergence and mutation rate estimation for delphinid species
# Sophie Garrote and Amy Van Cise
# 11 Aug 2023

# Short-finned pilot whale (Globicephala macrorhynchus), Risso's dolphin (Grampus griseus) and Indo-Pacific 
# humpack dolphin (Sousa chinensis) aligned to a killer whale (Orcinus orca) reference genome

# mutation rate calculation script derived from Robinson et al. 2022

################################################################################
# Genotype stats

# Short finned pilot whale
AALLELE1=146848
TOTAL1=2647351467 - AALLELE1
HET1=3088362
HOMALT1=27110569
HOMREF1=TOTAL1-(HOMALT1+HET1)

# Heterozygosity
PI1=HET1/TOTAL1
# 0.00116665027623239

# Divergence (number of alt alleles in hets and hom. alt divided by the total number of 
# alleles)
DIV1=(HET1+(2*HOMALT1))/(2*TOTAL1)
# 0.0108245315811003


# Indo-Pacific humpback dolphin
AALLELE2=79635
TOTAL2=2647351467 - AALLELE2
HET2=973442
HOMALT2=27617460
HOMREF2=TOTAL2-(HOMALT2+HET2)

# Heterozygosity
PI2=HET2/TOTAL2
# 0.000367715165565211

# Divergence (number of alt alleles divided by the total number of alleles)
DIV2=(HET2+(2*HOMALT2))/(2*TOTAL2)
# 0.0106162807537477


# Risso's dolphin
AALLELE3=187456
TOTAL3=2647351467 - AALLELE3
HET3=4744874
HOMALT3=26396048
HOMREF3=TOTAL3-(HOMALT3+HET3)

# Heterozygosity
PI3=HET3/TOTAL3
# 0.00179243672862097

# Divergence (number of alt alleles divided by the total number of alleles)
DIV3=(HET3+(2*HOMALT3))/(2*TOTAL3)
# 0.0108676624797163

################################################################################
# Mutation rate estimation

#variables to run through for-loop in order of species (calculated above)
species <- c("Gm", "Sc", "Gg")
G<-c(23.5,20.4,19.6) #generation time
PI<-c(0.00116665027623239,0.000367715165565211,0.00179243672862097)
DIV<-c(0.0108245315811003,0.0106162807537477,0.0108676624797163)

divergence_data <- data.frame()

for (i in 1:length(species)){

# TimeTree.org split times
Split=9.7e6

T=Split/G[i]

# Assuming u=DIV/2T
# Here, we ignore the time to coalescence in the ancestral population, which is okay when 
# 2Tu >> pi

# first method mutation rate calculation w/out ancestral heterozygosity
noPI_div <- DIV[i]/(2*T)

# Assuming u=(DIV-PI)/2T
# Here, we incorporate time to coalescence in the ancestral population, and we assume 
# that current pi = ancestral pi

# second method mutation rate calculation w/ ancestral heterozygosity
PI_div <- (DIV[i]-PI[i])/(2*T)

#temporary data frame w/ iteration data
temp_data <- data.frame(species = species[i], method = c("noPI","PI"), rate = c(noPI_div, PI_div))

#appending iteration data to final data frame
divergence_data <- rbind(divergence_data,temp_data)

}

################################################################################
# Plot mutation rates

library(ggplot2)
library(PNWColors) #color palette library

# data frame for previous estimations of mutation rate
est2 <- data.frame(yint=1.08e-8)

#plot
ggplot(data=divergence_data, aes(x=species,y=rate,shape=method,color=species)) +
  geom_point(size=3.5) +
  labs(x="Species", y="Mutations/site/generation",
       title="Whole Genome Mutation Rate") +
  theme_light() +
  theme(text = element_text(size = 20)) +
  guides(color=FALSE) +
  theme(plot.margin = unit(c(10,30,0,0), 'pt'), axis.title.y = element_text(margin = margin(t=0,r=12,b=0,l=5)),
        axis.title.x = element_text(margin = margin(t=12,r=0,b=5,l=0))) +
  scale_shape_discrete(labels=c('w/o ancestral\nheterozygosity', 'w/ ancestral\nheterozygosity'), name="Method") +
  scale_color_manual(values=pnw_palette(n=3,name="Sunset2")) +
  scale_x_discrete(labels=c('Rissos\ndolphin','Short-finned\npilot whale','Indo-Pacific\nhumpback dolphin')) +
  geom_hline(data=est2, mapping=aes(yintercept=yint, linetype="B")) +
  scale_linetype_discrete(labels=c('Odontocete nuclear\nmutation rate\n(Dornburg et al. 2012)'), 
                          name="Estimates")


