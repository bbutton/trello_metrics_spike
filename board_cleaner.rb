require 'orchestrate'
require 'JSON'

class BoardCleaner
  def initialize
    @client = Orchestrate::Client.new(ENV["ORCHESTRATE_API_KEY"], ENV["ORCHESTRATE_ENDPOINT"])
  end

  def run board_id
    complete_results = []
    offset = 0
    begin
      results = do_search(board_id, offset)
      complete_results.concat(results)
      offset += 100
    end until results.count == 0

    puts "Found #{complete_results.count()} results"

    action_ids = []
    complete_results.each do |action|
      action_ids << {key: action["path"]["key"], type: "card_actions", timestamp: action["path"]["timestamp"], ordinal: action["path"]["ordinal"]}
    end
    action_ids.uniq!

    puts "Translates to #{action_ids.count()} unique ids to delete"

    counter = 0
    action_ids.each do |a|
      @client.purge_event("TrelloData", a[:key], a[:type], a[:timestamp], a[:ordinal])
      counter += 1
      puts "#{counter}" if counter % 50 == 1
    end

    puts "Complete. All events deleted"
  end

  def do_search board_id, offset
    query_string = "value.data.board.id:#{board_id}"
    params = {
        sort: 'card_id:asc, date:asc',
        limit: 100,
        offset: offset
    }
    complete_actions = @client.search(:TrelloData, "@path.kind:event AND #{query_string}", params)
    complete_actions.results
  end

end

board_cleaner = BoardCleaner.new
puts "running event cleanup for board id: #{ARGV[0]}"
board_cleaner.run ARGV[0]