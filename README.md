# nf-metaomics-daisychain

> [!IMPORTANT]
> This is work-in-progress and not yet ready for use.
> A major issue at the moment is the wrapper process does not resume.
> Until a solution for this is found, this project is on hold.

A Nextflow meta-pipeline for meta-omic data.

![](docs/images/nf-metaomics-daisychain.png)

> Metro map by [James Fellows Yates](https://github.com/jfy133).

> Meta pipeline based on the concept of [nf-cascade](https://github.com/mahesh-panchal/nf-cascade)

> [!TIP]
> Use `nf-core pipelines launch <pipeline>` to write the pipeline `params.yml` which can
> supplied as a workflow parameter : `<workflow>.params_file`.

## Usage

Parameters are supplied to child workflows through `params.yml` files. These
files can be generated with `nf-core pipelines launch <pipeline>` and supplied to the workflow.

```bash
nextflow run main.nf -params-file params.yml
```

> [!NOTE]
> Parameter files can be supplied for each workflow though the `<workflow>.params_file` config.
> `<workflow>.input` can be set to supply a samplesheet, or override the samplesheet provided by
> a previous workflow (`<workflow>.input` and previous workflow stages take precedence over
> samplesheets provided through `<workflow>.params_file`).

> [!WARNING]
> Please use absolute paths for all input files.
