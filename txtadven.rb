#!/usr/bin/env ruby

require 'yaml'

class Character
    def change_name
        puts "Character name? => " #input text
        @name = gets.chomp #get input

        $charinfo[:name] = @name #Modify
        File.open('characters.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
        puts "Hello #{@name}" #show to player the name
    end
    def inventory
        puts "Inventory:"
        $charinfo.each do |key, value|
            if key.to_s() == "items"
                value.each do |k, v|
                    puts "#{k}"
                end
            end
        end
    end
    def examine
        puts "Which Item? "
        item = gets.chomp
        gotitem = false
        $charinfo.each do |key, value|
            if key.to_s() == "items"
                value.each do |v|
                    gotitem = true if item == v
                end
            end
        end
        if gotitem == true
            $items.each do |key, value|
                if value[:name] == item
                    puts "#{value[:name]} is type #{value[:type]} and it:\n #{value[:use]}"
                end
            end
        elsif gotitem == false
            puts "You cannot examine an item you do not have"
        end
    end
end

class Room
    def move(dir)
        goingto = ""
        breakk = false
        cango = "maybe"
        $roominfo.each do |key, value|
            if key == $general_info["current_room"]
                value[:in?] = false
                value[:exits].each do |k, v|
                    if v == dir 
                        goingto = k
                        puts "You go #{dir}"
                        cango = "true"
                        break
                    end
                    cango = "false"
                end
                breakk = true
                $roominfo.each do |k, v|
                    v.each do |ke, val|
                        if ke.to_s() == "name" 
                            if val.to_s() == goingto.to_s()
                                v[:in?] = true
                                $general_info["current_room"] = k
                                File.open('general_info.yaml', 'w') {|f| f.write @general_info.to_yaml } 
                            end
                        end
                    end
                end
            end
            break if breakk == true      
        end
        puts "You cannot go in this direction" if cango == "false"
    end
    def room_in_desc
        roominfo = $roominfo
        roominfo.each do |key, value|
            if key == $general_info["current_room"]
                puts "You are in the #{value[:name]}"
                value['items'].each {|k| puts "Items in room: #{k}"} unless value['items'] == nil
                value['npcs'].each {|k| puts "Npcs in room: #{k}"} unless value['npcs'] == nil 
                value[:exits].each do |k, v|
                    puts "There is the #{k} to the #{v}"
                end
            end
        end
    end
end

class Game
    def initialize
        @character
        @room
        @quit = false
        $roominfo
        $general_info
        $charinfo
        $items
        $npcs
        @savegame
    end
    def init_game
        puts "New Game or Load Game? (NEW / LOAD) => "
        gametype = gets.chomp
        if gametype.upcase == "NEW" #loads new info for the yml for new game
            $charinfo = YAML::load_file('defaultchar.yaml')
            $general_info = YAML::load_file('generaldefault.yaml')
            $roominfo = YAML::load_file('roomdefault.yaml')
            $items = YAML::load_file('itemlist.yaml')
            $npcs = YAML::load_file('npclist.yaml')
            @character = Character.new
            @character.change_name()
            @room = Room.new
            true
        elsif gametype.upcase == "LOAD" #does the same thing as NEW but different file
            @savegame = YAML::load(File.open('savegame.yaml'))
            $items = YAML::load_file('itemlist.yaml')
            $npcs = YAML::load_file('npclist.yaml')
            count = 1
            @savegame.each do |key, value|
                #puts key
                if count == 1
                    $charinfo = key 
                elsif count == 2
                    $roominfo = key
                elsif count == 3
                    $general_info = key
                end
                count += 1
            end
            @character = Character.new
            @room = Room.new
            false
        else
            puts ""
            puts "Invalid Input Option"
            puts "Quitting!"
            abort
        end
    end
    def game_loop
        while true do
            command_test()
            abort if @quit == true
        end
    end
    def command_test()
        print "=> "
        begin
            command = gets.chomp.upcase
        rescue Exception => e
            puts "\nQuitting... #{e.message}"
            abort
        end
        commands() if command == "COMMAND"
        save_game() if command == "SAVE"
        load_game() if command == "LOAD"
        @room.room_in_desc() if command == "ROOM"
        @room.pickup() if command == "PICKUP"
        @room.putdown() if command == "PUTDOWN"
        @room.move("NORTH") if command == "NORTH" 
        @room.move("SOUTH") if command == "SOUTH"
        @room.move("EAST") if command == "EAST"
        @room.move("WEST") if command == "WEST"
        @character.inventory() if command == "INVENTORY" or command == "INV"
        @character.examine() if command == "EXAMINE" or command == "EXAM"
        @character.equip() if command == "EQUIP" or command == "EQ" 
        @quit = true if command == "QUIT" 
    end
    def save_game
        data = $charinfo, $roominfo, $general_info
        File.open('savegame.yaml', 'w') {|f| f.write data.to_yaml } 
        @savegame = YAML::load(File.open('savegame.yaml'))
        puts "SAVED GAME!"
        #@savegame.each do |key, value|
        #    puts "#{key} #{value}"
        #    puts ""
        #end
    end
    def load_game 
        puts "\nYou travel back to your last save...\n\n"
        @savegame = YAML::load(File.open('savegame.yaml'))
        count = 1
        @savegame.each do |key, value|
            #puts key
            if count == 1
                $charinfo = key 
            elsif count == 2
                $roominfo = key
            elsif count == 3
                $general_info = key
            end
            count += 1
        end
    end
    def tutorial
        puts "\n\n To control your game you have to use commands to navigate"
        puts "through the area and to interact with things and find out more"
        puts "about your surroundings"
        
        puts "\n The first commands you will be taught is "
    end
    def start_game
        puts "You wake up in an empty room"
        puts "#{$charinfo['name']} => Where am I?"
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
option = game.init_game()
if option == true
    game.start_game 
elsif option == false
    puts "\nYou wake up back where you were...\n\n"
    game.game_loop
end
