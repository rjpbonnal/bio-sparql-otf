module OTF
  
  

  class VCF
    FALDO = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")
    include RDF

    def initialize(vcf, config)
      @vcf = vcf
      @config = config

    end

    def to_rdf
      refBaseURI = "http://rdf.ebi.ac.uk/resource/ensembl/#{@config['ensemblVersion']}/chromosome:#{@config['assemblyVersion']}:#{@vcf.getChr}"
      varBaseURI = "http://rdf.ebi.ac.uk/terms/ensemblvariation"
      vcf_rdf = []
      varURI = nil
      varID = nil

      # prefix = {
      #   "faldo" => "http://biohackathon.org/resource/faldo#", FALDO.
      #   "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",    RDFS.
      #   "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",  RDF.
      #   "dc" => "http://purl.org/dc/terms/" DC.
      # }

      case @vcf.getID
        when "."
          varID = Digest::MD5.hexdigest("#{@config["species"]}:#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}")
          varURI = "#{varBaseURI}/#{varID}"
        else
          varID = @vcf.getID
          varURI = "#{varBaseURI}/#{varID}"
          
          vcf_rdf << [URI(varURI), DC.identifier ,@vcf.getID]

          vcf_rdf << [URI(varURI),RDFS.label),@vcf.getID]
      end
      vcf_rdf << [URI(refBaseURI),DC.identifier,"#{@vcf.getChr}"]
      faldoRegion = URI(refBaseURI+":#{@vcf.getStart}-#{@vcf.getEnd}:1")
      vcf_rdf << [URI(varURI),FALDO.location,faldoRegion]
      vcf_rdf << [faldoRegion,RDFS.label,"#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}:1"]
      vcf_rdf << [faldoRegion,RDF.type,FALDO.Region]
      vcf_rdf << [faldoRegion,FALDO.begin,URI(refBaseURI+":#{@vcf.getStart}:1")]
      vcf_rdf << [faldoRegion,FALDO.end,URI(refBaseURI+":#{@vcf.getEnd}:1")]
      vcf_rdf << [faldoRegion,FALDO.reference,URI(refBaseURI)]
      if @vcf.getStart == @vcf.getEnd
        faldoExactPosition = URI(refBaseURI+":#{@vcf.getStart}:1")
        vcf_rdf << [faldoExactPosition,RDF.type,"faldo:ExactPosition"]
        vcf_rdf << [faldoExactPosition,RDF.type,"faldo:ForwardStrandPosition"]
        vcf_rdf << [faldoExactPosition,FALDO.position,@vcf.getStart]
        vcf_rdf << [faldoExactPosition,FALDO.reference,URI(refBaseURI)]
      end
      refAllele = @vcf.getReference.getBaseString
      refAlleleURI = URI(varURI+"\##{refAllele}")
      vcf_rdf << [URI(varURI),URI.(varURI+":has_allele"),refAlleleURI]
      vcf_rdf << [refAlleleURI,RDFS.label,"#{varID} allele #{refAllele}"]
      vcf_rdf << [refAlleleURI,RDF.type,URI(varURI+":reference_allele")]
      altAllele = @vcf.getAlternateAlleles.first.getBaseString
      altAlleleURI = URI(varURI+"\##{altAllele}")
      vcf_rdf << [URI(varURI),URI(varURI+":has_allele"),altAlleleURI]
      vcf_rdf << [altAlleleURI,RDFS.label,"#{varID} allele #{altAllele}"]
      vcf_rdf << [altAlleleURI,RDF.type,URI(varURI+":ancestral_allele")]
      vcf_rdf << [URI(varURI),URI(varBaseURI+"/vcf/quality"),Literal::Double(@vcf.getPhredScaledQual)]
      @vcf.getAttributes.each_key do |attr|
        vcf_rdf << [URI(varURI),URI(varBaseURI+"/vcf/attribute\##{attr}"),@vcf.getAttribute(attr)]
      end

      vcf_rdf
    end #to_rdf
  end #VCF
end #OTF