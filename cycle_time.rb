require 'orchestrate'
require 'JSON'

class CycleTimeGenerator
  def run
    app = Orchestrate::Application.new(ENV[ORCHESTRATE_API_KEY], "https://api.ctl-uc1-a.orchestrate.io/")
    trello_data = app[:TrelloData]

    workingActions = trello_data.search('listAfter.name:Working AND date:[2015-04-01 TO 2015-04-30]').order(:card_id, :asc, :date, :desc, ).kinds('event').find
    completeActions = trello_data.search('listAfter.name:Complete AND date:[2015-04-01 TO 2015-04-30]').order(:card_id, :asc, :date, :asc, ).kinds('event').find

    working_stuff = workingActions.collect { |score, event| event}
    complete_stuff = completeActions.collect { |score, event| event}

    working = to_hash(working_stuff)
    complete = to_hash(complete_stuff)
    puts "working actions count is #{working.keys.length}"
    puts "complete actions count is #{complete.keys.length}"

    puts "working elements: "
    working.each_key { |key| puts working[key].value }

    puts
    puts "complete elements: "
    complete.each_key { |key| puts complete[key].value }



    working.each_key do |key|
      start_date = working[key][:date]
      if complete.has_key? key then
        end_date = complete[key][:date] unless complete.has_key?(key)

        puts "#{key} start: #{start_date} - #{end_date}"
      end
    end

    # puts "********** Working"
    # workingActions_no_score.each { |event| puts "#{event.value}" }
    #
    # puts
    # puts "********** Complete"
    # completeActions.each{ |score, event| puts "#{event.value}"}

  end

  def to_hash my_array
    hash = {}
    my_array.each{ |element| hash[element[:card_id]] = element}
    hash
  end
end

ctg = CycleTimeGenerator.new
ctg.run

