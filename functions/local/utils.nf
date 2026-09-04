/**
 * Returns a channel with the path if it's defined, otherwise returns a default channel.
 *
 * @param path             The path to include into the channel
 * @param default_channel  A channel to use as the default if no path is defined.
 * @return                 A channel with a path, or the default channel
 */
def readWithDefault(String path, Object default_channel) {
    path ? channel.fromPath(path, checkIfExists: true) : default_channel
}

/**
 * Returns a channel with the file defined by the path resolved against the directory.
 *
 * @param path  The path of the file relative to the directory in dir
 * @param dir   A channel with a directory.
 * @return      A channel with a path relative to the dir path
 */
def resolveFileFromDir(String path, Object dir) {
    dir.map { results -> file(results.resolve(path)) }
}

/**
 * Returns a channel with a samplesheet for nf-core/mag.
 *
 * @param dir   A channel with a directory. Fastq.gz files are assumed to be in a folder called fastq here.
 * @return      A channel with a samplesheet or empty list
 */
def createMagSamplesheet(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["sample,group,short_reads_1,short_reads_2,long_reads,short_reads_platform"] + files(results.resolve('fastq/*fastq.gz'), checkIfExists: true).collect { file ->
                    "${file.simpleName},0,${file},,,ILLUMINA"
                }).join("\n")
            }
            .collectFile(name: 'mag_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/funcscan.
 *
 * @param dir   A channel with a directory containing assembled contigs.
 * @param glob  Glob (relative to dir) matching one fasta.gz file per sample/assembly.
 *              Defaults to nf-core/mag's MEGAHIT contigs.
 * @return      A channel with a samplesheet or empty list
 */
def createFuncscanSamplesheet(Object dir, String glob = 'Assembly/MEGAHIT/*.fa.gz') {
    if (dir) {
        dir
            .map { results ->
                (["sample,fasta"] + files(results.resolve(glob), checkIfExists: true).collect { file ->
                    "${file.simpleName},${file}"
                }).join("\n")
            }
            .collectFile(name: 'funcscan_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Reads nf-core/fetchngs' default samplesheet.csv into a channel of clean row maps
 * (sample,fastq_1,fastq_2,... keyed by their real column names).
 *
 * nf-core/fetchngs writes every field RFC4180-quoted (e.g. "sample","fastq_1",...),
 * but splitCsv(header:true) does not decode quoting - both header field names and
 * values come back with their literal surrounding quote characters still attached
 * (e.g. a key of `"sample"` rather than `sample`, a value of `"ERX3576970"` rather
 * than `ERX3576970`). Quotes are stripped from both here so `row.sample`/`row.fastq_1`
 * resolve correctly and values written out downstream aren't double-quoted.
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel of row maps
 */
def readFetchngsSamplesheet(Object dir) {
    resolveFileFromDir('samplesheet/samplesheet.csv', dir)
        .splitCsv(header: true)
        .map { row ->
            row.collectEntries { k, v -> [(k.replaceAll(/^"|"$/, '')): v instanceof String ? v.replaceAll(/^"|"$/, '') : v] }
        }
}

/**
 * Returns a channel with a samplesheet for nf-core/metatdenovo, reprojecting
 * nf-core/fetchngs' default samplesheet to metatdenovo's sample,fastq_1,fastq_2
 * schema (fetchngs' --nf_core_pipeline auto-formatting does not cover metatdenovo,
 * unlike rnaseq/atacseq/viralrecon/taxprofiler).
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createMetatdenovoSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample},${row.fastq_1},${row.fastq_2 ?: ''}" }
            .collectFile(name: 'metatdenovo_samplesheet.csv', newLine: true, sort: false, seed: 'sample,fastq_1,fastq_2')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/ampliseq, reprojecting
 * nf-core/fetchngs' default samplesheet to ampliseq's legacy
 * sampleID,forwardReads,reverseReads schema (fetchngs' --nf_core_pipeline
 * auto-formatting does not cover ampliseq, unlike rnaseq/atacseq/viralrecon/taxprofiler).
 * The legacy names are used rather than ampliseq's newer sample,fastq_1,fastq_2
 * alias because they're the only ones guaranteed to validate across ampliseq
 * releases - verified empirically: 2.14.0's schema requires sampleID/forwardReads
 * and does not recognise sample/fastq_1 at all, while 2.18.0 accepts both.
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createAmpliseqSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample},${row.fastq_1},${row.fastq_2 ?: ''}" }
            .collectFile(name: 'ampliseq_samplesheet.csv', newLine: true, sort: false, seed: 'sampleID,forwardReads,reverseReads')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/detaxizer, reprojecting
 * nf-core/fetchngs' default samplesheet to detaxizer's
 * sample,short_reads_fastq_1,short_reads_fastq_2 schema (fetchngs' --nf_core_pipeline
 * auto-formatting does not cover detaxizer, unlike rnaseq/atacseq/viralrecon/taxprofiler).
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createDetaxizerSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample},${row.fastq_1},${row.fastq_2 ?: ''}" }
            .collectFile(name: 'detaxizer_samplesheet.csv', newLine: true, sort: false, seed: 'sample,short_reads_fastq_1,short_reads_fastq_2')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/metatdenovo, built from
 * nf-core/detaxizer's decontaminated single-end reads (`filter/filtered/
 * <sample>_filtered.fastq.gz`). detaxizer's native downstream-samplesheet generator
 * (see createDetaxizerSamplesheet's caller) only supports taxprofiler/mag, not
 * metatdenovo, hence this separate glob-based glue. Single-end only, matching this
 * codebase's other glue.
 *
 * @param dir   A channel with a directory (an nf-core/detaxizer results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createMetatdenovoSamplesheetFromDetaxizer(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["sample,fastq_1,fastq_2"] + files(results.resolve('filter/filtered/*_filtered.fastq.gz'), checkIfExists: true).collect { file ->
                    "${file.simpleName - '_filtered'},${file},"
                }).join("\n")
            }
            .collectFile(name: 'metatdenovo_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a TSV samplesheet for nf-core/eager, reprojecting
 * nf-core/fetchngs' default samplesheet to eager's Sample_Name/Library_ID/Lane/
 * Colour_Chemistry/SeqType/Organism/Strandedness/UDG_Treatment/R1/R2/BAM schema.
 * Colour_Chemistry=4, Strandedness=double and UDG_Treatment=none are eager's own
 * documented pipeline-level defaults (not invented here) - but eager has no real
 * experimental metadata for these from fetchngs' own output either way, and they
 * materially affect aDNA damage/authentication results, so review them before
 * trusting anything downstream that depends on them. Organism is always unknown -
 * set to NA.
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createEagerSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample}\t${row.sample}\t0\t4\t${row.fastq_2 ? 'PE' : 'SE'}\tNA\tdouble\tnone\t${row.fastq_1}\t${row.fastq_2 ?: 'NA'}\tNA" }
            .collectFile(name: 'eager_samplesheet.tsv', newLine: true, sort: false, seed: 'Sample_Name\tLibrary_ID\tLane\tColour_Chemistry\tSeqType\tOrganism\tStrandedness\tUDG_Treatment\tR1\tR2\tBAM')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a TSV samplesheet for nf-core/eager, built from
 * nf-core/detaxizer's decontaminated single-end reads. See createEagerSamplesheet
 * for the Colour_Chemistry/Strandedness/UDG_Treatment default rationale.
 *
 * @param dir   A channel with a directory (an nf-core/detaxizer results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createEagerSamplesheetFromDetaxizer(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["Sample_Name\tLibrary_ID\tLane\tColour_Chemistry\tSeqType\tOrganism\tStrandedness\tUDG_Treatment\tR1\tR2\tBAM"] + files(results.resolve('filter/filtered/*_filtered.fastq.gz'), checkIfExists: true).collect { file ->
                    def sample = file.simpleName - '_filtered'
                    "${sample}\t${sample}\t0\t4\tSE\tNA\tdouble\tnone\t${file}\tNA\tNA"
                }).join("\n")
            }
            .collectFile(name: 'eager_samplesheet.tsv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/metapep (type=assembly), built from
 * nf-core/mag's MEGAHIT contigs - one condition per sample/assembly, condition named
 * after the sample (no grouping assumed, same neutral-default spirit as
 * createMagSamplesheet's group=0). `weights_path` is left blank (optional per metapep's
 * own schema).
 *
 * `alleles` uses real per-sample HLA genotypes from nf-core/hlatyping's OptiType output
 * (`optitype/<sample>/<sample>_result.tsv`, tab-separated with columns
 * A1,A2,B1,B2,C1,C2,Reads,Objective - verified against a real run) when `hlatypingDir`
 * is given, falling back to "A*01:01 B*07:02" - the exact example HLA-I allele pair
 * from nf-core/metapep's own test-datasets samplesheet, not fabricated here - for any
 * sample hlatyping didn't call (or when hlatyping wasn't run at all). Real typing is
 * still preferable to review even when available: OptiType only calls Class I
 * (A/B/C) alleles, and HLA typing is a host-genome analysis - only meaningful when a
 * host DNA fraction is actually present in the sample (e.g. this repo's own ancient
 * dental calculus test data), not for purely environmental metagenomes.
 *
 * @param dir            A channel with a directory (an nf-core/mag results dir).
 * @param hlatypingDir   A channel with a directory (an nf-core/hlatyping results dir),
 *                       or falsy to always use the placeholder alleles.
 * @return               A channel with a samplesheet or empty list
 */
def createMetapepSamplesheet(Object dir, Object hlatypingDir = null) {
    if (dir) {
        def alleles_by_sample = hlatypingDir
            ? hlatypingDir.map { results ->
                files(results.resolve('optitype/*/*_result.tsv'), checkIfExists: false).collectEntries { tsv ->
                    def lines = tsv.readLines()
                    def alleles = lines.size() > 1
                        ? lines[1].split('\t')[1..6].findAll { it && it != 'nan' }.join(' ')
                        : ''
                    [(tsv.simpleName - '_result'): alleles]
                }.findAll { sample, alleles -> alleles }
            }
            : channel.value([:])
        dir.combine(alleles_by_sample).map { results, alleles ->
            (["condition,type,microbiome_path,alleles,weights_path"] + files(results.resolve('Assembly/MEGAHIT/*.fa.gz'), checkIfExists: true).collect { file ->
                def sample = file.simpleName
                "${sample},assembly,${file},${alleles[sample] ?: 'A*01:01 B*07:02'},"
            }).join("\n")
        }
        .collectFile(name: 'metapep_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/hlatyping, reprojecting
 * nf-core/fetchngs' default samplesheet to hlatyping's sample,fastq_1,fastq_2,
 * seq_type schema (fetchngs' --nf_core_pipeline auto-formatting does not cover
 * hlatyping, unlike rnaseq/atacseq/viralrecon/taxprofiler). seq_type defaults to
 * 'dna'. HLA typing is a HOST-genome analysis, not a microbiome one - see
 * createMetapepSamplesheet for when this is actually meaningful to run.
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createHlatypingSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample},${row.fastq_1},${row.fastq_2 ?: ''},dna" }
            .collectFile(name: 'hlatyping_samplesheet.csv', newLine: true, sort: false, seed: 'sample,fastq_1,fastq_2,seq_type')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/hlatyping, built from
 * nf-core/detaxizer's decontaminated single-end reads. See createHlatypingSamplesheet
 * for the seq_type/host-vs-microbiome caveat.
 *
 * @param dir   A channel with a directory (an nf-core/detaxizer results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createHlatypingSamplesheetFromDetaxizer(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["sample,fastq_1,fastq_2,seq_type"] + files(results.resolve('filter/filtered/*_filtered.fastq.gz'), checkIfExists: true).collect { file ->
                    "${file.simpleName - '_filtered'},${file},,dna"
                }).join("\n")
            }
            .collectFile(name: 'hlatyping_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/coproid, reprojecting
 * nf-core/fetchngs' default samplesheet to coproid's sample,fastq_1,fastq_2 schema
 * (fetchngs' --nf_core_pipeline auto-formatting does not cover coproid, unlike
 * rnaseq/atacseq/viralrecon/taxprofiler). coproid also always needs its own
 * genomesheet (candidate host/source genomes), --kraken2_db, --sp_sources and
 * --sp_labels - always user-supplied via coproid.params_file, since no upstream
 * stage carries that information; coproid's own validation catches a missing one.
 *
 * @param dir   A channel with a directory (an nf-core/fetchngs results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createCoproidSamplesheet(Object dir) {
    if (dir) {
        readFetchngsSamplesheet(dir)
            .map { row -> "${row.sample},${row.fastq_1},${row.fastq_2 ?: ''}" }
            .collectFile(name: 'coproid_samplesheet.csv', newLine: true, sort: false, seed: 'sample,fastq_1,fastq_2')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a samplesheet for nf-core/coproid, built from
 * nf-core/detaxizer's decontaminated single-end reads. See createCoproidSamplesheet
 * for the always-manual genomesheet/kraken2_db/sourcepredict caveat.
 *
 * @param dir   A channel with a directory (an nf-core/detaxizer results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createCoproidSamplesheetFromDetaxizer(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["sample,fastq_1,fastq_2"] + files(results.resolve('filter/filtered/*_filtered.fastq.gz'), checkIfExists: true).collect { file ->
                    "${file.simpleName - '_filtered'},${file},"
                }).join("\n")
            }
            .collectFile(name: 'coproid_samplesheet.csv')
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with nf-core/magmap's counts table to use as nf-core/
 * differentialabundance's --matrix. magmap's own output docs name this
 * `summary_tables/magmap.<FEATURE>.counts.tsv.gz`, with <FEATURE> depending on
 * magmap's own --feature param, hence the glob; the first match is used if magmap
 * produced counts for more than one feature - override differentialabundance.wf_opts
 * with an explicit --matrix if you need a different one. Ready-to-use as-is per
 * magmap's own docs (a real counts table, not a placeholder) - unlike this file's
 * other "default" glue, nothing here needs review before trusting it.
 *
 * @param dir   A channel with a directory (an nf-core/magmap results dir).
 * @return      A channel with a file path or empty list
 */
def createDifferentialabundanceMatrix(Object dir) {
    if (dir) {
        dir.map { results -> files(results.resolve('summary_tables/magmap.*.counts.tsv.gz'), checkIfExists: true)[0] }
    }
    else {
        channel.value([])
    }
}

/**
 * Returns a channel with a --genomeinfo CSV for nf-core/magmap, built from nf-core/mag's
 * MetaBAT2 genome bins. genome_gff is left blank - magmap auto-annotates bins that are
 * missing a gff (via Prokka/Bakta).
 *
 * @param dir   A channel with a directory (an nf-core/mag results dir).
 * @return      A channel with a samplesheet or empty list
 */
def createMagmapGenomeInfo(Object dir) {
    if (dir) {
        dir
            .map { results ->
                (["accno,genome_fna,genome_gff"] + files(results.resolve('GenomeBinning/MetaBAT2/bins/*.fa.gz'), checkIfExists: true).collect { file ->
                    "${file.simpleName},${file},"
                }).join("\n")
            }
            .collectFile(name: 'magmap_genomeinfo.csv')
    }
    else {
        channel.value([])
    }
}
