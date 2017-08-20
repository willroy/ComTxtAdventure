require 'yaml'

class Character
    def initialize(charinfo)
        @charinfo = charinfo #character yaml file
    end
    def change_name
        puts "Character name? => " #input text
        @name = gets.chomp #get input

        info = YAML::load_file('charinfo.yml') #Load
        info['name'] = @name #Modify
        File.open('charinfo.yml', 'w') {|f| f.write name.to_yaml } 
        puts "Hello #{@name}" #show to player the name
    end
    def inventory
        puts "Inventory:"
        for item in @charinfo['items'] do {|i| puts "#{i['name']}"}
    end
end

class Room
    def initialize(roominfo=default_room_info())
        @roominfo = roominfo
    end
    def default_room_info
        data = {
            "1" => {"name" => "Starting Room", "Items" => {"Starting Sword" => {"Type" => "Weapon"}}, "npcs" => "NONE"}
            "2" => {"name" => "Hallway", "Items" => {"Potion" => {"Type" => "Consumable"}}, "npcs" => "Goblin"}
        }
        File.open("roominfo.yml", "w") {|f| f.write(data.to_yaml) }
        return data
    end
end

class Game
    def initialize
        @character
        @room
    end
    def init_game
        puts "New Game or Load Game? (NEW / LOAD) => "
        gametype = gets.chomp
        if gametype == "NEW" #creates new info for the yml for new game
            data = {"name" => "NAME", "health" => "100", "items" => {}}
            charinfo = YAML::load_file('charinfo.yml')
            @character = Character.new(charinfo)
            @character.data_input()
            @room = Room.new
        elsif gametype == "LOAD" #does the same thing as NEW but puts past data by loading
            begin
                charinfo = YAML::load(File.open('charinfo.yml')) 
            rescue ArgumentError => e #just in case
                  puts "Could not parse CHARACTER YAML: #{e.message}"
            end
            @character = Character.new(charinfo)

            begin 
                roominfo = YAML::load(File.open('roominfo.yml'))
            rescue ArgumentError => e
                puts "Could not parse ROOM YAML: #{e.message}"
            end
        end
    end
    def game_loop
        while True do
            command_test()

        end
    end
    def command_test()
        puts "=> "
        command = gets.chomp
        save_game() if command.upcase = "SAVE"
        load_game() if command.upcase = "LOAD"
        north() if command.upcase = "NORTH" 
        south() if command.upcase = "SOUTH"
        east() if command.upcase = "EAST"
        west() if command.upcase = "WEST"
        @character.inventory() if command.upcase = "INVENTORY"
        quit() if command.upcase = "QUIT" 
    end
    def start_game
        puts "You wake up in an empty room"
        puts "#{@character["name"]} => Where am I?"
        puts "You see a door to the north of the room"
        puts "Would you like a tutorial? (Y/n) "
        tutorial = gets.chomp
        if tutorial.upcase = "Y"
            
        elsif
        
        end
    end
end

