class Room
  def initialize(text)
    @text = text
  end
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
    @text.draw("You cannot go in this direction") if cango == false
    @text.draw("You go #{dir}") if cango == true
  end
  def room_in_desc
    @text.reset_pos()
    @text.draw("You are in the #{$roominfo[$general_info["current_room"]][:name]}")
    @text.draw("Items in room: ")
    if $roominfo[$general_info["current_room"]]["items"] != nil
      $roominfo[$general_info["current_room"]]["items"].each do |k| 
        @text.draw(k)
      end
    end
    $roominfo[$general_info["current_room"]][:exits].each {|k, v| @text.draw("There is the #{k} to the #{v}")}
    @text.reset_pos()
  end
  def pickup(item, character)
    items = $roominfo[$general_info["current_room"]]["items"]
    exists = items.include? item
    if exists
      items.delete item
      @text.draw("You put #{item} into your inventory.")
      character.intoinv(item)
    else
      @text.draw("There is no #{value} in this room")
    end 
    
  end
  def putinroom(item)
    $roominfo[$general_info["current_room"]]["items"] << item
  end
end 
