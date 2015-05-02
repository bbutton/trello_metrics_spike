require 'orchestrate'
require 'trello'
require 'JSON'

class Main
  def run
    Trello.configure do |config|
      config.developer_public_key =  "XXXX" # The "key" from step 1
      config.member_token =  "XXXX"
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

    app = Orchestrate::Application.new("XXXX", "https://api.ctl-uc1-a.orchestrate.io/")
    trello_data = app[:TrelloData]
    trello_data.set(board_dict[:id], board_dict)
    cards_dict.each { |c|
      card_id = c[:id]
      puts("adding card data for #{c[:name]}")
      trello_data.set(c[:id], c)

      action_events = trello_data["ActionEvents"]
      card_actions.each{ |a| action_events.events["event_data_" + card_id] << a}
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
    cards.each { |c|
      actions = get_card_actions(c.actions)
    }
  end

  def get_card_actions actions
    actions.sort{|a1, a2| a1.date <=> a2.date}.collect { |a|
      {
          :id => a.id, :type => a.type, :data => a.data, :date => a.date
      }
    }
  end
end

us = Main.new
us.run
