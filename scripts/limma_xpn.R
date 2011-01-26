#!/usr/bin/Rscript

library(beadarray)

# because I can't be bothered to type all the quotes
qw <- function(...) {
  as.character(sys.call()[-1])
}

options(stringsAsFactors = FALSE);
options(scipen=10)

args <- commandArgs(trailingOnly=TRUE)
filename = args[1]
outfile = args[2]

filename <- "Pas_aSVZ_DN-REST_illumina_sept10_Sample_Probe_Profile.txt"
outfile <- "limma_results.csv"

BSData<-readBeadSummaryData(filename,
                            sep="\t",
                            skip=7,
                            ProbeID="ProbeID",
                            columns=list(
                              exprs="AVG_Signal",
                              se.exprs="BEAD_STDEV",
                              NoBeads="Avg_NBEADS",
                              Detection="Detection"
		   )
)	

E = normaliseIllumina(BSData, method="quantile", transform="log2")
data <- exprs(E)

library(limma)

cols <- c(rep('ev',4), rep('dn',4))
ev <- 1:4
dn <- 5:8

design<-matrix(0,nrow=(ncol(data)), ncol=2)
colnames(design)<-c("ev","dn")
design[ev,"ev"]<-1
design[dn,"dn"]<-1


fit<-lmFit(data, design)
cont.matrix<-makeContrasts(nsvsastro=dn-ev, levels=design)
fit<-contrasts.fit(fit, cont.matrix)
ebFit<-eBayes(fit)

write.fit(ebFit, file=outfile , adjust="BH")
data<-read.table(outfile, sep="\t", header=T)

data<- topTable(ebFit, number=nrow(data))
write.csv(data,outfile)
















