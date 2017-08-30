#!/usr/bin/env ruby

require 'yaml'

class Character
    def change_name
        $texthandler.write("Character name? => ") #input text
        @name = gets.chomp #get input

        $charinfo[:name] = @name #Modify
        File.open('characters.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
        $texthandler.write("Hello #{@name}") #show to player the name
    end
    def equip
        $texthandler.write("Which item? ")
        item = gets.chomp
        ininv = false
        $charinfo["items"].each {|k| ininv = true if k == item}
        $charinfo["items"].delete(item) if ininv == true
        $charinfo["equiped"] = item if $charinfo["equiped"] == nil and ininv == true
    end
    def unequip
        equipped = ""
        if $charinfo == nil
            $texthandler.write ("You have nothing to unequip")
        else
            equipped = $charinfo["equiped"]
            $charinfo["equiped"] = nil
            $charinfo["items"] << equipped
        end
    end
    def inventory
        $texthandler.write("Inventory:")
        itemdupes = $charinfo["items"].inject(Hash.new(0)) {|n, v| n[v] += 1; n }
        itemdupes.to_a.each do |value, count| 
            $texthandler.write "#{value} [#{count}]" if count > 1
            $texthandler.write value if count == 1
        end
        $texthandler.write("Equipped:")
        $texthandler.write $charinfo["equiped"]
    end
    def intoinv(item)
        $charinfo["items"] << item
    end
    def putdown(item)
        return true if $charinfo["items"].each {|k| $charinfo["items"].delete(item) if k == item}
    end
    def examine
        $texthandler.write("Which Item? ")
        item = gets.chomp
        gotitem = false
        $charinfo["items"].each {|v| gotitem = true if item == v}
        gotitem = true if item == $charinfo["equiped"]
        if gotitem == true 
            $items.each do |key, value|
                $texthandler.write("#{value[:name]} is type #{value[:type]} and it:\n #{value[:use]}") if value[:name] == item
            end
        elsif gotitem == false
            $texthandler.write("You cannot examine an item you do not have")
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
        $texthandler.write("You cannot go in this direction") if cango == false
        $texthandler.write("You go #{dir}") if cango == true
    end
    def room_in_desc
        $texthandler.write("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
        $texthandler.write("Items in room: ")
        $roominfo[$general_info["current_room"]]["items"].each {|k| $texthandler.write(k)}
        $texthandler.write("Npcs in room: ")
        $roominfo[$general_info["current_room"]].fetch("npcs", {}).each do |k, v| 
            $texthandler.write(v[:name])
        end
        $roominfo[$general_info["current_room"]][:exits].each {|k, v| $texthandler.write("There is the #{k} to the #{v}")}
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

class BasicTextHandler
    def write(string)
        puts string
    end
    def command_prompt
        print "=> "
		return gets.chomp.upcase 
    end
end

class Game
    def initialize
        @character
        @room
        @quit = false
        @battle = false
        @savegame
        $texthandler
        $roominfo
        $general_info
        $charinfo
        $items
        $npcs
    end
    def init_game
        $texthandler = BasicTextHandler.new
        $texthandler.write("New Game or Load Game? (NEW / LOAD) => ")
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
            $texthandler.write("")
            $texthandler.write("Invalid Input Option")
            $texthandler.write("Quitting!")
            abort
        end
    end
    def game_loop
		debug = false
        while true do
            command_test(debug)
            File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
            File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
            File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
            abort if @quit == true
        end
    end
    def battle_loop(debug)
        $texthandler.write("Enemy to battle: ")
        enemy = gets.chomp
        running = false
        enemyid = nil
        if $roominfo[$general_info["current_room"]]["npcs"] == nil
            $texthandler.write("No enemies in this room")
            return "no_enemy"
        end
        $roominfo[$general_info["current_room"]]["npcs"].each do |key, value|
            if value[:name] == enemy
                $texthandler.write("You engage in battle with #{enemy}")
                enemyid = key
                running = true
            end
        end 
        if running == false
            $texthandler.write("No #{enemy} in this room")
        end
        while running == true do 
            File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
            File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
            File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml }
            begin
                command = $texthandler.command_prompt()
            rescue Exception => e
                $texthandler.write("\nQuitting... #{e.message}")
                abort
            end
            commandbattle() if command == "COMMAND" 
            attk(enemyid) if command == "ATTACK" or command == "A"
            block() if command == "BLOCK" or command == "B"
            use() if command == "USE" or command == "U"
            killenemy(enemyid) if command == "KE" and debug = true
            killchar() if command == "KC" and debug = true 
            @character.inventory() if command == "INVENTORY" or command == "INV"
            if  $roominfo[$general_info["current_room"]]["npcs"][enemyid][:health] <= 0
                $roominfo[$general_info["current_room"]]["npcs"].delete(enemyid)
                return true
            end
            return false if $charinfo[:health].to_i() <= 0 
			enemy_attk(enemyid)
        end
    end
	def enemy_attk(enemyid)
		$charinfo[:health] -= rand($roominfo[$general_info["current_room"]]["npcs"][enemyid][:power]-2..$roominfo[$general_info["current_room"]]["npcs"][enemyid][:power]+2)
	end	
    def killenemy(enemyid)
        $roominfo[$general_info["current_room"]]["npcs"][enemyid][:health] = 0
        $texthandler.write("Enemy Health Set To 0")
    end
    def killchar
        $charinfo[:health] = 0
        $texthandler.write("Player Health Set To 0")
    end
    def attk(enemyid)
		$roominfo[$general_info["current_room"]]["npcs"][enemyid][:health] -= rand($charinfo[:power]-2..$charinfo[:power]+2)
		$texthandler.write("Your Health: #{$charinfo[:health]} Enemy Health: #{$roominfo[$general_info["current_room"]]["npcs"][enemyid][:health]}")
    end
    def block
    
    end
    def use
        $texthandler.write("Which item? ")
        item = gets.chomp
        itemid = nil
        ininv = false
        usable = false
        $charinfo["items"].each {|k| ininv = true if k == item}
        $items.each {|k, v| itemid = k if v[:name] == item}
        usable = true if $items[itemid][:type] == "consumable"
        $texthandler.write("Usable? #{usable} InInv? #{ininv} ItemID: #{itemid}")
    end
    def restorehealth
		$texthandler.write("RESTORED HEALTH")
        $charinfo[:health] = 100
    end
    def command_test(debug)
        begin
			command = $texthandler.command_prompt()
        rescue Exception => e
            $texthandler.write("\nQuitting... #{e.message}")
            abort
        end	
		if command == "DEBUG"
			debug = true
			$texthandler.write("DEBUG MODE ACTIVE")
		end
        commands() if command == "COMMAND"
        save_game() if command == "SAVE"
        load_game() if command == "LOAD"
        restorehealth() if command == "RH" and debug == true
        if command == "BATTLE"
            value = battle_loop(debug)
            if value == false
                died()
            elsif value == true
                $texthandler.write("You beat the enemy!")
                $texthandler.write("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
            else

            end
        end
        if command == "PICKUP"
            $texthandler.write("Which Item? ")
            item = gets.chomp
            if @room.pickup(item) == true
                $texthandler.write("You put #{item} into your inventory.")
                @character.intoinv(item)
            else
                $texthandler.write("There is no #{item} in this room")
            end
        end
        if command == "PUTDOWN"
            $texthandler.write("Which Item? ")
            item = gets.chomp
            if @character.putdown(item) == true 
                $texthandler.write("You put the #{item} down in the room")
                @room.putinroom(item)
            else
                $texthandler.write("There is no #{item} in your inventory")
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
        $texthandler.write("You have died! Quitting...")
        @quit = true
    end
    def commands
        $texthandler.write("\n - Command (Lists Commands)")
        $texthandler.write(" - Save (Saves Game State)")
        $texthandler.write(" - Load (Loads Game State)")
        $texthandler.write(" - Room (Lists Room Info)")
        $texthandler.write(" - Pickup (Picks Up Room Items)")
        $texthandler.write(" - Putdown (Putdown Inventory Items)")
        $texthandler.write(" - North / East / South / West (Goes In The Desired Direction If Possible)")
        $texthandler.write(" - Inventory / Inv (Lists Items On Character)")
        $texthandler.write(" - Examine / Exam (Lists Info About An Item In Inventory)")
        $texthandler.write(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
        $texthandler.write(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
        $texthandler.write(" - Quit (Work it out)")
    end
    def commandbattle
        $texthandler.write("\n - Command (List Battle Commands)")
        $texthandler.write(" - Attack / A (Attacks The Enemyy)")
        $texthandler.write(" - Block / B (Blocks An Enemy Attack To Reduce Damage)")
        $texthandler.write(" - Use / U (Uses An Item In Your Inventory)")
        $texthandler.write(" - Inventory / Inv (Lists Items On Character)")
    end
    def save_game
        data = $charinfo, $roominfo, $general_info
        File.open('savegame.yaml', 'w') {|f| f.write data.to_yaml } 
        @savegame = YAML::load(File.open('savegame.yaml'))
        $texthandler.write("SAVED GAME!") 
    end
    def load_game 
        $texthandler.write("\nYou travel back to your last save...\n\n")
        @savegame = YAML::load(File.open('savegame.yaml'))
        count = 1
        @savegame.each do |key, value|
            #write key
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
        $texthandler.write("\nThis is a dungeon text adventure game.") 
        $texthandler.write("The aim of this game is to become the leader of the dungeon")
        $texthandler.write("and replace the current king of the dungeon.")
        $texthandler.write("However the current king is hiding out and must be killed first.")
        $texthandler.write("\nThe game requires use of commands to navigate through.")
        $texthandler.write("These are the commands: ")
        $texthandler.write("\n - Command (Lists Commands)")
        $texthandler.write(" - Save (Saves Game State)")
        $texthandler.write(" - Load (Loads Game State)")
        $texthandler.write(" - Room (Lists Room Info)")
        $texthandler.write(" - Pickup (Picks Up Room Items)")
        $texthandler.write(" - Putdown (Putdown Inventory Items)")
        $texthandler.write(" - North / East / South / West (Goes In The Desired Direction If Possible)")
        $texthandler.write(" - Inventory / Inv (Lists Items On Character)")
        $texthandler.write(" - Examine / Exam (Lists Info About An Item In Inventory)")
        $texthandler.write(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
        $texthandler.write(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
        $texthandler.write(" - Quit (Work it out)\n\n")
    end
    def start_game
        $texthandler.write("You wake up in an empty room")
        $texthandler.write("#{$charinfo['name']} => Where am I?")
        $texthandler.write("You see a door to the north of the room")
        $texthandler.write("Would you like a tutorial? (Y/n) ")
        tut = gets.chomp
        if tut.upcase == "Y"
            $texthandler.write("Running tutorial...")
            tutorial()
            game_loop()
        elsif tut.upcase == "N"
            $texthandler.write("Ok!")
            game_loop()
        end
    end
end

game = Game.new
option = game.init_game()
if option == true
    game.start_game 
elsif option == false
    $texthandler.write("\nYou wake up back where you were...\n\n")
    game.game_loop
end

# :vim: set expandtab:
