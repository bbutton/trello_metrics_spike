require 'orchestrate'
require 'JSON'

class BoardCleaner
  def run board_id
    app = Orchestrate::Application.new(ENV["ORCHESTRATE_API_KEY"], ENV["ORCHESTRATE_ENDPOINT"])
    trello_data = app[ENV["ORCHESTRATE_COLLECTION"]]

    query_string = "value.data.board.id:#{board_id}"

    complete_actions = trello_data.search("#{query_string}").order(:card_id, :asc, :date, :asc, ).kinds('event').find

    action_ids = []
    complete_actions.each do |score, action|
      action_ids << {key: action["card_id"], type: "card_actions", timestamp: nil, ordinal: action.ordinal}
    end
    action_ids.uniq!

    action_ids.each do |a|
      trello_data.purge_event("TrelloData", a[:key], a[:type], a[:timestamp], a[:ordinal])
    end
  end
end

board_cleaner = BoardCleaner.new
board_cleaner.run ARGV[0]