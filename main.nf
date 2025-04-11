include { NEXTFLOW_RUN as NFCORE_FETCHNGS              } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_DETAXIZER             } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_CREATETAXDB           } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_AMPLISEQ              } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_TAXPROFILER           } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_EAGER                 } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_MAGMAP                } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_MAG                   } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_METATDENOVO           } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_DIFFERENTIALABUNDANCE } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_METAPEP               } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_PHAGEANNOTATOR        } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_FUNCSCAN              } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as NFCORE_PHYLOPLACE            } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as GMS_METAVAL                  } from "$projectDir/modules/local/nextflow/run/main"

workflow {
    // TODO: Check params-file for values that override channel inputs

    NFCORE_FETCHNGS ( // Args: pipeline name, workflow opts, params file, samplesheet, custom config
        Channel.value('nf-core/fetchngs').filter{ params.fetchngs_enabled },
        "${params.all_cli?: ''} ${params.fetchngs_cli?: ''}",
        params.fetchngs_enabled && params.fetchngs_params ? file( params.fetchngs_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.fetchngs_enabled && params.fetchngs_config ? file(params.fetchngs_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/fetchngs').toUriString(),
    )

    NFCORE_DETAXIZER (
        Channel.value('nf-core/detaxizer').filter{ params.detaxizer_enabled },
        "${params.all_cli?: ''} ${params.detaxizer_cli?: ''}",
        params.detaxizer_enabled && params.detaxizer_params ? file( params.detaxizer_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.detaxizer_enabled && params.detaxizer_config ? file(params.detaxizer_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/detaxizer').toUriString(),
    )

    NFCORE_CREATETAXDB (
        Channel.value('nf-core/createtaxdb').filter{ params.createtaxdb_enabled },
        "${params.all_cli?: ''} ${params.createtaxdb_cli?: ''}",
        params.createtaxdb_enabled && params.createtaxdb_params ? file( params.createtaxdb_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.createtaxdb_enabled && params.createtaxdb_config ? file(params.createtaxdb_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/createtaxdb').toUriString(),
    )

    NFCORE_AMPLISEQ (
        Channel.value('nf-core/ampliseq').filter{ params.ampliseq_enabled },
        "${params.all_cli?: ''} ${params.ampliseq_cli?: ''}",
        params.ampliseq_enabled && params.ampliseq_params ? file( params.ampliseq_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.ampliseq_enabled && params.ampliseq_config ? file(params.ampliseq_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/ampliseq').toUriString(),
    )

    def taxprofiler_samplesheet = NFCORE_FETCHNGS.out.output
        // Extract samplesheet from fetchngs output
        .map { results -> results.resolve('samplesheet/samplesheet.csv') }
        // If params file has input: override taxprofiler samplesheet
        .filter { params.taxprofiler_enabled && params.taxprofiler_params ? file( params.taxprofiler_params, checkIfExists: true ).text.contains('input:') : true }
        .ifEmpty([])
    NFCORE_TAXPROFILER (
        Channel.value('nf-core/taxprofiler').filter{ params.taxprofiler_enabled },
        "${params.all_cli?: ''} ${params.taxprofiler_cli?: ''}",
        params.taxprofiler_enabled && params.taxprofiler_params ? file( params.taxprofiler_params, checkIfExists: true ) : [],
        taxprofiler_samplesheet,
        params.taxprofiler_enabled && params.taxprofiler_config ? file(params.taxprofiler_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/taxprofiler').toUriString(),
    )

    NFCORE_EAGER (
        Channel.value('nf-core/eager').filter{ params.eager_enabled },
        "${params.all_cli?: ''} ${params.eager_cli?: ''}",
        params.eager_enabled && params.eager_params ? file( params.eager_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.eager_enabled && params.eager_config ? file(params.eager_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/eager').toUriString(),
    )

    NFCORE_MAGMAP (
        Channel.value('nf-core/magmap').filter{ params.magmap_enabled },
        "${params.all_cli?: ''} ${params.magmap_cli?: ''}",
        params.magmap_enabled && params.magmap_params ? file( params.magmap_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.magmap_enabled && params.magmap_config ? file(params.magmap_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/magmap').toUriString(),
    )

    NFCORE_MAG (
        Channel.value('nf-core/mag').filter{ params.mag_enabled },
        "${params.all_cli?: ''} ${params.mag_cli?: ''}",
        params.mag_enabled && params.mag_params ? file( params.mag_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.mag_enabled && params.mag_config ? file(params.mag_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/mag').toUriString(),
    )

    NFCORE_METATDENOVO (
        Channel.value('nf-core/metatdenovo').filter{ params.metatdenovo_enabled },
        "${params.all_cli?: ''} ${params.metatdenovo_cli?: ''}",
        params.metatdenovo_enabled && params.metatdenovo_params ? file( params.metatdenovo_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.metatdenovo_enabled && params.metatdenovo_config? file(params.metatdenovo_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/metatdenovo').toUriString(),
    )

    NFCORE_DIFFERENTIALABUNDANCE (
        Channel.value('nf-core/differentialabundance').filter{ params.differentialabundance_enabled },
        "${params.all_cli?: ''} ${params.differentialabundance_cli?: ''}",
        params.differentialabundance_enabled && params.differentialabundance_params ? file( params.differentialabundance_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.differentialabundance_enabled && params.differentialabundance_config? file(params.differentialabundance_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/differentialabundance').toUriString(),
    )

    NFCORE_METAPEP (
        Channel.value('nf-core/metapep').filter{ params.metapep_enabled },
        "${params.all_cli?: ''} ${params.metapep_cli?: ''}",
        params.metapep_enabled && params.metapep_params ? file( params.metapep_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.metapep_enabled && params.metapep_config ? file(params.metapep_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/metapep').toUriString(),
    )

    NFCORE_PHAGEANNOTATOR (
        Channel.value('nf-core/phageannotator').filter{ params.phageannotator_enabled },
        "${params.all_cli?: ''} ${params.phageannotator_cli?: ''}",
        params.phageannotator_enabled && params.phageannotator_params ? file( params.phageannotator_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.phageannotator_enabled && params.phageannotator_config ? file(params.phageannotator_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/phageannotator').toUriString(),
    )

    NFCORE_FUNCSCAN (
        Channel.value('nf-core/funcscan').filter{ params.funcscan_enabled },
        "${params.all_cli?: ''} ${params.funcscan_cli?: ''}",
        params.funcscan_enabled && params.funcscan_params ? file( params.funcscan_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.funcscan_enabled && params.funcscan_config ? file(params.funcscan_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/funcscan').toUriString(),
    )

    NFCORE_PHYLOPLACE (
        Channel.value('nf-core/phyloplace').filter{ params.phyloplace_enabled },
        "${params.all_cli?: ''} ${params.phyloplace_cli?: ''}",
        params.phyloplace_enabled && params.phyloplace_params ? file( params.phyloplace_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.phyloplace_enabled && params.phyloplace_config ? file(params.phyloplace_config, checkIfExists: true) : [],
        workflow.workDir.resolve('nf-core/phyloplace').toUriString(),
    )

    GMS_METAVAL (
        Channel.value('gms/metaval').filter{ params.gms_metaval_enabled },
        "${params.all_cli?: ''} ${params.gms_metaval_cli?: ''}",
        params.gms_metaval_enabled && params.gms_metaval_params ? file( params.gms_metaval_params, checkIfExists: true ) : [],
        [], // Read from params-file
        params.gms_metaval_enabled && params.gms_metaval_config ? file(params.gms_metaval_config, checkIfExists: true) : [],
        workflow.workDir.resolve('gms/metaval').toUriString(),
    )
}