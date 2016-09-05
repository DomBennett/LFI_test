# CALCULATE EPIS FROM NODE_OBJ
# TODO: add ranks


# START
cat(paste0('\nStage `epi` started at [', Sys.time(), ']\n'))

# PARAMETERS
cat("Loading parameters ...\n")
source('parameters.R')

# LIBS
cat("Loading libraries ...\n")
library(ggplot2)
source(file.path("tools", "epi_tools.R"))
source(file.path('tools', 'node_obj_tools.R'))

# DIRS
input_dir <- "8_cntrst_chng"
output_dir <- '9_epi'
if (!file.exists(output_dir)) {
  dir.create(output_dir)
}
output_file <- file.path(output_dir, "res.RData")
input_file <- file.path(input_dir, "res.RData")

# INPUT
load(input_file)

# GET SSTR CANDIDATES
# ensure sisters are accounted for in order to test autocorrelation
cnddts <- cnddts[!duplicated(cnddts)]
cnddts <- unique(unlist(sapply(cnddts,
                               function(x) c(x, node_obj[[x]][['sstr']]))))

# GENERATE EPI DATAFRAME
cat("Generating EPI dataframe.... ")
nms <- tmsplts <- cntrst_ns <- cntrst_chngs <- chngs <- eds <- ns <- rep(NA, length(cnddts))
for(i in 1:length(cnddts)) {
  tmsplt <- node_obj[[cnddts[i]]][["tmsplt"]]
  # if no tmsplt, use sstrs
  if(is.null(tmsplt)) {
    sstrs <- node_obj[[cnddts[i]]][['sstr']]
    if(length(sstrs) > 0) {
      sstr_tmsplts <- sapply(sstrs, function(x) {
        res <- NA
        if(!is.null(node_obj[[x]][['tmsplt']])) {
          res <- node_obj[[x]][['tmsplt']]
        }
        res})
      tmsplt <- mean(sstr_tmsplts, na.rm=TRUE)
    }
  }
  cntrst_n <- node_obj[[cnddts[i]]][["cntrst_n"]]
  if(!is.null(tmsplt) & !is.null(cntrst_n)) {
    tmsplts[i] <- tmsplt
    cntrst_ns[i] <- cntrst_n
    ns[i] <- length(node_obj[[cnddts[i]]][['kids']])
    nms[i] <- node_obj[[cnddts[i]]][["nm"]][["scientific name"]]
  }
  if(!is.null(node_obj[[cnddts[i]]][['ed']])) {
    eds[i] <- node_obj[[cnddts[i]]][['ed']]
  }
  if(!is.null(node_obj[[cnddts[i]]][["cntrst_chng"]])) {
    cntrst_chngs[i] <- node_obj[[cnddts[i]]][["cntrst_chng"]]
    chngs[i] <- node_obj[[cnddts[i]]][["chng"]]
  }
}
bool <- !is.na(cntrst_ns)
cntrst_ns <- cntrst_ns[bool]
tmsplts <- tmsplts[bool]
cnddts <- cnddts[bool]
nms <- nms[bool]
cntrst_chngs <- cntrst_chngs[bool]
chngs <- chngs[bool]
eds <- eds[bool]
ns <- ns[bool]
epi <- data.frame(nm=nms, txid=cnddts, tmsplt=tmsplts, cntrst_n=cntrst_ns,
                  chng=chngs, ed=eds, cntrst_chng=cntrst_chngs, n=ns,
                  stringsAsFactors=FALSE)
cat("Done.\n")

# CLEAN-UP
# some data points don't make sense, reasons as yet unknown
epi <- epi[epi[['cntrst_n']] != Inf, ]  # two instances of this

# CALCULATE EPIS
cat("Calculating EPIs .... ")
epi$epi <- log((epi[['cntrst_chng']] + epi[['cntrst_n']]) / epi[['tmsplt']])
epi$pepi <- log(epi[['cntrst_n']] / epi[['tmsplt']])
cat("Done.\n")

# PLOTS
plotEPI(epi, n=25)

pdf(file.path(output_dir, "res.pdf"))
ggplot(data=epi, aes(x=log(tmsplt), y=log(cntrst_n), colour=pepi)) +
  geom_point() + theme_bw()
ggplot(data=epi, aes(x=pepi, y=log(ed))) +
  geom_point() + theme_bw()
ggplot(data=epi, aes(x=pepi, y=chng)) +
  geom_point() + theme_bw()
dev.off()

# ADDING TAXONOMIC INFO
txids <- ls(node_obj)
epi$txnmcgrp <- NA
mmls <- getGrpTxids(txids, "mammals")
epi$txnmcgrp[epi$txid %in% mmls] <- 'mammal'
brds <- getGrpTxids(txids, "birds")
epi$txnmcgrp[epi$txid %in% brds] <- 'bird'
lpdsrs <- getGrpTxids(txids, "lepidosaurs")
epi$txnmcgrp[epi$txid %in% lpdsrs] <- 'lepidosaur'

# OUTPUT
cat("Outputting ... ")
top50 <- epi[order(epi[['pepi']])[1:50], ]
write.csv(top50, file.path(output_dir, "top50.csv"), row.names=FALSE)
save(node_obj, epi, file=output_file)
cat('Done.\n')

# END
cat(paste0('\nStage `epi` finished at [', Sys.time(), ']\n'))