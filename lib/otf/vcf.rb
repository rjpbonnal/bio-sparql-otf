module OTF
  class VCF
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

      prefix = {
        "faldo" => "http://biohackathon.org/resource/faldo#",
        "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
        "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "dc" => "http://purl.org/dc/terms/"
      }

      case @vcf.getID
        when "."
          varID = Digest::MD5.hexdigest("#{@config["species"]}:#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}")
          varURI = "#{varBaseURI}/#{varID}"
        else
          varID = @vcf.getID
          varURI = "#{varBaseURI}/#{varID}"
          vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(prefix["dc"]+"identifier"),@vcf.getID]
          vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(prefix["rdfs"]+"label"),@vcf.getID]
      end
      vcf_rdf << [RDF::URI.new(refBaseURI),RDF::URI.new(prefix["dc"]+"identifier"),"#{@vcf.getChr}"]
      faldoRegion = RDF::URI.new(refBaseURI+":#{@vcf.getStart}-#{@vcf.getEnd}:1")
      vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(prefix["faldo"]+"location"),faldoRegion]
      vcf_rdf << [faldoRegion,RDF::URI.new(prefix["rdfs"]+"label"),"#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}:1"]
      vcf_rdf << [faldoRegion,RDF::URI.new(prefix["rdf"]+"type"),RDF::URI.new(prefix["faldo"]+"Region")]
      vcf_rdf << [faldoRegion,RDF::URI.new(prefix["faldo"]+"begin"),RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")]
      vcf_rdf << [faldoRegion,RDF::URI.new(prefix["faldo"]+"end"),RDF::URI.new(refBaseURI+":#{@vcf.getEnd}:1")]
      vcf_rdf << [faldoRegion,RDF::URI.new(prefix["faldo"]+"reference"),RDF::URI.new(refBaseURI)]
      if @vcf.getStart == @vcf.getEnd
        faldoExactPosition = RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")
        vcf_rdf << [faldoExactPosition,RDF::URI.new(prefix["rdf"]+"type"),"faldo:ExactPosition"]
        vcf_rdf << [faldoExactPosition,RDF::URI.new(prefix["rdf"]+"type"),"faldo:ForwardStrandPosition"]
        vcf_rdf << [faldoExactPosition,RDF::URI.new(prefix["faldo"]+"position"),@vcf.getStart]
        vcf_rdf << [faldoExactPosition,RDF::URI.new(prefix["faldo"]+"reference"),RDF::URI.new(refBaseURI)]
      end
      refAllele = @vcf.getReference.getBaseString
      refAlleleURI = RDF::URI.new(varURI+"\##{refAllele}")
      vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varURI+":has_allele"),refAlleleURI]
      vcf_rdf << [refAlleleURI,RDF::URI.new(prefix["rdfs"]+"label"),"#{varID} allele #{refAllele}"]
      vcf_rdf << [refAlleleURI,RDF::URI.new(prefix["rdf"]+"type"),RDF::URI.new(varURI+":reference_allele")]
      altAllele = @vcf.getAlternateAlleles.first.getBaseString
      altAlleleURI = RDF::URI.new(varURI+"\##{altAllele}")
      vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varURI+":has_allele"),altAlleleURI]
      vcf_rdf << [altAlleleURI,RDF::URI.new(prefix["rdfs"]+"label"),"#{varID} allele #{altAllele}"]
      vcf_rdf << [altAlleleURI,RDF::URI.new(prefix["rdf"]+"type"),RDF::URI.new(varURI+":ancestral_allele")]
      vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varBaseURI+"/vcf/quality"),RDF::Literal::Double.new(@vcf.getPhredScaledQual)]
      @vcf.getAttributes.each_key do |attr|
        vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varBaseURI+"/vcf/attribute\##{attr}"),@vcf.getAttribute(attr)]
      end

      vcf_rdf
    end #to_rdf
  end #VCF
end #OTF