
module FsIndex
    class IBT #IndexByTabix
    require 'sequel'
    require 'bio-bgzf'
    require 'java'
    require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
    java_import 'htsjdk.tribble.readers.TabixReader'
    #specific for reading BgZip Files
    def initialize(filename)
      @filename = filename
      @db = Sequel.connect("jdbc:sqlite:#{@filename}.ibt")
      @tabix = TabixReader.new @filename
      begin
        @db.create_table :positions do
          String :rs #the name on which is possible to perform the query
          Integer :chr #chr
          Integer :position #start
        end unless @db.table_exists?(:positions)
        @positions = @db[:positions]
      rescue Exception => e
        puts "This is the original message: #{e.message}"
      end #files_index
    end #initialize

    def filename 
      @filename
    end
# you can use name to override the name of the file into the database
# requires a yield and must return an array of tags
    def index_file()
      @db.disconnect
      `gunzip -c #{@filename} | grep -v "^#" | awk '{print $3","$1","$2}' > #{@filename}.tmp_csv`
      File.open("#{@filename}.bulk", 'w') do |f|
        f.puts <<-STR
CREATE TABLE positions(
   rs TEXT,
   chr TEXT,
   position INT
);
.separator ,
.import #{@filename}.tmp_csv positions
CREATE INDEX rs_index
ON positions (rs);
STR

`sqlite3 -init #{@filename}.bulk #{@filename}.ibt`
`rm #{@filename}.tmp_csv`
`rm #{@filename}.bulk`
      # @h[tag.to_sym] << {block_vo: vo, iblock_vo: iblock_vo, tag: tag.to_sym, leftover: leftover}
      # @db.synchronous=:normal
      # @db.temp_store=:memory
    end
    @db = Sequel.connect("jdbc:sqlite:#{@filename}.ibt")
  end

    def search(rs)

        @positions.where(tags: key).each do |record|
          region = @tabix.parseReg("#{record.chr}:#{record.position}")
          @tabix.query(region).each do |item|
            # item 
          end
        end
    end #search

  end #IBT IndexByTabix

end 