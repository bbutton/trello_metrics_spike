require 'orchestrate'
require 'JSON'

class DataDumper
  def run board_id, start_date, end_date
    app = Orchestrate::Application.new(ENV["ORCHESTRATE_API_KEY"], ENV["ORCHESTRATE_ENDPOINT"])
    trello_data = app[ENV["ORCHESTRATE_COLLECTION"]]

    query_string = build_query_string(board_id, start_date, end_date)

    complete_actions = trello_data.search("#{query_string}").order(:card_id, :asc, :date, :asc, ).kinds('event').find

    complete_actions.each do |score, action|
      card_id = action[:card_id]
      card_type = action[:type]
      card_date = action[:date]

      case card_type
        when "createCard"
          puts
          puts "#{card_id}: #{card_date} -> created #{action["data"]["card"]["name"]} "
        when "copyCard"
          puts
          puts "#{card_id}: #{card_date} -> copied #{action["data"]["card"]["name"]} "
        when "updateCard"
          if action["data"]["listAfter"] != nil then
            puts "\t#{card_id}: #{card_date} -> moved from #{action["data"]["listBefore"]["name"]} to #{action["data"]["listAfter"]["name"]} "
            if action["data"]["listAfter"]["name"].equal?("Complete") then
              puts
            end
          end
        when "addLabelToCard"
          puts "\t#{card_id}: #{card_date} -> added label #{action["data"]["label"]["name"]}"
        when "moveCardToBoard"
          puts "\t#{card_id}: #{card_date} -> moved to this board from #{action["data"]["board_source"]["name"]}"
      end
    end
  end

  def build_query_string(board_id, start_date, end_date)
    query_string = "board.id:#{board_id}"
    if(start_date != nil && end_date != nil) then
      query_string = query_string + " AND date:[#{start_date} TO #{end_date}]"
    end

    query_string
  end
end

data_dumper = DataDumper.new
data_dumper.run ARGV[0], ARGV[1], ARGV[2]