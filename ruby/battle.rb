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