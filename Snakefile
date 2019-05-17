import pandas as pd
import os
import numpy as np

configfile: "wbuild.yaml" #"../genetic_diagnosis_modified/wbuild.yaml"

subworkflow standardFileNames:
    workdir:
        "../sample_annotation"
    snakefile:
        "../sample_annotation/Snakefile"
    configfile:
        "../sample_annotation/wbuild.yaml"


# set config variables
#mae
vcfs, rnas = mae_files()
config["vcfs"] = vcfs
config["rnas"] = rnas
config["mae_ids"] = list(map('-'.join, zip(vcfs, rnas)))

#outrider
outrider_all_ids, outrider_filtered = outrider_files()
config["outrider"] = outrider_all_ids
config["outrider_filtered"] = outrider_filtered

include: ".wBuild/wBuild.snakefile"  # Has to be here in order to update the config with the new variables
#htmlOutputPath = config["htmlOutputPath"]  if (config["htmlOutputPath"] != None) else "Output/html"
htmlOutputPath = "Output/html"


rule all:
    input: rules.Index.output, htmlOutputPath + "/readme.html"
    output: touch("Output/all.done")

