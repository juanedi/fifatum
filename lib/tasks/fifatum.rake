namespace :fifatum do
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
