#
# Lovelace – an Intelligent Battleship Bot
# Created by Mia Ngo (August 2nd, 2018)
#
require 'httparty'
require 'json'

class Board 
    def initialize(board)
        @board = board
    end

    def value_at(c, n) 
        @board[n.to_i][c.ord - 'A'.ord]
    end

    def is_valid(c, n) 
        !(n.to_i > 9 || n.to_i < 0 || c.ord > "J".ord || 
        c.ord < "A".ord || value_at(c, n) == "O" || value_at(c, n) == "X")
    end

    def rand_pos
        char = "#{rand(65..74).chr}"
        num = "#{rand(9)}"
        cur = value_at(char, num)
        while cur == "O" || cur == "X" do
            char = "#{rand(65..74).chr}"
            num = "#{rand(9)}"
            cur = value_at(char, num)
        end
        char + num
    end

    def targeted_pos(c, n)
        return top(c,n) || bottom(c,n) || left(c,n) || right(c,n)
    end

    def top(c, n)
       return nil unless is_valid(c, n.to_i-1)
       c + "#{n.to_i-1}"
    end

    def bottom(c, n)
        return nil unless is_valid(c, n.to_i+1)
        c + "#{n.to_i+1}"
     end

     def left(c, n)
        return nil unless is_valid((c.ord-1).chr, n)
        (c.ord-1).chr + n
     end

     def right(c, n)
        return nil unless is_valid((c.ord+1).chr, n)
        (c.ord+1).chr + n
     end
end

class Lovelace
    def initialize(game_id) 
        @game_id = game_id
        @state = :rand
    end

    def join_game
        response = HTTParty.post("http://battleship.inseng.net/games/#{@game_id}/players", 
            body: generate_init_state)
            
        # Use the POST request below to play with an automatic bot
        # response = HTTParty.post("http://battleship.inseng.net/games/#{@game_id}/players?match=1", 
        #     body: generate_init_state)

        @token = JSON.parse(response.body).dig('currentPlayer', 'token')
        @board = Board.new JSON.parse(response.body)['board']
    end

    def make_move
        header = {
            'X-Token' => @token
        }
        pos = if (@state == :hit) 
            target = @board.targeted_pos(@prev_hit[0], @prev_hit[1])
            if !target
                @state = :rand
                @board.rand_pos
            else
                target
            end
        else
            @board.rand_pos
        end

        response = HTTParty.post("http://battleship.inseng.net/games/#{@game_id}/moves", 
        body: {"position" => pos},
        headers: header)
        @board = Board.new JSON.parse(response.body)['board']
     
        if (@board.value_at(pos[0], pos[1]) == "X") 
            @state = :hit
            @prev_hit = pos
        end
    end

    def generate_init_state
        {
            "name" => "SmarterLovelace",
            "carrier" => {
              "position" => "A1",
              "direction" => "DOWN"
            },
            "battleship" => {
              "position" => "C5",
              "direction" => "DOWN"
            },
            "cruiser" => {
              "position" => "G3",
              "direction" => "DOWN"
            },
            "destroyer" => {
              "position" => "E7",
              "direction" => "DOWN"
            },
            "submarine" => {
              "position" => "J8",
              "direction" => "DOWN"
            }
        }
    end
end

response = HTTParty.post('http://battleship.inseng.net/games')
id = JSON.parse(response.body)['id']
puts id

lovelace = Lovelace.new id
lovelace.join_game

while true do 
    lovelace.make_move
end
