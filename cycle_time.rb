require 'orchestrate'
require 'JSON'

class CycleTimeGenerator
  def run
    app = Orchestrate::Application.new(ENV["ORCHESTRATE_API_KEY"], "https://api.ctl-uc1-a.orchestrate.io/")
    trello_data = app[:TrelloData]

    complete_actions = trello_data.search('listAfter.name:(Complete or Completed) AND date:[2015-04-01 TO 2015-04-31]').order(:card_id, :asc, :date, :asc, ).kinds('event').find

    results = []
    complete_actions.each do |score, complete_action|
      card_id = complete_action[:card_id]
      card_name = complete_action["data"]["card"]["name"]
      complete_date = complete_action["date"]

      working_actions = trello_data.search('(listAfter.name:"Working" OR listBefore.name:"Ready for Work") AND card_id:' + card_id).order(:card_id, :asc, :date, :asc, ).kinds('event').find

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

  def print_report results
    puts "Name\tstart_date\tend_date\tcycle_time"
    results.each do |result|
      puts "#{result[:card_name]}\t#{result[:sd]}\t#{result[:ed]}\t#{result[:cycle_time]}"
    end
  end
end

ctg = CycleTimeGenerator.new
results = ctg.run
ctg.print_report(results)

