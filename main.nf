include { NEXTFLOW_RUN as NFCORE_FETCHNGS              } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_DETAXIZER             } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_CREATETAXDB           } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_AMPLISEQ              } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_TAXPROFILER           } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_EAGER                 } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_MAGMAP                } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_MAG                   } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_METATDENOVO           } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_DIFFERENTIALABUNDANCE } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_METAPEP               } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_PHAGEANNOTATOR        } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_FUNCSCAN              } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_PHYLOPLACE            } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_HLATYPING             } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_COPROID                } from "./modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_PROTEINFAMILIES        } from "./modules/local/nextflow/run/main"
include { readWithDefault                              } from "./functions/local/utils"
include { resolveFileFromDir as getSamplesheet         } from "./functions/local/utils"
include { createMagSamplesheet                         } from "./functions/local/utils"
include { createFuncscanSamplesheet                    } from "./functions/local/utils"
include { createAmpliseqSamplesheet                    } from "./functions/local/utils"
include { createMetatdenovoSamplesheet                 } from "./functions/local/utils"
include { createMagmapGenomeInfo                       } from "./functions/local/utils"
include { createDetaxizerSamplesheet                   } from "./functions/local/utils"
include { createMetatdenovoSamplesheetFromDetaxizer    } from "./functions/local/utils"
include { createEagerSamplesheet                       } from "./functions/local/utils"
include { createEagerSamplesheetFromDetaxizer          } from "./functions/local/utils"
include { createMetapepSamplesheet                     } from "./functions/local/utils"
include { createDifferentialabundanceMatrix            } from "./functions/local/utils"
include { createHlatypingSamplesheet                   } from "./functions/local/utils"
include { createHlatypingSamplesheetFromDetaxizer      } from "./functions/local/utils"
include { createCoproidSamplesheet                     } from "./functions/local/utils"
include { createCoproidSamplesheetFromDetaxizer        } from "./functions/local/utils"
include { validateParameters                           } from "plugin/nf-schema"

