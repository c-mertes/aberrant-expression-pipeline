#'---
#' title: Preprocess Gene Annotations
#' author: mumichae
#' wb:
#'  params:
#'   - tmpdir: '`sm drop.getMethodPath(METHOD, "tmp_dir")`'
#'  input:
#'   - gtf: '`sm lambda wildcards: parser.getGeneAnnotationFile(wildcards.annotation) `'
#'  output:
#'   - txdb: '`sm parser.getProcDataDir() + "/aberrant_expression/{annotation}/txdb.db"`'
#'   - count_ranges: '`sm parser.getProcDataDir() + 
#'                    "/aberrant_expression/{annotation}/count_ranges.Rds" `'
#'   - gene_name_mapping: '`sm parser.getProcDataDir() + "/aberrant_expression/{annotation}/gene_name_mapping_{annotation}.tsv"`'
#'  type: script
#'---

saveRDS(snakemake, file.path(snakemake@params$tmpdir, "annotation.snakemake") )
# snakemake <- readRDS(".drop/tmp/AE/annotation.snakemake")

suppressPackageStartupMessages({
  library(GenomicFeatures)
  library(data.table)
  library(rtracklayer)
  library(magrittr)
})

## Create txdb
txdb <- makeTxDbFromGFF(snakemake@input$gtf)
txdb <- keepStandardChromosomes(txdb)

tmpFile <- tempfile()
saveDb(txdb, tmpFile)
R.utils::copyFile(tmpFile, snakemake@output$txdb, overwrite=TRUE)

# save count ranges
count_ranges <- exonsBy(txdb, by = "gene")
saveRDS(count_ranges, snakemake@output$count_ranges)

# Get a gene annotation table
gtf_dt <- import(snakemake@input$gtf) %>% as.data.table
if (!"gene_name" %in% colnames(gtf_dt)) {
  gtf_dt[gene_name := gene_id]
}
gtf_dt <- gtf_dt[type == 'gene']

# Subset to the following columns only
columns <- c('seqnames', 'start', 'end', 'strand', 'gene_id', 'gene_name', 'gene_type', 'gene_status')
columns <- intersect(columns, colnames(gtf_dt))
gtf_dt <- gtf_dt[, columns, with = F]

# make gene_names unique
gtf_dt[, N := 1:.N, by = gene_name] # warning message
gtf_dt[, gene_name_orig := gene_name]
gtf_dt[N > 1, gene_name := paste(gene_name, N, sep = '_')]
gtf_dt[, N := NULL]

fwrite(gtf_dt, snakemake@output$gene_name_mapping, na = NA)
