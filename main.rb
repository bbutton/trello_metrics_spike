require 'orchestrate'
require 'trello'
require 'JSON'

class Main
  def run
    Trello.configure do |config|
      config.developer_public_key =  ENV[TRELLO_DEV_KEY] # The "key" from step 1
      config.member_token =  ENV[TRELLO_TOKEN]
      # The token from step 3.
    end

    boards = Trello::Board.all
    object_storage_board = boards.select { |b| b.name == "Object Storage"}[0]
    lists = object_storage_board.lists.select { |l| l.closed == false}
    cards = object_storage_board.cards.select { |c| c.closed == false}

    board_dict = {:id => object_storage_board.id,
              :trello_type => "board",
              :name => object_storage_board.name,
              :sorted_lists => get_list_data(lists),
    }

    cards_dict = get_card_data cards
    card_actions = get_card_action_data cards

    puts("Data gotten, slamming it into Orchestrate")

    app = Orchestrate::Application.new(ENV[ORCHESTRATE_API_KEY], "https://api.ctl-uc1-a.orchestrate.io/")
    trello_data = app[:TrelloData]

    trello_data.set(board_dict[:id], board_dict)

    cards_dict.each { |c|
      card_id = c[:id]
      puts("adding card data for #{c[:id]}:#{c[:name]}")
      trello_data.set(c[:id], c)
    }

    card_actions.each_pair { |action_key, action_value|
      card_obj = trello_data[action_key]

      action_value.each { |action_data|
        puts("adding card actions to #{action_data[:card_id]}:#{action_data[:id]}")
        trello_date = action_data[:date]
        ruby_date = DateTime.parse(trello_date.to_s)
        iso_8601_date = ruby_date.iso8601

        card_obj.events[:card_actions][iso_8601_date] << action_data
      }
    }

    puts("Data be slammed")
  end

  def get_list_data lists
    lists.sort{ |l1, l2| l1.pos <=> l2.pos }.collect { |l| {:id => l.id, :name => l.name}}
  end

  def get_card_data cards
    cards.collect{ |c|
      {
          :id => c.id, :trello_type => "card", :board_id => c.board_id, :name => c.name, :desc => c.desc, :list_id => c.list_id,
          :pos => c.pos, :last_activity_date => c.last_activity_date, :labels => c.card_labels
      }
    }
  end

  def get_card_action_data cards
    card_actions = {}
    cards.each { |c|
      card_actions[c.id] = get_card_actions(c.actions, c.id)
    }
    card_actions
  end

  def get_card_actions actions, card_id
    actions.sort{|a1, a2| a1.date <=> a2.date}.collect { |a|
      {
          :id => a.id, :type => a.type, :card_id => card_id, :data => a.data, :date => a.date
      }
    }
  end
end

us = Main.new
us.run
