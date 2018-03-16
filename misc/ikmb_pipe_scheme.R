
library(DiagrammeR)
library(DiagrammeRsvg)
library(magrittr)
library(rsvg)

pipe <- 
  grViz("
        digraph nicegraph {
        #rankdir=LR
        compound=true
        splines=false
        # graph, node, and edge definitions
        graph [compound = true, nodesep = 1, ranksep = .5,
        color = crimson]
        
        node [fontname = Helvetica, fontcolor = darkslategray,
        shape = rectangle, fixedsize = false, width = 3,
        color = darkslategray, fillcolor = GhostWhite, style=filled]
        
        edge [color = grey, arrowtail = none]
        
        a [label = 'INPUT\npath containing .fastq files\nin individual directories']
        b [label = 'INPUT\n(small RNA-Seq data)\n.fastq']
        A [label = 'REMOVE ADAPTERS\n(cutadapt)\ntrimmed.fastq']
        B [label = 'COLLAPSE READS\n(collapse_reads_md.pl)\ncollapsed.trimmed.fastq']
        C [label = 'miRNA/isomiR ANNOTATION\n(miraligner.jar)\ncounts.mirna']
        D [label = 'miRNA ANNOTATION\n(quantifier.pl)\ncounts.tsv']
        F [label = 'OUTPUT\n(dir=$sample/miRpipe_out))\nresults']
        I [label = 'DOWNSTREAM ANALYSES\n(DESeq2 / isomiRs, R)\nresults']
        G [label = 'VIRUS FILTER\n(RefSeq & miRBase)\n.fasta']
        H [label = 'tRNA, rRNA, snRNA & sRNA FILTER\n(Rfam)\n.fasta']
        
        #{rank = same; b; G}
        
        # subgraph for pre-procesing
        subgraph cluster0 {
        labeljust='l'
        label='MODULE 1: pre-procesing'
        color=black
        node [fixedsize = true, width = 3]
        b -> A [ label='report number of\nraw sequences']
        A -> B [ label='report number of\n QCed and trimmed\nsequences']
        }
        
        # subgraph for filtering
        subgraph cluster1 {
        labeljust='l'
        label='MODULE 2: filtering'
        node [fixedsize = true, width = 3]
        color=black
        B -> G [ constraint=false ] 
        G -> H [ label='report number of\n QCed and trimmed\nsequences']
        }

        # subgraph for miraligner
        subgraph cluster2 {
        #  labeljust='l'
        label='MODULE 3: miRNA/isomiR annotation'
        color=black
        node [fixedsize = true, width = 3]
        H -> C [ label='> if [$run_miraligner -eq 1]; then']
        H -> D [ label='> if [$run_quantifier -eq 1]; then']
        }
        
        a -> b [ label=' > for sample in $dir; do']
        C -> F [ label='mapping QC']
        D -> F [ label='mapping QC']
        F -> I [ label=' > done']
        }
        

        ")

export_svg(pipe) %>% charToRaw %>% rsvg_png(file='pipe_scheme.png')
