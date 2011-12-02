require 'sqlite3'
require 'fileutils'
require 'csv'
require 'json'

class StarDatabase
  DATABASE = 'stars.db'
  CSVDB = '/home/rramsden/share/hygfull.csv'

  class << self
    def create
      FileUtils.rm("./stars.db") rescue nil
      db = SQLite3::Database.new( DATABASE )

db.execute <<SQL
  CREATE TABLE stars (
   id INTEGER PRIMARY KEY,
   name VARCHAR(32),
   bayer VARCHAR(32),
   ra FLOAT(4,5),
   dec FLOAT(4,5),
   distance FLOAT(4,5),
   absmag FLOAT(4,5),
   mag FLOAT(4,5),
   color FLOAT(4,5),
   x FLOAT(4,5),
   y FLOAT(4,5),
   z FLOAT(4,5)
  );
SQL

      i,csv = read
      queries = ""

      db.transaction do |d|

        csv.each_with_index do |row,index|
          name = "\"#{row[i["ProperName"]]}\""
          bayer = "\"#{row[i["BayerFlamsteed"]]}\""
          name = (name == "\"\"" ? "NULL" : name)
          bayer = (bayer == "\"\"" ? "NULL" : bayer)

          ra = row[i["RA"]].to_f
          dec = row[i["Dec"]].to_f
          distance = row[i["Distance"]].to_f

          # distance hardcoded at 1000.0
          x = ((1000.0 * cos(dec)) * cos(ra*15.0))
          y = ((1000.0 * cos(dec)) * sin(ra*15.0))
          z = (1000.0 * sin(dec))

          mag = row[i["Mag"]]
          absmag = row[i["AbsMag"]]

          color = row[i["ColorIndex"]].to_f

          q = "INSERT INTO stars (name,bayer,ra,dec,distance,absmag,mag,color,x,y,z) VALUES (#{name},#{bayer},#{ra},#{dec},#{distance},#{absmag},#{mag},#{color},#{x},#{y},#{z});"
          d.execute(q)
          puts index
        end

      end

      db.close
    end

    def read
      counter = 0
      csv = CSV.read( CSVDB )
      i = csv.first.inject({}) do |accum, element|
        accum[element] = counter
        counter = counter + 1
        accum
      end
      csv.shift
      [i,csv]
    end

    def cos(n)
      Math.cos(n*(Math::PI/180))
    end

    def sin(n)
      Math.sin(n*(Math::PI/180))
    end

    def export
      i,csv = read

      filter_by_name = csv.select {|e| (e[ i["ProperName"] ] != nil) or (( e[i["BayerFlamsteed"]] != nil) and (e[i["Mag"]].to_f < 5)) }
      res = filter_by_name.inject({}) do |accum, e|
        distance = 1000.0 #e[i["Distance"]].to_f * 3.26163626 # distance in ly
        ra = e[i["RA"]].to_f * 15.0 # in degrees
        dec = e[i["Dec"]].to_f

        x = ((distance * cos(dec)) * cos(ra))
        y = ((distance * cos(dec)) * sin(ra))
        z = (distance * sin(dec))

        color_index = e[i["ColorIndex"]].to_f

        mag = e[i["Mag"]].to_f
        accum[e[0].to_i] = {
          :name => e[i['ProperName']],
          :bayer => e[i['BayerFlamsteed']],
          :x => x,
          :y => y,
          :z => z,
          :mag => mag,
          :color => color_index
        }
        accum
      end
      puts res.to_json
    end
  end
end
