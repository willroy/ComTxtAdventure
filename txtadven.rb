#!/usr/bin/env ruby
 
require 'yaml'
require 'curses'
include Curses

class Character
  def change_name
    $com.clear
    $text.reset_pos
    $text.draw("Character name? => ") #input text
    @name = $com.getstr() #get input

    $charinfo[:name] = @name #Modify
    File.open('characters.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
    $text.draw("Hello #{@name}") #show to player the name
  end
  def equip(item)
    ininv = false
    $charinfo["items"].each {|k| ininv = true if k == item}
    $charinfo["items"].delete(item) if ininv == true
    $charinfo["equiped"] = item if $charinfo["equiped"] == nil and ininv == true
  end
  def unequip
    equipped = ""
    if $charinfo["equiped"] == nil
      $text.draw ("You have nothing to unequip")
    else
      equipped = $charinfo["equiped"]
      $charinfo["equiped"] = nil
      $charinfo["items"] << equipped
    end
  end
  def inventory
    $text.reset_pos
    $text.draw("Inventory:") if $charinfo["items"] == nil
    $text.draw("Inventory: ") unless $charinfo["items"] == nil
    itemdupes = $charinfo["items"].inject(Hash.new(0)) {|n, v| n[v] += 1; n }
    itemdupes.to_a.each do |value, count| 
      $text.draw "#{value} [#{count}]" if count > 1
      $text.draw value if count == 1
    end
    $text.draw("Equipped:") if $charinfo["equiped"] == nil
    $text.draw("Equipped:") unless $charinfo["equiped"] == nil
    $text.draw $charinfo["equiped"]
    $text.reset_pos
  end
  def intoinv(item)
    $charinfo["items"] << item
  end
  def putdown(item)
    return true if $charinfo["items"].each {|k| $charinfo["items"].delete(item) if k == item}
  end
  def examine
    $text.draw("Which Item? ")
    item = gets.chomp
    gotitem = false
    $charinfo["items"].each {|v| gotitem = true if item == v}
    gotitem = true if item == $charinfo["equiped"]
    if gotitem == true 
      $items.each do |key, value|
        $text.draw("#{value[:name]} is type #{value[:type]} and it:\n #{value[:use]}") if value[:name] == item
      end
    elsif gotitem == false
      $text.draw("You cannot examine an item you do not have")
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
    $text.draw("You cannot go in this direction") if cango == false
    $text.draw("You go #{dir}") if cango == true
  end
  def room_in_desc
    $text.reset_pos()
    $text.draw("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
    $text.draw("Items in room: ")
    if $roominfo[$general_info["current_room"]]["items"] != nil
      $roominfo[$general_info["current_room"]]["items"].each do |k| 
        $text.draw(k)
      end
    end
    $roominfo[$general_info["current_room"]][:exits].each {|k, v| $text.draw("There is the #{k} to the #{v}")}
    $text.reset_pos()
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
class Battle	
  def initialize(debug, enemy, character)
    @enemy = enemy
    @running = false
    @enemyid = nil
    @character = character
  end
  def init_battle
    if $roominfo[$general_info["current_room"]]["npcs"] == nil
      $text.draw("No enemies in this room")
      return "noenemy"
    end
    $roominfo[$general_info["current_room"]]["npcs"].each do |key, value|
      if value[:name] == @enemy
        $text.draw("You engage in battle with #{@enemy}")
        @enemyid = key
        @running = true
      end
    end 
    if @running == false
      $text.draw("No #{@enemy} in this room")
    elsif @running == true
      battle_loop()
    end
  end
  def battle_loop
    $text.draw_other
    while true do
      if $roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health] <= 0
        $text.draw("Your Health: #{$charinfo[:health]} Enemy Health: 0")
        $roominfo[$general_info["current_room"]]["npcs"].delete(@enemyid)
        return true
      end
      return false if $charinfo[:health].to_i() <= 0 
      $com.box("|","-")
      $other.box("|","-")
      $other.refresh
      $other.clear
      $text.draw_other
      command_test_battle
      File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
      File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
      File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
    end
  end
  def command_test_battle
    $text.reset_pos
    begin
      command = $text.command_prompt()
      $com.clear
      if command.match(" ")
        list_com = command.split(" ")
        command = list_com[0]
        command.upcase!
        value = list_com[1]
      else
        command.upcase!
      end		
    rescue Exception => e
      $text.draw("\nQuitting... #{e.message}")
      abort
    end	
    commandbattle() if command == "COMMAND" 
    attk() if command == "ATTACK" or command == "A"
    block() if command == "BLOCK" or command == "B"
    use() if command == "USE" or command == "U"
    killenemy() if command == "KE" and debug == true
    killchar() if command == "KC" and debug == true 
    @character.inventory() if command == "INVENTORY" or command == "INV"
    enemy_attk() if command == "ATTACK" or command == "BLOCK" or command == "USE" or command == "A" or command == "B" or command == "U"
    if command == "A" or command == "ATTACK" or command == "BLOCK" or command == "B" or command == "USE" or command == "U"
      $text.draw("Your Health: #{$charinfo[:health]} Enemy Health: #{$roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health]}") unless $roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health] <= 0 
    end
  end
  def enemy_attk
    $charinfo[:health] -= rand($roominfo[$general_info["current_room"]]["npcs"][@enemyid][:power]-2..$roominfo[$general_info["current_room"]]["npcs"][@enemyid][:power]+2)
  end	
  def killenemy
    $roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health] = 0
    $text.draw("Enemy Health Set To 0")
  end
  def killchar
    $charinfo[:health] = 0
    $text.draw("Player Health Set To 0")
  end
  def attk
    $roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health] -= rand($charinfo[:power]-2..$charinfo[:power]+2)
  end
  def block

  end
  def use
    $text.draw("Which item? ")
    item = gets.chomp
    itemid = nil
    ininv = false
    usable = false
    $charinfo["items"].each {|k| ininv = true if k == item}
    $items.each {|k, v| itemid = k if v[:name] == item}
    usable = true if $items[itemid][:type] == "consumable"
    $text.draw("Usable? #{usable} InInv? #{ininv} ItemID: #{itemid}")
    if usable 
      $charinfo[:health] += 40 if $items[itemid][:does] = "heal"
      $roominfo[$general_info["current_room"]]["npcs"][@enemyid][:health] -= 10 if $items[itemid][:does] = "dealdmg"
    end
  end
  def commandbattle
    $text.draw("\n - Command (List Battle Commands)")
    $text.draw(" - Attack / A (Attacks The Enemyy)")
    $text.draw(" - Block / B (Blocks An Enemy Attack To Reduce Damage)")
    $text.draw(" - Use / U (Uses An Item In Your Inventory)")
    $text.draw(" - Inventory / Inv (Lists Items On Character)")
  end
