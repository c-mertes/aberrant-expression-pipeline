### SNAKEFILE ABERRANT EXPRESSION
import os
import drop
import pathlib

parser = drop.config(config)
config = parser.config # needed if you dont provide the wbuild.yaml as configfile
include: config['wBuildPath'] + "/wBuild.snakefile"

tmpdir = os.path.join(config["ROOT"], 'tmp')
config["tmpdir"] = tmpdir
if not os.path.exists(tmpdir+'/AberrantExpression'):
    os.makedirs(tmpdir+'/AberrantExpression')
# remove dummy files if they exist
done = tmpdir + "/AE.done"
if os.path.exists(done):
    os.remove(done)

AE_ROOT = pathlib.Path(drop.__file__).parent / "modules/aberrant-expression-pipeline"

# get group subsets
config['outrider_all'] = parser.outrider_all
config['outrider_filtered'] = parser.outrider_filtered

rule all:
    input: 
        rules.Index.output, config["htmlOutputPath"] + "/aberrant_expression_readme.html",
        expand(
            config["htmlOutputPath"] + "/AberrantExpression/Counting/{annotation}/Summary_{dataset}.html",
            annotation=list(config["GENE_ANNOTATION"].keys()),
            dataset=parser.outrider_filtered
        ),
        expand(
            parser.getProcResultsDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/OUTRIDER_results.tsv",
            annotation=list(config["GENE_ANNOTATION"].keys()),
            dataset=parser.outrider_filtered
        )
    output: touch(done)

rule read_count_qc:
    input:
        bam_files = lambda wildcards: parser.getFilePaths(group=wildcards.dataset, ids_by_group=config["outrider_all"], file_type='RNA_BAM_FILE'),
        ucsc2ncbi = AE_ROOT / "resource/chr_UCSC_NCBI.txt",
        script = AE_ROOT / "Scripts/Counting/bamfile_coverage.sh"
    output:
        qc = parser.getProcDataDir() + "/aberrant_expression/{annotation}/outrider/{dataset}/bam_coverage.tsv"
    params:
        sample_ids = lambda wildcards: parser.outrider_all[wildcards.dataset]
    shell:
        "{input.script} {input.ucsc2ncbi} {output.qc} {params.sample_ids} {input.bam_files}"


### RULEGRAPH  
### rulegraph only works without print statements

## For rule rulegraph.. copy configfile in tmp file
import oyaml
with open(tmpdir + '/config.yaml', 'w') as yaml_file:
    oyaml.dump(config, yaml_file, default_flow_style=False)

rulegraph_filename = htmlOutputPath + "/AE_rulegraph" # htmlOutputPath + "/" + os.path.basename(os.getcwd()) + "_rulegraph"
rule produce_rulegraph:
    input:
        expand(rulegraph_filename + ".{fmt}", fmt=["svg", "png"])

rule create_graph:
    output:
        rulegraph_filename + ".dot"
    shell:
        "snakemake --configfile " + tmpdir + "/config.yaml --rulegraph > {output}"

rule render_dot:
    input:
        "{prefix}.dot"
    output:
        "{prefix}.{fmt,(png|svg)}"
    shell:
        "dot -T{wildcards.fmt} < {input} > {output}"

