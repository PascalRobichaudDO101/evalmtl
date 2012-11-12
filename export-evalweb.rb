#!/usr/bin/ruby
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'

# TODO unify the array and the hash (order is important)
columns = ['id', 'adresse', 'ville', 'proprietaire', 'arrondissement', 'arrondissement_no',
  'matricule', 'compte', 'uef_id', 'cubf', 'nb_logements', 'voisinage',
  'emplacement_front', 'emplacemment_profondeur', 'emplacement_superficie',
  'classe_non_residentielle', 'classe_industrielle', 'terrain_vague',
  'annee_construction', 'nb_etages', 'nb_autres_locaux',
  'annee_role_anterieur', 'terrain_role_anterieur', 'batiment_role_anterieur', 'immeuble_role_anterieur', 'vide',
  'loi', 'article', 'alinea', 'valeur_terrain', 'valeur_batiment', 'valeur_immeuble',
  'code_imposition', 'code_exemption', 'maj',
  'no_lot_renove', 'paroisse', 'lot', 'subd', 'type_lot', 'superficie', 'front', 'profond']
column_types = { 'id' => :i,
  'adresse' => :s, 'ville' => :s, 'proprietaire' => :s, 'arrondissement' => :s, 'arrondissement_no' => :i,
  'matricule' => :s, 'compte' => :i, 'uef_id' => :i, 'cubf' => :i, 'nb_logements' => :i, 'voisinage' => :i,
  'emplacement_front' => :i, 'emplacemment_profondeur' => :i, 'emplacement_superficie' => :i,
  'classe_non_residentielle' => :i, 'classe_industrielle' => :s, 'terrain_vague' => :s,
  'annee_construction' => :i, 'nb_etages' => :i, 'nb_autres_locaux' => :i,
  'annee_role_anterieur' => :i, 'terrain_role_anterieur' => :i, 'batiment_role_anterieur' => :i, 'immeuble_role_anterieur' => :i, 'vide' => :s,
  'loi' => :s, 'article' => :s, 'alinea' => :s, 'valeur_terrain' => :i, 'valeur_batiment' => :i, 'valeur_immeuble' => :i,
  'code_imposition' => :s, 'code_exemption' => :s, 'maj' => :s,
  'no_lot_renove' => :i, 'paroisse' => :s, 'lot' => :s, 'subd' => :s,
  'type_lot' => :s, 'superficie' => :f, 'front' => :f, 'profond' => :f}

File.open("evaluations.sql", 'w') do |sql|
  sql.write("create database registre_foncier_montreal;\n")
  sql.write("use registre_foncier_montreal\n")
  sql_types = {:s => "varchar(255)", :i => "integer", :f => "float"}
  sql.write("create table evaluations (\n" + columns.map{|col| t=sql_types[column_types[col]] ; "  #{col} #{t}"}.join(",\n") + "\n) ENGINE=InnoDB;\n")
  sql.write("LOAD DATA LOCAL INFILE 'evaluations.csv' INTO TABLE evaluations;\n")
  sql.write("CREATE INDEX proprietaire_index ON address (proprietaire);")
  sql.write("CREATE INDEX arrondissement_index ON address (arrondissement);")
  sql.write("CREATE INDEX arrondissement_no_index ON address (arrondissement_no);")
  sql.write("CREATE INDEX type_lot_index ON address (type_lot);")
  sql.write("CREATE INDEX uef_id_index ON address (uef_id);")
end

File.open("evaluations.csv", 'w') do |f|
  f.write(columns.join("\t"))
  f.write("\n")
  Dir.glob("cache/address/**").reject {|v| v =~ /^\./}.each do |path|
    address_id = File.basename(path)
    content = File.open(path, 'rb') { |fr| fr.read }
    page = Nokogiri::HTML::Document.parse(content)
    data = page.css("//td").map {|td| td.content.gsub(/\s+/, " ").strip}
    data = data.each_with_index.map { |cell,index|
      type = column_types[columns[index]]
      type == :s ? cell : cell.gsub(',','')
    }
    data.push(address_id)
    f.write(data.join("\t"))
    f.write("\n")
  end
end