end
class CursesTextHandler
  def initialize
    @count = 0
  end
  def draw_other
    $other.clear
    $other.setpos(2, 3)
    $other.addstr("Health: #{$charinfo[:health]}")
    $other.setpos(3, 3)
    $other.addstr("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
  end
  def draw_other_battle(enemyhealth)
    $other.clear
    $other.setpos(2, 3)
    $other.addstr("Health: #{$charinfo[:health]}")
    $other.setpos(3, 3)
    $other.addstr("Enemy Health: #{enemyhealth}")
    $other.setpos(4, 3)
    $other.addstr("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
    $othera
  end
  def draw(text)
    @count += 1
    $com.setpos(3+@count, 8)
    $com.addstr text.to_s()
  end
  def reset_pos
    @count = 0
    $com.setpos(3, 3)
  end
  def command_prompt
    $com.setpos(2, 3)
    $com.addstr "=> "
    return $com.getstr
  end
end
class GameStateHandler
  def load_game
    $text.reset_pos
    $text.draw("You travel back to your last save...")
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
  def save_game
    data = $charinfo, $roominfo, $general_info
    File.open('savegame.yaml', 'w') {|f| f.write data.to_yaml } 
    @savegame = YAML::load(File.open('savegame.yaml'))
    $text.draw("SAVED GAME!") 
  end
  def new_game	
    $text.reset_pos
    $text.draw("You create a new game...")
    @newgame = YAML::load(File.open('newgame.yaml'))
    count = 1
    @newgame.each do |key, value|
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
end
class Game
  def initialize
    @character
    @room
    @quit = false
    @battle = false
    @battlehandler
    @savegame
    @gamestatehandler
    @debug
    $texthandler
    $roominfo
    $general_info
    $charinfo
    $items
    $npcs
  end
  def init_game
    @room = Room.new
    $text = CursesTextHandler.new
    @gamestatehandler = GameStateHandler.new
    $items = YAML::load_file('itemlist.yaml')
    $npcs = YAML::load_file('npclist.yaml')
    $other = Window.new(7,40,0,0)
    $com = Window.new(35,80,7,7)
    $com.box("|","-")
    $other.box("|","-")
    $text.draw("New Game or Load Game? (NEW / LOAD) => ")
    gametype = $com.getstr()
    $com.clear
    if gametype.upcase == "NEW" #loads new info for the yml for new game
      @gamestatehandler.new_game
      @character = Character.new
      @character.change_name()
      true
    elsif gametype.upcase == "LOAD" #does the same thing as NEW but different file
      @gamestatehandler.load_game
      @character = Character.new
      false
    else
      $text.draw("")
      $text.draw("Invalid Input Option")
      $text.draw("Quitting!")
      abort
    end
  end
  def game_loop
    $text.draw_other
    @debug = false
    while true do
      $com.box("|","-")
      $other.box("|","-")
      $other.refresh
      $other.clear
      $text.draw_other 
      File.open('general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
      File.open('roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
      File.open('charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 

      command_test()
      abort if @quit == true
    end
  end
  def command_test
    value = nil
    begin
      command = $text.command_prompt()
      $com.clear
      if command.match(" ")
        list_com = command.split(" ")
        command = list_com[0]
        command.upcase!
        value = list_com[1]
      else
        command.upcase!
      end		
    rescue Exception => e
      $text.draw("\nQuitting... #{e.message}")
      abort
    end	
    $text.reset_pos()
    commands() if command == "COMMAND"
    @gamestatehandler.save_game() if command == "SAVE"
    @gamestatehandler.load_game() if command == "LOAD"
    rh = true if command == "RH" 
    $charinfo[:health] = 100 if rh && @debug

    randomencounter = rand(0...10) 
    $text.draw(randomencounter)
    listofdir = ["NORTH", "SOUTH", "EAST", "WEST"]
    listofdir.each {|k| moving = true if command = k}
    if randomencounter < 1 
      @battlehandler = Battle.new(@debug, value, @character)
      wintest = @battlehandler.init_battle()
      if wintest == false
        died()
      elsif wintest == true
        $text.draw("You beat the enemy!")
        $text.draw("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
      else

      end
    end
    @room.room_in_desc() if command == "ROOM"
    @room.move("NORTH") if command == "NORTH" 
    @room.move("SOUTH") if command == "SOUTH"
    @room.move("EAST") if command == "EAST"
    @room.move("WEST") if command == "WEST"
    $text.draw_other
    @character.inventory() if command == "INVENTORY" or command == "INV"
    @character.examine() if command == "EXAMINE" or command == "EXAM" and if value == nil
    @character.equip(value) if command == "EQUIP" or command == "EQ"
    @character.unequip() if command == "UNEQUIP" or command == "UE"

    if command == "DEBUG"
      $text.draw("DEBUG MODE ACTIVE") 
      @debug = true
    end
    if command == "PICKUP"
      if @room.pickup(value) == true
        $text.draw("You put #{value} into your inventory.")
        @character.intoinv(value)
      else
        $text.draw("There is no #{value} in this room") unless value == nil
      end
    end
    if command == "PUTDOWN"
      if @character.putdown(value) == true 
        $text.draw("You put the #{value} down in the room")
        @room.putinroom(value)
      else
        $text.draw("There is no #{value} in your inventory")
      end
    end
    
    @quit = true if command == "QUIT" 
  end
  def died    
    $text.draw("You have died! Quitting...")
    @quit = true
  end
  def commands
    $text.draw(" - Command (Lists Commands)")
    $text.draw(" - Save (Saves Game State)")
    $text.draw(" - Load (Loads Game State)")
    $text.draw(" - Room (Lists Room Info)")
    $text.draw(" - Pickup (Picks Up Room Items)")
    $text.draw(" - Putdown (Putdown Inventory Items)")
    $text.draw(" - North / East / South / West (Goes In The Desired Direction)")
    $text.draw(" - Inventory / Inv (Lists Items On Character)")
    $text.draw(" - Examine / Exam (Lists Info About An Item In Inventory)")
    $text.draw(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
    $text.draw(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
    $text.draw(" - Quit (Work it out)")
  end
  def tutorial
    $text.draw("\nThis is a dungeon text adventure game.")
    $text.draw("The aim of this game is to become the leader of the dungeon")
    $text.draw("and replace the current king of the dungeon.")
    $text.draw("However the current king is hiding out and must be killed first.")
    $text.draw("\nThe game requires use of commands to navigate through.")
    $text.draw("These are the commands: ")
    $text.draw("\n - Command (Lists Commands)")
    $text.draw(" - Save (Saves Game State)")
    $text.draw(" - Load (Loads Game State)")
    $text.draw(" - Room (Lists Room Info)")
    $text.draw(" - Pickup (Picks Up Room Items)")
    $text.draw(" - Putdown (Putdown Inventory Items)")
    $text.draw(" - North / East / South / West (Goes In The Desired Direction If Possible)")
    $text.draw(" - Inventory / Inv (Lists Items On Character)")
    $text.draw(" - Examine / Exam (Lists Info About An Item In Inventory)")
    $text.draw(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
    $text.draw(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
    $text.draw(" - Quit (Work it out)\n\n")
  end
  def start_game
    $text.draw("You wake up in an empty room")
    $text.draw("#{$charinfo['name']} => Where am I?")
    $text.draw("You see a door to the north of the room")
    $text.draw("Would you like a tutorial? (Y/n) ")
    tut = gets.chomp
    if tut.upcase == "Y"
      $text.draw("Running tutorial...")
      tutorial()
      game_loop()
    elsif tut.upcase == "N"
      $text.draw("Ok!")
      game_loop()
    end
  end
end

game = Game.new
option = game.init_game()
if option == true
  game.game_loop() 
elsif option == false
  game.game_loop()
end
end
# :vim: set expandtab:
