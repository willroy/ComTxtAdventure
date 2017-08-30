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
    def equip
        puts "Which item? "
        item = gets.chomp
        ininv = false
		$charinfo["items"].each {|k| ininv = true if k == item}
		$charinfo["items"].delete(item) if ininv == true
		$charinfo["equiped"] = item if $charinfo["equiped"] == nil and ininv == true
    end
    def unequip
        equipped = ""
		if $charinfo == nil
			puts "You have nothing to unequip"
		else
			equipped = $charinfo["equiped"]
			$charinfo["equiped"] = nil
			$charinfo["items"] << equipped
		end
    end
    def inventory
        puts "Inventory:"
		$charinfo["items"].each {|k| puts k}
        puts "Equipped:"
		puts $charinfo["equiped"]
    end
    def intoinv(item)
		$charinfo["items"] << item
    end
    def putdown(item)
		return true if $charinfo["items"].each {|k| $charinfo["items"].delete(item) if k == item}
    end
    def examine
        puts "Which Item? "
        item = gets.chomp
        gotitem = false
		$charinfo["items"].each {|v| gotitem = true if item == v}
		gotitem = true if item == $charinfo["equiped"]
        if gotitem == true 
			$items.each do |key, value|
				puts "#{value[:name]} is type #{value[:type]} and it:\n #{value[:use]}" if value[:name] == item
			end
        elsif gotitem == false
            puts "You cannot examine an item you do not have"
        end
    end
end

class Room
    def move(dir)
        goingto = ""
        cango = "maybe"
		$roominfo[$general_info["current_room"]][:in?] = false
		$roominfo[$general_info["current_room"]][:exits].each do |k, v|
			if v == dir 
				goingto = k
				cango = true
				break
			end
			cango = false
		end
		$roominfo.each do |k, v|
			v.each do |ke, val|
				if ke.to_s() == "name" 
					if val.to_s() == goingto.to_s()
						v[:in?] = true
						$general_info["current_room"] = k
					end
				end
			end
        end
        puts "You cannot go in this direction" if cango == false
		puts "You go #{dir}" if cango == true
    end
    def room_in_desc
		puts "You are in the #{$roominfo[$general_info["current_room"]][:name]}"
		puts "Items in room: "
		$roominfo[$general_info["current_room"]]["items"].each {|k| puts k}
		puts "Npcs in room: "
		$roominfo[$general_info["current_room"]].fetch("npcs", {}).each do |k, v| 
			puts v[:name]
		end
		$roominfo[$general_info["current_room"]][:exits].each {|k, v| puts "There is the #{k} to the #{v}"}
    end
    def pickup(item)
		items = $roominfo[$general_info["current_room"]]["items"]
		exists = items.include? item
		if exists
			items.delete item
		end
		exists
    end
    def putinroom(item)
		$roominfo[$general_info["current_room"]]["items"] << item
    end
end

