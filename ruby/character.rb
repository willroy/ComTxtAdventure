class Character
  def initialize(text)
    @text = text
  end
  def change_name
    $com.clear
    @text.draw("Character name? => ") #input text
    @name = $com.getstr() #get input
    @text.draw("")
    @text.draw("")
    @text.draw("")
    @text.draw("")            
    @text.draw("")
    draw1 = %(             _..-'(                       )`-.._)
    draw2 = %(           ./'. '||\\\\.       (\\_/)       .//||` .`\.)
    draw3 = %(       ./'.|'.'||||\\\\|..     \)O O\(    ..|//||||`.`|.`\.)
    draw4 = %(     ./'..|'.|| |||||\\`````` '`''` ''''''/||||| ||.`|..`\.)
    draw5 = %(   ./'.||'.|||| ||||||||||||.     .|||||||||||| |||||.`||.`\.)
    draw6 = %(  /'|||'.|||||| ||||||||||||{     }|||||||||||| ||||||.`|||`\\)            
    draw7 = %( '.|||'.||||||| ||||||||||||{     }|||||||||||| |||||||.'|||.')
    draw8 = %('.||| ||||||||| |/'   ``\\||``     ''||/''   `\\| ||||||||| |||.`)
    draw9 = %(|/' \\./'     `\\./         \\!|\\   /|!/         \\./'     `\\./ `\\|)
    draw10= %(V    V         V          }' `\\ /' `{          V         V    V)
    draw11= %(`    `         `               V               '         '    ')
    @text.draw(draw1)            
    @text.draw(draw2)            
    @text.draw(draw3)            
    @text.draw(draw4)            
    @text.draw(draw5)            
    @text.draw(draw6)            
    @text.draw(draw7)            
    @text.draw(draw8)            
    @text.draw(draw9)            
    @text.draw(draw10)            
    @text.draw(draw11)            
    $charinfo[:name] = @name #Modify
    File.open('characters.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
    @text.draw("Hello #{@name}") #show to player the name
  end
  def equip(item)
    ininv = false
    @text.reset_pos
    @text.draw("Trying To Equip...")
    $charinfo["items"].each {|k| ininv = true if k == item}
    $charinfo["items"].delete(item) if ininv == true
    $charinfo["equiped"] = item if $charinfo["equiped"] == nil and ininv == true
    @text.draw("Equipped!") if ininv == true
  end
  def unequip
    equipped = ""
    if $charinfo["equiped"] == nil
      @text.draw ("You have nothing to unequip")
    else
      equipped = $charinfo["equiped"]
      $charinfo["equiped"] = nil
      $charinfo["items"] << equipped
    end
  end
  def inventory
    @text.reset_pos
    @text.draw("Inventory:") if $charinfo["items"] == nil
    @text.draw("Inventory: ") unless $charinfo["items"] == nil
    itemdupes = $charinfo["items"].inject(Hash.new(0)) {|n, v| n[v] += 1; n }
    itemdupes.to_a.each do |value, count| 
      @text.draw "#{value} [#{count}]" if count > 1
      @text.draw value if count == 1
    end
    @text.draw("Equipped:") if $charinfo["equiped"] == nil
    @text.draw("Equipped:") unless $charinfo["equiped"] == nil
    @text.draw $charinfo["equiped"]
    @text.reset_pos
  end
  def intoinv(item)
    $charinfo["items"] << item
  end
  def putdown(item, room)
    worked = nil
    worked = true if $charinfo["items"].each {|k| $charinfo["items"].delete(item) if k == item}
    if worked 
      @text.draw("You put the #{value} down in the room")
      room.putinroom(value)
    else
      @text.draw("There is no #{value} in your inventory")
    end
  end
  def examine
    @text.draw("Which Item? ")
    item = gets.chomp
    gotitem = false
    $charinfo["items"].each {|v| gotitem = true if item == v}
    gotitem = true if item == $charinfo["equiped"]
    if gotitem == true 
      $items.each do |key, value|
        @text.draw("#{value[:name]} is type #{value[:type]} and it:\n #{value[:use]}") if value[:name] == item
      end
    elsif gotitem == false
      @text.draw("You cannot examine an item you do not have")
    end
  end
end 
