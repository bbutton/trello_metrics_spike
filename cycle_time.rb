require 'orchestrate'
require 'JSON'

class CycleTimeGenerator
  def run board_id
    app = Orchestrate::Application.new(ENV["ORCHESTRATE_API_KEY"], ENV["ORCHESTRATE_ENDPOINT"])
    trello_data = app[:TrelloData]

    #board_id = '53fb794a72ab28b254f3f471'
    #complete_actions = trello_data.search('listAfter.name:(Complete or Completed) AND date:[2015-06-01 TO 2015-08-01]').order(:card_id, :asc, :date, :asc, ).kinds('event').find
    complete_actions = trello_data.search("board.id:#{board_id} AND listAfter.name:(`Complete` or `Completed`)").order(:card_id, :asc, :date, :asc, ).kinds('event').find
    #puts "data"
    #complete_actions.each{ |action| puts action.to_s }
    #puts

    results = []
    complete_actions.each do |score, complete_action|
      card_id = complete_action[:card_id]
      if complete_action["data"] != nil then
        puts "complete_action nil" if complete_action == nil
        puts "data nil" if complete_action["data"] == nil
        puts "card nil" if complete_action["data"]["card"] == nil
        puts "name nil" if complete_action["data"]["card"]["name"] == nil

        card_name = complete_action["data"]["card"]["name"]
        complete_date = complete_action["date"]

        working_actions = trello_data.search('(listAfter.name:`Working` AND listBefore.name:`Ready for Work`) AND card_id:' + card_id).order(:card_id, :asc, :date, :asc, ).kinds('event').find
        #puts "Dumping raw data"
        #working_actions.each { |action| puts action.to_s }

        start_date = nil
        working_actions.each do |ignore, working_action|
          start_date = working_action["date"]
        end

        if(start_date != nil) then
          sd = DateTime.parse(start_date)
          ed = DateTime.parse(complete_date)

          cycle_time = week_days_between(sd, ed)

          results << {card_name: card_name, sd: sd, ed: ed, cycle_time: cycle_time}
        end
      end
    end
    results

  end

  def week_days_between start_date, end_date
    r = Range.new(start_date, end_date)
    r.select{|day| (day.saturday? || day.sunday?) == false}.size
  end

  def to_hash my_array
    hash = {}
    my_array.each{ |element| hash[element[:card_id]] = element}
    hash
  end

  def date_to_ymd input_date
    input_date.to_date.to_s
  end

  def print_report results
    puts "Name\tstart_date\tend_date\tcycle_time"
    results.each do |result|
      puts "#{result[:card_name]}\t#{date_to_ymd(result[:sd])}\t#{date_to_ymd(result[:ed])}\t#{result[:cycle_time]}"
      #puts "#{date_to_ymd(result[:ed])}\t#{date_to_ymd(result[:sd])}\t\t\t#{result[:card_name]}"
    end
  end
end

ctg = CycleTimeGenerator.new
results = ctg.run(ARGV[0])
ctg.print_report(results)