class Game
    def initialize
        @character
        @room
        @quit = false
		@battle = false
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

            File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
            File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
			File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
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
			File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
			File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
        	File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
            abort if @quit == true
        end
    end
	def battle_loop
		puts "Enemy to battle: "
		enemy = gets.chomp
		running = false
		enemyid = nil
		if $roominfo[$general_info["current_room"]]["npcs"] == nil
			puts "No enemies in this room"
			return "no_enemy"
		end
		$roominfo[$general_info["current_room"]]["npcs"].each do |key, value|
			if value[:name] == enemy
				puts "You engage in battle with #{enemy}"
				enemyid = key
				running = true
			end
		end	
		if running == false
			puts "No #{enemy} in this room"
		end
		while running == true do 
			File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
			File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
			File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
			print "=> "
			begin
				command = gets.chomp.upcase
			rescue Exception => e
				puts "\nQuitting... #{e.message}"
				abort
			end
			commandbattle() if command == "COMMAND"
			attack() if command == "ATTACK"
			block() if command == "BLOCK"
			use() if command == "USE"
			killenemy(enemyid) if command == "KE"
			killchar() if command == "KC"
			@character.inventory() if command == "INVENTORY" or command == "INV"
			if  $roominfo[$general_info["current_room"]]["npcs"][enemyid][:health] <= 0
				$roominfo[$general_info["current_room"]]["npcs"].delete(enemyid)
				return true
			end
		   	return false if $charinfo[:health].to_i() <= 0 
		end
	end
	def killenemy(enemyid)
		$roominfo[$general_info["current_room"]]["npcs"][enemyid][:health] = 0
		puts "DONE"
	end
	def killchar
		$charinfo[:health] = 0
		puts "DONE"
	end
	def attack
		
	end
	def block
	
	end
	def use
		puts "Which item? "
        item = gets.chomp
		itemid = nil
        ininv = false
		usable = false
		$charinfo["items"].each {|k| ininv = true if k == item}
		$items.each {|k, v| itemid = k if v[:name] == item}
		usable = true if $items[itemid][:type] == "consumable"
		puts "Usable? #{usable} InInv? #{ininv} ItemID: #{itemid}"
	end
	def restorehealth
		$charinfo[:health] = 100
	end
    def command_test
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
		restorehealth() if command == "RH"
		if command == "BATTLE"
			value = battle_loop()
			if value == false
				died()
			elsif value == true
				puts "You beat the enemy!"
			else

			end
		end
        if command == "PICKUP"
            puts "Which Item? "
            item = gets.chomp
            if @room.pickup(item) == true
                puts "You put #{item} into your inventory."
                @character.intoinv(item)
            else
                puts "There is no #{item} in this room"
            end
        end
        if command == "PUTDOWN"
            puts "Which Item? "
            item = gets.chomp
            if @character.putdown(item) == true 
                puts "You put the #{item} down in the room"
                @room.putinroom(item)
            else
                puts "There is no #{item} in your inventory"
            end
        end
        @room.room_in_desc() if command == "ROOM"
        @room.move("NORTH") if command == "NORTH" 
        @room.move("SOUTH") if command == "SOUTH"
        @room.move("EAST") if command == "EAST"
        @room.move("WEST") if command == "WEST"
        @character.inventory() if command == "INVENTORY" or command == "INV"
        @character.examine() if command == "EXAMINE" or command == "EXAM"
        @character.equip() if command == "EQUIP" or command == "EQ" 
        @character.unequip() if command == "UNEQUIP" or command == "UE"

        @quit = true if command == "QUIT" 
    end
	def died	
		puts "You have died! Quitting..."
		@quit = true
	end
    def commands
        puts "\n - Command (Lists Commands)"
        puts " - Save (Saves Game State)"
        puts " - Load (Loads Game State)"
        puts " - Room (Lists Room Info)"
        puts " - Pickup (Picks Up Room Items)"
        puts " - Putdown (Putdown Inventory Items)"
        puts " - North / East / South / West (Goes In The Desired Direction If Possible)"
        puts " - Inventory / Inv (Lists Items On Character)"
        puts " - Examine / Exam (Lists Info About An Item In Inventory)"
        puts " - Equip / EQ (Equips Tool / Weapon Into Main Hand)"
        puts " - Unequip / UE (Unequips Tool / Weapon Into Inventory)"
        puts " - Quit (Work it out)"
    end
    def commandbattle
        puts "\n - Command (List Battle Commands)"
        puts " - Attack (Attacks The Enemyy)"
        puts " - Block (Blocks An Enemy Attack To Reduce Damage)"
        puts " - Use (Uses An Item In Your Inventory)"
        puts " - Inventory / Inv (Lists Items On Character)"
    end
    def save_game
        data = $charinfo, $roominfo, $general_info
        File.open('savegame.yaml', 'w') {|f| f.write data.to_yaml } 
        @savegame = YAML::load(File.open('savegame.yaml'))
        puts "SAVED GAME!"  
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
        puts "\nThis is a dungeon text adventure game."    
        puts "The aim of this game is to become the leader of the dungeon"
        puts "and replace the current king of the dungeon."
        puts "However the current king is hiding out and must be killed first."
        puts "\nThe game requires use of commands to navigate through."
        puts "These are the commands: "
        puts "\n - Command (Lists Commands)"
        puts " - Save (Saves Game State)"
        puts " - Load (Loads Game State)"
        puts " - Room (Lists Room Info)"
        puts " - Pickup (Picks Up Room Items)"
        puts " - Putdown (Putdown Inventory Items)"
        puts " - North / East / South / West (Goes In The Desired Direction If Possible)"
        puts " - Inventory / Inv (Lists Items On Character)"
        puts " - Examine / Exam (Lists Info About An Item In Inventory)"
        puts " - Equip / EQ (Equips Tool / Weapon Into Main Hand)"
        puts " - Unequip / UE (Unequips Tool / Weapon Into Inventory)"
        puts " - Quit (Work it out)\n\n"
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