workflow {
    // Which pipelines to run is controlled by the enable_<pipeline> params (see
    // nextflow.config). Whether a pipeline that's enabled but has no viable input
    // source (neither an auto-wired upstream nor its own `.input`/`.params_file`) is
    // caught here, before any process runs - see the `allOf` rules in
    // nextflow_schema.json, not a hand-rolled check here.
    validateParameters()

    // Channels used to connect stages together, so downstream stages can default to
    // an upstream stage's output.
    // - Vars later used as a channel input in their own right (`.map`'d, or passed as
    //   a `readWithDefault` default) start as a real empty channel: `Channel.value([])`.
    // - Vars only ever passed into a createXSamplesheet(dir)-style helper (which does
    //   its own `if (dir) {...} else {...}` truthy check) start as a bare `[]` - a
    //   plain falsy object, not a channel - matching what those helpers' own `else`
    //   branch already returns.
    // Neither ever needs `?: Channel.value([])` later: each is always already the
    // right shape for how it's used downstream.
    def fetchngs_output_samplesheet = Channel.value([])
    def fetchngs_output              = []
    def detaxizer_output             = []
    def mag_output                   = []
    def metatdenovo_output           = []
    def magmap_output                = []
    def hlatyping_output             = []
    def createtaxdb_databases        = Channel.value([])

    // Run pipelines
    if (params.enable_fetchngs) {
        NFCORE_FETCHNGS (
            'nf-core/fetchngs',
            "${params.general.wf_opts ?: ''} ${params.fetchngs.wf_opts ?: ''}",     // workflow opts
            readWithDefault( params.fetchngs.params_file, Channel.value([]) ),      // params file
            readWithDefault( params.fetchngs.input, Channel.value([]) ),            // samplesheet
            readWithDefault( params.fetchngs.add_config, Channel.value([]) ),       // custom config
            workflow.workDir.resolve('nf-core/fetchngs').toUriString(),
        )
        fetchngs_output_samplesheet = getSamplesheet( 'samplesheet/samplesheet.csv', NFCORE_FETCHNGS.out.output )
        fetchngs_output             = NFCORE_FETCHNGS.out.output
    }
    if (params.enable_detaxizer) {
        // FETCHNGS -> DETAXIZER. Amplicon reads bypass detaxizer entirely per the
        // metro map (only the shotgun branch needs decontamination), so this only
        // ever defaults from fetchngs, never feeds ampliseq.
        // Always ask detaxizer to generate its own downstream_samplesheets/{taxprofiler,
        // mag-se,mag-pe}.csv (same "best effort" pattern as createtaxdb) - an explicit
        // override in detaxizer.wf_opts always wins, same precedence as elsewhere.
        NFCORE_DETAXIZER (
            'nf-core/detaxizer',
            "${params.general.wf_opts ?: ''} --generate_downstream_samplesheets true --generate_pipeline_samplesheets taxprofiler,mag ${params.detaxizer.wf_opts ?: ''}",
            readWithDefault( params.detaxizer.params_file, Channel.value([]) ),
            readWithDefault( params.detaxizer.input, createDetaxizerSamplesheet(fetchngs_output) ),
            readWithDefault( params.detaxizer.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/detaxizer').toUriString(),
        )
        detaxizer_output = NFCORE_DETAXIZER.out.output
    }
    if (params.enable_createtaxdb) {
        NFCORE_CREATETAXDB (
            'nf-core/createtaxdb',
            "${params.general.wf_opts ?: ''} ${params.createtaxdb.wf_opts ?: ''}",
            readWithDefault( params.createtaxdb.params_file, Channel.value([]) ),
            readWithDefault( params.createtaxdb.input, Channel.value([]) ),
            readWithDefault( params.createtaxdb.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/createtaxdb').toUriString(),
        )
        // createtaxdb's own docs call this CSV "best effort" - may need manual
        // completion. An explicit --databases in taxprofiler.wf_opts always wins,
        // since it's appended after this and repeated pipeline params let the last
        // value win (verified: unlike -profile, which errors on repetition).
        createtaxdb_databases = getSamplesheet( 'downstream_samplesheets/taxprofiler.csv', NFCORE_CREATETAXDB.out.output )
    }
    if (params.enable_ampliseq) {
        // FETCHNGS -> AMPLISEQ (createAmpliseqSamplesheet reprojects fetchngs' default
        // samplesheet - fetchngs' --nf_core_pipeline auto-formatting doesn't cover ampliseq).
        NFCORE_AMPLISEQ (
            'nf-core/ampliseq',
            "${params.general.wf_opts ?: ''} ${params.ampliseq.wf_opts ?: ''}",
            readWithDefault( params.ampliseq.params_file, Channel.value([]) ),
            readWithDefault( params.ampliseq.input, createAmpliseqSamplesheet(fetchngs_output) ),
            readWithDefault( params.ampliseq.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/ampliseq').toUriString(),
        )
    }
    if (params.enable_taxprofiler) {
        // FETCHNGS -> TAXPROFILER: fetchngs.wf_opts should include
        // `--nf_core_pipeline taxprofiler` so its samplesheet is pre-formatted.
        // DETAXIZER -> TAXPROFILER takes priority when detaxizer ran: its own
        // natively-generated downstream_samplesheets/taxprofiler.csv (decontaminated
        // reads, real metadata carried through from detaxizer's own input).
        // CREATETAXDB -> TAXPROFILER --databases, see comment above.
        def taxprofiler_default_input = fetchngs_output_samplesheet
        if (detaxizer_output) {
            taxprofiler_default_input = getSamplesheet( 'downstream_samplesheets/taxprofiler.csv', detaxizer_output )
        }
        def taxprofiler_databases_flag = createtaxdb_databases.map { db -> db ? "--databases ${db}" : '' }
        NFCORE_TAXPROFILER (
            'nf-core/taxprofiler',
            taxprofiler_databases_flag.map { flag -> "${params.general.wf_opts ?: ''} ${flag} ${params.taxprofiler.wf_opts ?: ''}" },
            readWithDefault( params.taxprofiler.params_file, Channel.value([]) ),
            readWithDefault( params.taxprofiler.input, taxprofiler_default_input ),
            readWithDefault( params.taxprofiler.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/taxprofiler').toUriString(),
        )
    }
    if (params.enable_eager) {
        // FETCHNGS/DETAXIZER -> EAGER, per the metro map (same shared fastq node as
        // mag/metatdenovo). eager's own OUTPUT is an endpoint though - see plan Phase 3:
        // BAM/VCF/consensus are QC/authentication products, not assembly inputs, so
        // nothing downstream defaults from it.
        def eager_default_input = createEagerSamplesheet(fetchngs_output)
        if (detaxizer_output) {
            eager_default_input = createEagerSamplesheetFromDetaxizer(detaxizer_output)
        }
        NFCORE_EAGER (
            'nf-core/eager',
            "${params.general.wf_opts ?: ''} ${params.eager.wf_opts ?: ''}",
            readWithDefault( params.eager.params_file, Channel.value([]) ),
            readWithDefault( params.eager.input, eager_default_input ),
            readWithDefault( params.eager.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/eager').toUriString(),
        )
    }
    if (params.enable_hlatyping) {
        // FETCHNGS/DETAXIZER -> HLATYPING, same shared reads pool as eager/mag. HLA
        // typing is a HOST-genome analysis, not a microbiome one - only meaningful
        // when a host DNA fraction is actually present (e.g. this repo's own ancient
        // dental calculus test data). Its own output feeds METAPEP's alleles column
        // below with real per-sample genotypes instead of a placeholder.
        def hlatyping_default_input = createHlatypingSamplesheet(fetchngs_output)
        if (detaxizer_output) {
            hlatyping_default_input = createHlatypingSamplesheetFromDetaxizer(detaxizer_output)
        }
        NFCORE_HLATYPING (
            'nf-core/hlatyping',
            "${params.general.wf_opts ?: ''} ${params.hlatyping.wf_opts ?: ''}",
            readWithDefault( params.hlatyping.params_file, Channel.value([]) ),
            readWithDefault( params.hlatyping.input, hlatyping_default_input ),
            readWithDefault( params.hlatyping.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/hlatyping').toUriString(),
        )
        hlatyping_output = NFCORE_HLATYPING.out.output
    }
    if (params.enable_coproid) {
        // FETCHNGS/DETAXIZER -> COPROID, same shared reads pool as eager/mag - an
        // ancient-DNA/coprolite-focused sibling to eager. Always needs its own
        // genomesheet (candidate host/source genomes), --kraken2_db, --sp_sources and
        // --sp_labels via coproid.params_file: no upstream stage carries that
        // information, and coproid's own validation catches a missing one.
        def coproid_default_input = createCoproidSamplesheet(fetchngs_output)
        if (detaxizer_output) {
            coproid_default_input = createCoproidSamplesheetFromDetaxizer(detaxizer_output)
        }
        NFCORE_COPROID (
            'nf-core/coproid',
            "${params.general.wf_opts ?: ''} ${params.coproid.wf_opts ?: ''}",
            readWithDefault( params.coproid.params_file, Channel.value([]) ),
            readWithDefault( params.coproid.input, coproid_default_input ),
            readWithDefault( params.coproid.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/coproid').toUriString(),
        )
    }
    if (params.enable_mag) {
        // FETCHNGS -> MAG. DETAXIZER -> MAG takes priority when detaxizer ran: its own
        // natively-generated downstream_samplesheets/mag-se.csv. Only the single-end
        // sheet is used here - detaxizer writes mag-pe.csv separately for paired-end
        // samples, which would need combining in by hand via mag.input if you have both.
        def mag_default_input = createMagSamplesheet(fetchngs_output)
        if (detaxizer_output) {
            mag_default_input = getSamplesheet( 'downstream_samplesheets/mag-se.csv', detaxizer_output )
        }
        // Both of the above are always single-end (verified: mag 5.5.0 errors "Single-end
        // data must be executed with --single_end" otherwise) - only add the flag when
        // we're actually the ones supplying the samplesheet, not when mag.input overrides
        // it with the user's own (possibly paired-end) data.
        def mag_single_end_flag = (!params.mag.input && (fetchngs_output || detaxizer_output)) ? '--single_end' : ''
        NFCORE_MAG (
            'nf-core/mag',
            "${params.general.wf_opts ?: ''} ${mag_single_end_flag} ${params.mag.wf_opts ?: ''}",
            readWithDefault( params.mag.params_file, Channel.value([]) ),
            readWithDefault( params.mag.input, mag_default_input ),
            readWithDefault( params.mag.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/mag').toUriString(),
        )
        mag_output = NFCORE_MAG.out.output
    }
    if (params.enable_magmap) {
        // MAG -> MAGMAP --genomeinfo (from MetaBAT2 bins; genome_gff left blank -
        // magmap auto-annotates). Its own reads samplesheet is still user-supplied:
        // magmap needs its own --input reads alongside --genomeinfo, and there isn't
        // yet a single obvious upstream reads source to default it to here - enforced
        // in nextflow_schema.json (magmap always needs its own input/params_file).
        def magmap_genomeinfo_flag = createMagmapGenomeInfo(mag_output)
            .map { db -> db ? "--genomeinfo ${db}" : '' }
        NFCORE_MAGMAP (
            'nf-core/magmap',
            magmap_genomeinfo_flag.map { flag -> "${params.general.wf_opts ?: ''} ${flag} ${params.magmap.wf_opts ?: ''}" },
            readWithDefault( params.magmap.params_file, Channel.value([]) ),
            readWithDefault( params.magmap.input, Channel.value([]) ),
            readWithDefault( params.magmap.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/magmap').toUriString(),
        )
        magmap_output = NFCORE_MAGMAP.out.output
    }
    if (params.enable_metatdenovo) {
        // FETCHNGS/DETAXIZER -> METATDENOVO (reprojects the upstream samplesheet to
        // metatdenovo's sample,fastq_1,fastq_2 schema; detaxizer has no native
        // downstream-samplesheet support for metatdenovo, so a separate glob-based
        // glue is used for that source). metatdenovo produces one combined co-assembly
        // rather than per-sample contigs, so unlike mag it isn't wired as a funcscan
        // input source here - see createFuncscanSamplesheet's glob parameter if you
        // want to wire that manually.
        def metatdenovo_default_input = createMetatdenovoSamplesheet(fetchngs_output)
        if (detaxizer_output) {
            metatdenovo_default_input = createMetatdenovoSamplesheetFromDetaxizer(detaxizer_output)
        }
        NFCORE_METATDENOVO (
            'nf-core/metatdenovo',
            "${params.general.wf_opts ?: ''} ${params.metatdenovo.wf_opts ?: ''}",
            readWithDefault( params.metatdenovo.params_file, Channel.value([]) ),
            readWithDefault( params.metatdenovo.input, metatdenovo_default_input ),
            readWithDefault( params.metatdenovo.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/metatdenovo').toUriString(),
        )
        metatdenovo_output = NFCORE_METATDENOVO.out.output
    }
    if (params.enable_differentialabundance) {
        // MAGMAP -> DIFFERENTIALABUNDANCE --matrix (magmap's own docs call its counts
        // table "ready for further analysis... by other pipelines such as nf-core/
        // differentialabundance" - a real matrix, not a placeholder). The sample sheet
        // (--input, conditions/batch) and --contrasts are always user-supplied: no
        // upstream stage carries study-design metadata to derive them from.
        def differentialabundance_matrix_flag = createDifferentialabundanceMatrix(magmap_output)
            .map { m -> m ? "--matrix ${m}" : '' }
        NFCORE_DIFFERENTIALABUNDANCE (
            'nf-core/differentialabundance',
            differentialabundance_matrix_flag.map { flag -> "${params.general.wf_opts ?: ''} ${flag} ${params.differentialabundance.wf_opts ?: ''}" },
            readWithDefault( params.differentialabundance.params_file, Channel.value([]) ),
            readWithDefault( params.differentialabundance.input, Channel.value([]) ),
            readWithDefault( params.differentialabundance.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/differentialabundance').toUriString(),
        )
    }
    if (params.enable_metapep) {
        // MAG -> METAPEP (type=assembly, one condition per sample). HLATYPING -> METAPEP
        // fills alleles with real per-sample HLA genotypes when hlatyping ran; otherwise
        // falls back to a placeholder example pair - see createMetapepSamplesheet.
        NFCORE_METAPEP (
            'nf-core/metapep',
            "${params.general.wf_opts ?: ''} ${params.metapep.wf_opts ?: ''}",
            readWithDefault( params.metapep.params_file, Channel.value([]) ),
            readWithDefault( params.metapep.input, createMetapepSamplesheet(mag_output, hlatyping_output) ),
            readWithDefault( params.metapep.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/metapep').toUriString(),
        )
    }
    if (params.enable_phageannotator) {
        // Deferred - see plan Phase 3: no stable nf-core release yet, and it takes raw
        // reads (sample,fastq_1,fastq_2), so it would run parallel to mag/metatdenovo,
        // not downstream of them. Runs standalone until wiring is revisited.
        NFCORE_PHAGEANNOTATOR (
            'nf-core/phageannotator',
            "${params.general.wf_opts ?: ''} ${params.phageannotator.wf_opts ?: ''}",
            readWithDefault( params.phageannotator.params_file, Channel.value([]) ),
            readWithDefault( params.phageannotator.input, Channel.value([]) ),
            readWithDefault( params.phageannotator.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/phageannotator').toUriString(),
        )
    }
    if (params.enable_funcscan) {
        // MAG -> FUNCSCAN (MEGAHIT contigs), falling back to METATDENOVO's single
        // co-assembly when mag didn't run - both feed the same "fasta" node per the
        // metro map. Only one row results from metatdenovo (one combined assembly,
        // not per-sample contigs).
        def funcscan_default_input = createFuncscanSamplesheet(mag_output)
        if (!mag_output && metatdenovo_output) {
            funcscan_default_input = createFuncscanSamplesheet(metatdenovo_output, 'megahit/megahit_out/*.fa.gz')
        }
        NFCORE_FUNCSCAN (
            'nf-core/funcscan',
            "${params.general.wf_opts ?: ''} ${params.funcscan.wf_opts ?: ''}",
            readWithDefault( params.funcscan.params_file, Channel.value([]) ),
            readWithDefault( params.funcscan.input, funcscan_default_input ),
            readWithDefault( params.funcscan.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/funcscan').toUriString(),
        )
    }
    if (params.enable_proteinfamilies) {
        // MAG -> PROTEINFAMILIES: mag's own unconditional per-assembly gene-prediction
        // step (Prodigal, `Annotation/Prodigal/[assembler]-[sample].faa.gz`) is a more
        // reliable protein source here than funcscan's - funcscan only runs its own
        // annotation subworkflow when ARG screening's deeparg, AMP, BGC, or CAZyme
        // screening is enabled, and this repo's own funcscan wiring keeps deeparg/AMP/
        // CAZyme off for single-sample reliability (see tests/chains.nf.test), so it
        // wouldn't reliably produce one. Reuses createFuncscanSamplesheet's sample,fasta
        // shape - proteinfamilies' own schema is identical.
        NFCORE_PROTEINFAMILIES (
            'nf-core/proteinfamilies',
            "${params.general.wf_opts ?: ''} ${params.proteinfamilies.wf_opts ?: ''}",
            readWithDefault( params.proteinfamilies.params_file, Channel.value([]) ),
            readWithDefault( params.proteinfamilies.input, createFuncscanSamplesheet(mag_output, 'Annotation/Prodigal/*.faa.gz') ),
            readWithDefault( params.proteinfamilies.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/proteinfamilies').toUriString(),
        )
    }
    if (params.enable_phyloplace) {
        // NOTE: nf-core/phyloplace's real samplesheet flag is --phyloplace_input, not
        // --input (verified against its nextflow_schema.json) - unlike every other
        // pipeline wired here. `phyloplace.input`/readWithDefault below is therefore
        // always [] in practice: NEXTFLOW_RUN only ever emits `--input`, which
        // phyloplace doesn't recognise. Use `phyloplace.params_file` (with its own
        // `phyloplace_input:`/`phylosearch_input:` key) instead - the only viable path
        // today. Not otherwise auto-wireable regardless: sample,queryseqfile,
        // refseqfile,refphylogeny,model is one CSV where refseqfile/refphylogeny/model
        // are per-row required and always user-supplied, so a partial row (queryseqfile
        // only, from mag/funcscan marker genes) still wouldn't validate on its own.
        NFCORE_PHYLOPLACE (
            'nf-core/phyloplace',
            "${params.general.wf_opts ?: ''} ${params.phyloplace.wf_opts ?: ''}",
            readWithDefault( params.phyloplace.params_file, Channel.value([]) ),
            readWithDefault( params.phyloplace.input, Channel.value([]) ),
            readWithDefault( params.phyloplace.add_config, Channel.value([]) ),
            workflow.workDir.resolve('nf-core/phyloplace').toUriString(),
        )
    }
}
