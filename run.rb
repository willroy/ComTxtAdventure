#!/usr/bin/env ruby

require 'yaml'
require 'curses'
require_relative 'ruby/room'
require_relative 'ruby/character'
require_relative 'ruby/battle'
include Curses

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
  def initialize(text)
    @text = text
  end
  def load_game
    @text.reset_pos
    @text.draw("You travel back to your last save...")
    @savegame = YAML::load(File.open('yaml/savegame.yaml'))
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
    @savegame = YAML::load(File.open('yaml/savegame.yaml'))
    @text.draw("SAVED GAME!") 
  end
  def new_game	
    @text.reset_pos
    @text.draw("You create a new game...")
    @newgame = YAML::load(File.open('yaml/newgame.yaml'))
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
    save_game()
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
    @texthandler
    $roominfo
    $general_info
    $charinfo
    $items
    $npcs
  end
  def init_game
    @text = CursesTextHandler.new
    @room = Room.new(@text)
    @gamestatehandler = GameStateHandler.new(@text)
    $items = YAML::load_file('yaml/itemlist.yaml')
    $npcs = YAML::load_file('yaml/npclist.yaml')
    $other = Window.new(7,40,0,0)
    $com = Window.new(35,80,7,7)
    $com.box("|","-")
    $other.box("|","-")
    @text.draw("New Game or Load Game? (NEW / LOAD) => ")
    gametype = $com.getstr()
    $com.clear
    if gametype.upcase == "NEW" #loads new info for the yaml for new game
      @gamestatehandler.new_game
      @character = Character.new(@text)
      @character.change_name()
      true
    elsif gametype.upcase == "LOAD" #does the same thing as NEW but different file
      @gamestatehandler.load_game
      @character = Character.new(@text)
      false
    else
      @text.draw("")
      @text.draw("Invalid Input Option")
      @text.draw("Quitting!")
      abort
    end
  end
  def game_loop
    @text.draw_other
    @debug = false
    while true do
      $com.box("|","-")
      $other.box("|","-")
      $other.refresh
      $other.clear
      @text.draw_other 
      File.open('yaml/general_info.yaml', 'w') {|f| f.write $general_info.to_yaml } 
      File.open('yaml/roominfo.yaml', 'w') {|f| f.write $roominfo.to_yaml } 
      File.open('yaml/charinfo.yaml', 'w') {|f| f.write $charinfo.to_yaml } 

      command_test()
      abort if @quit == true
    end
  end
  def command_test
    command = nil
    begin 
      command = @text.command_prompt()
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
      @text.draw("\nQuitting... #{e.message}")
      abort
    end	

    @text.reset_pos()
    case command
      when "ROOM"
        @room.room_in_desc()
      when "NORTH"
        @room.move("NORTH")
      when "WEST"
        @room.move("WEST")
      when "EAST"
        @room.move("EAST")
      when "SOUTH"
        @room.move("SOUTH")
      when "COMMAND"
        commands() 
      when "SAVE"
        @gamestatehandler.save_game()
      when "LOAD"
        @gamestatehandler.load_game()
      when "RH"
        rh = true
      when "INV"
        @character.inventory()
      when "EXAMINE"
        @character.examine()
      when "Q"
        abort()
      when "DEBUG"
        begin
          @debug = true
          $charinfo[:health] = 100 if rh 
        end
      when "EQUIP"
        @character.equip(value)
      when "UNEQUIP"
        @character.unequip()
      when "PICKUP"
        @room.pickup(value, @character)
      when "PUTDOWN"
        @character.putdown(value, @room)
    end

    randomencounter = 2
    if randomencounter < 1 
      @battlehandler = Battle.new(@debug, value, @character)
      wintest = @battlehandler.init_battle()
      if wintest == false
        died()
      elsif wintest == true
        @text.draw("You beat the enemy!")
        @text.draw("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
      else
      end
    end
    @text.draw_other
      
  end
  def died    
    @text.draw("You have died! Quitting...")
    @quit = true
  end
  def commands
    @text.draw(" - Command (Lists Commands)")
    @text.draw(" - Save (Saves Game State)")
    @text.draw(" - Load (Loads Game State)")
    @text.draw(" - Room (Lists Room Info)")
    @text.draw(" - Pickup (Picks Up Room Items)")
    @text.draw(" - Putdown (Putdown Inventory Items)")
    @text.draw(" - North / East / South / West (Goes In The Desired Direction)")
    @text.draw(" - Inventory / Inv (Lists Items On Character)")
    @text.draw(" - Examine / Exam (Lists Info About An Item In Inventory)")
    @text.draw(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
    @text.draw(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
    @text.draw(" - Quit (Work it out)")
  end
  def tutorial
    @text.draw("\nThis is a dungeon text adventure game.")
    @text.draw("The aim of this game is to become the leader of the dungeon")
    @text.draw("and replace the current king of the dungeon.")
    @text.draw("However the current king is hiding out and must be killed first.")
    @text.draw("\nThe game requires use of commands to navigate through.")
    @text.draw("These are the commands: ")
    @text.draw("\n - Command (Lists Commands)")
    @text.draw(" - Save (Saves Game State)")
    @text.draw(" - Load (Loads Game State)")
    @text.draw(" - Room (Lists Room Info)")
    @text.draw(" - Pickup (Picks Up Room Items)")
    @text.draw(" - Putdown (Putdown Inventory Items)")
    @text.draw(" - North / East / South / West (Goes In The Desired Direction If Possible)")
    @text.draw(" - Inventory / Inv (Lists Items On Character)")
    @text.draw(" - Examine / Exam (Lists Info About An Item In Inventory)")
    @text.draw(" - Equip / EQ (Equips Tool / Weapon Into Main Hand)")
    @text.draw(" - Unequip / UE (Unequips Tool / Weapon Into Inventory)")
    @text.draw(" - Quit (Work it out)\n\n")
  end
  def start_game
    @text.draw("You wake up in an empty room")
    @text.draw("#{$charinfo['name']} => Where am I?")
    @text.draw("You see a door to the north of the room")
    @text.draw("Would you like a tutorial? (Y/n) ")
    tut = gets.chomp
    if tut.upcase == "Y"
      @text.draw("Running tutorial...")
      tutorial()
      game_loop()
    elsif tut.upcase == "N"
      @text.draw("Ok!")
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
# :vim: set expandtab:
