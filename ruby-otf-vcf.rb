
require 'java'
require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
require 'lib/jar/bzip2.jar' #wget http://www.kohsuke.org/bzip2/bzip2.jar
require 'rdf'
require 'rdf/ntriples'
require 'sparql'
require 'securerandom'

# require 'lib/indexing'
require 'lib/otf'


file_name = ARGV[0]

# unless File.exists?("#{file_name}.fsidx")
#   print "Creting Index for text search..."
#   index = ::FsIndex::Index.new file_name

# end



query = File.open(ARGV[1]).read

file = java.io.File.new(ARGV[0])
fileidx = java.io.File.new("#{ARGV[0]}.tbi")
vcf = VCFFileReader.new(file, fileidx, true)

triplets = []
chr = nil
start = nil
stop = nil

vcf_parameters = File.open(ARGV[2]).read

chr, start, final = OTF::Query.get_parameters(query, vcf_parameters)


puts chr
puts start
puts final

chr_val = chr.last.to_s
start_val = start.last.to_s
final_val = final.last.to_s

repository = RDF::Graph.new

if chr_val && start_val && final_val
  vcf.query(chr_val, start_val.to_i, final_val.to_i).each do |vc|
    OTF::VCF.new(vc, ARGV[3]).to_rdf.each do |vcf_statement|
        repository << vcf_statement
      # puts vcf_statement.inspect
    end
  end
end

repository.each do |s|
  puts s.inspect
end

# repository.graphs.enum_triple do |t|
#   puts t
# end
# puts SPARQL.execute(query, repository, options={}).inspect