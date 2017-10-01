require "open-uri"

module Teams
  module Scrappers
    module Fifa17
      TEAMS_URL = "https://www.easports.com/fifa/news/2016/fifa-17-leagues-and-teams"

      extend self

      def run
        # TODO: use tmp file for this?
        source_html = Rails.root.join("data", "teams.html")

        if File.exists? source_html
          puts "Using pre-existing source file: #{source_html}"
        else
          puts "Downloading source HTML..."
          open(source_html, 'wb') do |file|
            file << open(TEAMS_URL).read
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

        open(Import::FIFA17_DATA_FILE, 'wb') do |file|
          file << JSON.pretty_generate(result)
        end

        puts "Done!"
      end
    end
  end
end
