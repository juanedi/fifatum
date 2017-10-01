require "teams/import"
require "teams/scrappers/fifa17"

namespace :fifatum do
  namespace :fifa17 do
    task :download do
      Teams::Scrappers::Fifa17.run
    end

    task :import => :environment do
      Teams::Import.import_fifa_17_teams
    end
  end
end
