namespace :fifatum do
  task :download do
    teams_url = "https://www.easports.com/fifa/news/2016/fifa-17-leagues-and-teams"

    source_html = Rails.root.join("data", "teams.html")
    output_json = Rails.root.join("data", "teams.json")

    if File.exists? source_html
      puts "Using pre-existing source file: #{source_html}"
    else
      puts "Downloading source HTML..."
      open(source_html, 'wb') do |file|
        file << open(teams_url).read
      end
    end

    puts "Parsing HTML..."
    doc = File.open(source_html) { |f| Nokogiri::HTML(f) }
    league_nodes = doc.css(".article-detail .eas-b2 h3")

    result = {}

    league_nodes.each do |league_node|
      league = league_node.text

      result[league] = league_node
                         .next_element
                         .css("p")
                         .map { |content| content.text.strip }
                         .select { |s| !s.blank? }
    end

    open(output_json, 'wb') do |file|
      file << JSON.pretty_generate(result)
    end

    puts "Done!"
  end

  task :import => :environment do
    data_file = Rails.root.join("data", "teams.json")

    if !File.exists? data_file
      puts "File #{data_file} does not exist. Perhaps you need to run the scraper."
      exit 1
    end

    data = JSON.parse(File.read(data_file))

    data.each do |league_name, team_names|
      puts "Importing league: #{league_name}"
      league = League.create(name: league_name)

      team_names.each do |team_name|
        puts "\t Importing team: #{team_name}"
        league.teams.create(name: team_name)
      end

      puts
    end

    puts "Done!"
  end
end
