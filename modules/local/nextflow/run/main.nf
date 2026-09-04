process NEXTFLOW_RUN {
    // directives:
    tag "${pipeline_name}"

    input:
    val pipeline_name      // String
    val nextflow_opts      // String
    val params_file        // pipeline params-file
    val samplesheet        // pipeline samplesheet
    val additional_config  // custom configs
    val cache_dir

    exec:
    // Set cache directory so workflow can `-resume`
    def cache_path = file(cache_dir)
    assert cache_path.mkdirs()

    // Env vars inherited from a Tower/Seqera Platform launch break the nested run - see nf-cascade#6.
    // NXF_SYNTAX_PARSER=v1: this meta-pipeline runs on a recent Nextflow, but pinned
    // nf-core pipeline releases (even current ones, e.g. fetchngs 1.12.0) commonly still
    // use the legacy `def check_max(obj, type) { ... }`-style helper in their own
    // nextflow.config, which fails to parse under Nextflow's newer strict config parser
    // (v2) - verified empirically. v1 stays broadly compatible with both old and new
    // pipeline configs.
    def child_env = (System.getenv() + [NXF_IGNORE_RESUME_HISTORY: 'false', NXF_SYNTAX_PARSER: 'v1'])
        .collect { k, v -> "${k}=${v}" }

    // Construct nextflow command
    def nxf_cmd = [
        'nextflow',
            '-log .nextflow.log',
            'run',
            pipeline_name,
            nextflow_opts,
            params_file ? "-params-file ${params_file}" : '',
            additional_config ? "-c ${additional_config}" : '',
            samplesheet ? "--input ${samplesheet}" : '',
            "--outdir ${task.workDir}/results",
    ].join(" ")

    // Copy command to shell script in work dir for reference/debugging.
    file("${task.workDir}/nf-cmd.sh").text = nxf_cmd

    // Run nextflow command locally in cache directory
    def process = nxf_cmd.execute(child_env, cache_path.toFile())
    // Print process output to stdout and stderr
    process.consumeProcessOutput(System.out, System.err)
    process.waitFor()

    // Copy nextflow log to work directory
    cache_path.resolve(".nextflow.log").copyTo("${task.workDir}/nextflow.log")
    assert process.exitValue() == 0:
        """
        ============================================================
        PIPELINE FAILED: ${pipeline_name}
        Exit Code: ${process.exitValue()}
        Pipeline Log: ${task.workDir}/nextflow.log
        ============================================================
        """.stripIndent()

    // Clean cache of failed tasks
    def clean_cmd = ["/usr/bin/env", "bash", "-c", "nextflow clean -f -before last && find work -type d -empty -delete"]
    def clean_process = clean_cmd.execute(child_env, cache_path.toFile())
    clean_process.waitFor()
    assert clean_process.exitValue() == 0:
        """
        ============================================================
        CACHE CLEAN FAILED: ${pipeline_name}
        Exit Code: ${clean_process.exitValue()}
        ============================================================
        """.stripIndent()

    output:
    path "results", emit: output
}
