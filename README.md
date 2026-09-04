# nf-metaomics-daisychain

> [!IMPORTANT]
> This is work-in-progress and not yet ready for use.

A Nextflow meta-pipeline for meta-omic data.

![](docs/images/nf-metaomics-daisychain.png)

> Metro map by [James Fellows Yates](https://github.com/jfy133).

> Meta pipeline based on the concept of [nf-cascade](https://github.com/mahesh-panchal/nf-cascade)

> [!TIP]
> Use `nf-core pipelines launch <pipeline>` to write the pipeline `params.yml` which can
> supplied as a workflow parameter : `<workflow>.params_file`.

## Usage

Choose which pipelines to run with the per-pipeline `enable_<pipeline>` boolean params,
e.g. `enable_fetchngs: true` / `enable_taxprofiler: true`. Each selected pipeline gets
its own `<workflow>.{input, params_file, wf_opts, add_config}` block, and a
`general.wf_opts` applies to every pipeline in the chain. See `meta-pipeline-params.yml`
for a worked example.

Parameters for each child pipeline are supplied through `params.yml` files. These
files can be generated with `nf-core pipelines launch <pipeline>` and supplied via
`<workflow>.params_file`.

```bash
nextflow run main.nf -params-file meta-pipeline-params.yml
```

> [!NOTE]
> Parameter files can be supplied for each workflow though the `<workflow>.params_file` config.
> `<workflow>.input` can be set to supply a samplesheet, or override the samplesheet provided by
> a previous workflow (`<workflow>.input` and previous workflow stages take precedence over
> samplesheets provided through `<workflow>.params_file`).

> [!NOTE]
> `nextflow_schema.json` runs preliminary checks before any pipeline starts: enabling a
> pipeline that has no auto-wired upstream in this chain (or whose upstream is itself
> disabled) requires that pipeline's own `.input`, `.params_file`, or a `-profile ...test...`
> in `.wf_opts` to be set, otherwise validation fails fast with a clear error instead of
> the pipeline failing deep into a run. A pipeline's own `-profile test` already bundles
> a complete, self-consistent example input (including things this repo can't derive for
> you, like a differentialabundance contrasts file or a phyloplace reference tree) - a
> quick way to try a pipeline you haven't wired up your own data for yet.

> [!WARNING]
> Please use absolute paths for all input files.

## Technical details

This meta-pipeline runs each child pipeline as `nextflow run nf-core/<pipeline>` in a
native `NEXTFLOW_RUN` process, and connects stages together by generating a samplesheet
from a previous stage's output directory (see `functions/local/utils.nf`). This is the
same approach demonstrated in [nf-cascade](https://github.com/mahesh-panchal/nf-cascade) -
see that repo's README and wiki for the technical background and a guided example of
adding a new pipeline to the chain.
