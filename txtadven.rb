#!/usr/bin/env ruby

require 'yaml'

class Character
    attr_accessor :charinfo
    def initialize(charinfo)
        @charinfo = charinfo #character yaml file
    end
    def change_name
        puts "Character name? => " #input text
        @name = gets.chomp #get input

        @charinfo['name'] = @name #Modify
        File.open('characters.yaml', 'w') {|f| f.write @charinfo.to_yaml } 
        puts "Hello #{@name}" #show to player the name
    end
    def inventory
        puts "Inventory:"
        for item in @charinfo['items'] 
            puts "#{item['name']}"
        end
    end
end

class Room
    def initialize(roominfo=default_room_info())
        @roominfo = roominfo
    end
    def default_room_info
        data = {
            1 => {:name => "Starting Room", :items => {"Starting Sword" => {:type => "Weapon"}}, :npcs => "NONE", :exits => {"Hallway" => "NORTH"}, :in? => true},
            2 => {:name => "Hallway", :items => {"Potion" => {:type => "Consumable"}}, :npcs => "Goblin", :exits => ["NORTH", "WEST"], :in? => false}
        }
        File.open("roominfo.yml", "w") {|f| f.write(data.to_yaml) }
        return data
    end
    def move(dir)
        for i in @roominfo

    end
end

class Game
    def initialize
        @character
        @room
        @quit = false
    end
    def init_game
        puts "New Game or Load Game? (NEW / LOAD) => "
        gametype = gets.chomp
        if gametype.upcase == "NEW" #creates new info for the yml for new game
            data = {"name" => "NAME", "health" => "100", "items" => {"name" => "Flashlight"}}
            File.open("characters.yaml", "w") {|f| f.write(data.to_yaml) }
            charinfo = YAML::load_file('characters.yaml')
            @character = Character.new(charinfo)
            @character.change_name()
            @room = Room.new
        elsif gametype == "LOAD" #does the same thing as NEW but puts past data by loading
            begin
                charinfo = YAML::load(File.open('characters.yaml')) 
            rescue ArgumentError => e #just in case
                  puts "Could not parse CHARACTER YAML: #{e.message}"
            end
            @character = Character.new(charinfo)

            begin 
                roominfo = YAML::load(File.open('roominfo.yml'))
            rescue ArgumentError => e
                puts "Could not parse ROOM YAML: #{e.message}"
            end
            @room = Room.new(roominfo)
        end
    end
    def game_loop
        while true do
            command_test()
            quit if @quit == true
        end
    end
    def command_test()
        print "=> "
        command = gets.chomp
        save_game() if command.upcase == "SAVE"
        load_game() if command.upcase == "LOAD"
        @room.move("NORTH") if command.upcase == "NORTH" 
        @room.move("SOUTH") if command.upcase == "SOUTH"
        @room.move("EAST") if command.upcase == "EAST"
        @room.move("WEST") if command.upcase == "WEST"
        @character.inventory() if command.upcase == "INVENTORY"
        if command.upcase == "EXAMINE"
            puts "Which item? "
            item = gets.chomp
            @character.examine(item.lowercase) 
        end
        @quit = true if command.upcase = "QUIT" 
    end
    def start_game
        puts "You wake up in an empty room"
        puts "#{@character.charinfo['name']} => Where am I?"
        puts "You see a door to the north of the room"
        puts "Would you like a tutorial? (Y/n) "
        tut = gets.chomp
        if tut.upcase == "Y"
            puts "Running tutorial..."
            tutorial()
            game_loop()
        elsif tut.upcase == "N"
            puts "Ok!"
            game_loop()
        end
    end
end

game = Game.new
game.init_game()
game.start_game
end 
