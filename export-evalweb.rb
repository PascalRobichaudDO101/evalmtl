#!/usr/bin/ruby
# encoding: UTF-8
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'dbm'

columns = [
  {'id' => :i},
  {'adresse' => :s}, {'ville' => :s}, {'proprietaire' => :s},
  {'arrondissement' => :s}, {'arrondissement_no' => :i},
  {'matricule' => :s}, {'compte' => :i}, {'uef_id' => :i},
  {'cubf' => :i}, {'nb_logements' => :i}, {'voisinage' => :i},
  {'emplacement_front' => :i}, {'emplacemment_profondeur' => :i}, {'emplacement_superficie' => :i},
  {'classe_non_residentielle' => :i}, {'classe_industrielle' => :s}, {'terrain_vague' => :s},
  {'annee_construction' => :i}, {'nb_etages' => :i}, {'nb_autres_locaux' => :i},
  {'annee_role_anterieur' => :i}, {'terrain_role_anterieur' => :i},
  {'batiment_role_anterieur' => :i}, {'immeuble_role_anterieur' => :i}, {'vide' => :s},
  {'loi' => :s}, {'article' => :s}, {'alinea' => :s}, {'valeur_terrain' => :i},
  {'valeur_batiment' => :i}, {'valeur_immeuble' => :i},
  {'code_imposition' => :s}, {'code_exemption' => :s}, {'maj' => :s},
  {'no_lot_renove' => :i}, {'paroisse' => :s}, {'lot' => :s}, {'subd' => :s},
  {'type_lot' => :s}, {'superficie' => :f}, {'front' => :f}, {'profond' => :f}
]

File.open("evaluations.sql", 'w') do |sql|
  sql.write("create database evalmtl ENGINE=InnoDB;\n")
  sql.write("use evalmtl\n")
  sql_types = {:s => "varchar(255)", :i => "integer", :f => "float"}
  sql.write("create table evaluations (\n" + columns.map{|c| c.map{|col,t| "  #{col} #{sql_types[t]}"}}.join(",\n") + "\n) ENGINE=InnoDB;\n")
  sql.write("LOAD DATA LOCAL INFILE 'evaluations.csv' INTO TABLE evaluations CHARACTER SET UTF8 IGNORE 1 LINES;\n")
  sql.write("CREATE INDEX adresse_index ON evaluations (adresse);\n")
  sql.write("CREATE INDEX proprietaire_index ON evaluations (proprietaire);\n")
  sql.write("CREATE INDEX arrondissement_index ON evaluations (arrondissement);\n")
  sql.write("CREATE INDEX arrondissement_no_index ON evaluations (arrondissement_no);\n")
  sql.write("CREATE INDEX type_lot_index ON evaluations (type_lot);\n")
  sql.write("CREATE INDEX uef_id_index ON evaluations (uef_id);\n")
end

db = DBM.open('address')
File.open("evaluations.csv", 'w:UTF-8') do |csv|
  csv.write(columns.map{|c|c.keys}.join("\t"))
  csv.write("\n")
  db.each_entry do |address_id, page_content|
    page_content.force_encoding('utf-8')
    page = Nokogiri::HTML::Document.parse(page_content, encoding='UTF-8')
    data = page.css("//td").map {|td| td.content.gsub(/\s+/, " ").strip}
    data = data.each_with_index.map { |cell,index|
      type = columns[index].values if columns[index]
      type == :s ? cell : cell.gsub(',','')
    }
    data.unshift(address_id)
    csv.write(data.join("\t"))
    csv.write("\n")
  end
end
db.close

