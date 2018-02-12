class Character
  def initialize(text)
    @text = text
  end
  def change_name
    $com.clear
    @text.reset_pos
    @text.draw("Character name? => ") #input text
    @name = $com.getstr() #get input

    $charinfo[:name] = @name #Modify
    File.open('characters.yaml', 'w') {|f| f.write $charinfo.to_yaml } 
    @text.draw("Hello #{@name}") #show to player the name
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
  def putdown(item)
    return true if $charinfo["items"].each {|k| $charinfo["items"].delete(item) if k == item}
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
