# DATA WRANGLING FOR 2_CHNG

# START
cat(paste0('\nStage `wrangle` started at [', Sys.time(), ']\n'))

# FUNCTIONS
library(ape)
source(file.path('tools', "wrngl_tools.R"))

# DIRS
output_dir <- "1_wrngl"
if(!file.exists(output_dir)) {
  dir.create(output_dir)
}
tree_dir <- file.path('0_data', "trees")
chars_dir <- file.path('0_data', "chars")

# MAMMALS
cat('Working on mammals ....\n')
data <- read.delim(file.path(chars_dir, "panTHERIA.txt"), na.strings = -999,
                    stringsAsFactors = FALSE)
pantheria <- data[ ,- c(1:5,36:55)]
for(i in 1:ncol(pantheria)) {
  temp.chars <- pantheria[!is.na(pantheria[ , i]),i]
  if(length(unique(temp.chars)) > 10) {
    pantheria[!is.na(pantheria[ , i]),i] <- cut(temp.chars, 10)
  }
}
rownames(pantheria) <- data[ ,"MSW93_Binomial"]
rownames(pantheria) <- sub(" ", "_", rownames(pantheria))
file <- "morpho_matrix_forR.nex"
oleary <- readNexusData(file.path(chars_dir, file))
chars <- merge(oleary, pantheria, by = 0, all = TRUE)
rownames(chars) <- c(rownames(oleary) [!rownames(oleary) %in% rownames(pantheria)], rownames(pantheria))
tree <- read.tree(file.path(tree_dir, "bininda_mammalia.tre"))
chars <- chars[rownames(chars) %in% tree$tip.label, ]
clades_phylo <- MoreTreeTools::getClades(tree)
data <- list(tree=tree, chars=chars, clades_phylo=clades_phylo)
save(data, file=file.path(output_dir, "mammal.RData"))
prep <- signif(mean(colSums(!is.na(chars)))/length(tree$tip.label), 3)
cat('Done. Found [', ncol(chars), '] characters each on average representing [', 
    prep, '%] of all tips\n', sep="")

# BIRDS
cat('Working on birds ....\n')
file <- "X1228_Morphology Matrix_morphobank.nex"
livezy <- readNexusData(file.path(chars_dir, file))
file <- "avian_ssd_jan07.txt"
lislevand <- read.delim(file.path(chars_dir, file),
                        stringsAsFactors=FALSE)
pull <- !names(lislevand) %in% c("Family", "Species_number", "Species_name",
                                 "English_name", "Subspecies", "References",
                                 "X", "X.1", "X.2", "Resource")
lislevand[lislevand == -999] <- NA  # remove missing values
lislevand <- lislevand[lislevand[,'Species_name'] != "", ]
dups <- lislevand[, 'Species_name'][duplicated(lislevand[, 'Species_name'])]
for(dup in dups) {
  i <- which(lislevand[, 'Species_name'] == dup)
  meaned <- colMeans(lislevand[i, pull], na.rm=TRUE)
  lislevand[i[1], pull] <- meaned
  lislevand <- lislevand[-i[-1], ]
}
rownames(lislevand) <- lislevand[, 'Species_name']
genus_nms <- sub("\\s+.*", "", lislevand[, 'Species_name'])
lislevand <- lislevand[, pull]
livezy <- livezy[rownames(livezy) %in% genus_nms, ]
mtchd <- match(genus_nms, rownames(livezy))
chars <- cbind(lislevand, livezy[mtchd, ])
trees <- read.tree(file.path(tree_dir, 'jetz_aves.tre'))
tree <- consensus(trees)  # strict consensus tree
rownames(chars) <- gsub(" ", "_", rownames(chars))
chars <- chars[rownames(chars) %in% tree$tip.label,]
mssng <- tree$tip.label[!tree$tip.label %in% rownames(chars)]
mssng_dt <- matrix(NA, ncol=ncol(chars), nrow=length(mssng))
rownames(mssng_dt) <- mssng
colnames(mssng_dt) <- colnames(chars)
chars <- rbind(chars, mssng_dt)  # ensure no tip is missing from chars
tree$edge.length <- rep(1, nrow(tree$edge))
clades_phylo <- MoreTreeTools::getClades(tree)
data <- list(tree=tree, chars=chars, clades_phylo=clades_phylo)
save(data, file = file.path(output_dir, "bird.RData"))
prep <- signif(mean(colSums(!is.na(chars)))/length(tree$tip.label), 3)
cat('Done. Found [', ncol(chars), '] characters each on average representing [', 
    prep, '%] of all tips\n', sep="")

# END
cat(paste0('\nStage `wrangle` finished at [', Sys.time(), ']\n'))