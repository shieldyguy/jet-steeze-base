-- pico-8 cartridge // http://www.pico-8.com
-- version 42
__lua__

local default_advance_button_id = 5
local default_num_display_lines = 3

dialogue = {
    sfx_typewriter = 0
}

narrator = {
    name = "narrator",
    x = 8,
    y = 10
}

-- Local helper function for drawing the bubble
-- (formerly _dtb_draw_bubble, renamed and made local)
local function _draw_bubble(x, y, w, h, flipped, narration)
    local block_size = 6
    local outline_color = 7
    local fill_color = 1
    local x_offset = 15
    flipped = flipped or false

    if narration then
        x += peek2(0x5f28)
        y += peek2(0x5f2a)
    else
        y -= 8
        if flipped then
            x -= x_offset
        else
            x += x_offset
        end
    end
    h += 1

    -- establish left and right limits in pixel space
    local left_x, right_x
    if flipped then
        right_x = x -- anchor is bottom‑right
        left_x = x - (w - 1) * block_size
    else
        left_x = x -- anchor is bottom‑left
        right_x = x + (w - 1) * block_size
    end
    local top_y = y - (h - 1) * block_size

    -----------------------------------------------------------------------
    --  top & bottom edges
    -----------------------------------------------------------------------
    for i = 1, w - 2 do
        local seg_x = left_x + i * block_size
        -- top edge
        rectfill(seg_x, top_y, seg_x + block_size, top_y + block_size, fill_color)
        line(seg_x, top_y, seg_x + block_size, top_y, outline_color)
        -- bottom edge
        rectfill(seg_x, y, seg_x + block_size, y + block_size, fill_color)
        line(seg_x, y + block_size, seg_x + block_size, y + block_size, outline_color)
    end

    -----------------------------------------------------------------------
    --  left & right edges
    -----------------------------------------------------------------------
    for j = 1, h - 2 do
        local edge_y = top_y + j * block_size
        -- left edge
        rectfill(left_x, edge_y, left_x + block_size, edge_y + block_size, fill_color)
        line(left_x, edge_y, left_x, edge_y + block_size, outline_color)
        -- right edge
        rectfill(right_x, edge_y, right_x + block_size - 1, edge_y + block_size, fill_color)
        line(right_x + block_size - 1, edge_y, right_x + block_size - 1, edge_y + block_size, outline_color)
    end

    -----------------------------------------------------------------------
    --  centre fill
    -----------------------------------------------------------------------
    rectfill(
        left_x + block_size, top_y + block_size,
        left_x + block_size * (w - 1), top_y + block_size * (h - 1), fill_color
    )

    -----------------------------------------------------------------------
    --  corners
    -----------------------------------------------------------------------

    -- top corners (unchanged)
    spr(10, left_x, top_y, 1, 1, false, false)
    -- top‑left
    spr(10, right_x - 2, top_y, 1, 1, true, false)
    -- top‑right

    if not narration then
        if not flipped then
            -- ░░ arrow‑on‑left layout ░░
            -- bottom‑left = flat corner for arrow overlap
            rectfill(left_x, y, left_x + block_size - 1, y + block_size - 1, fill_color)
            line(left_x, y + block_size, left_x + block_size - 1, y + block_size, outline_color)
            -- bottom‑right = sprite corner
            spr(10, right_x - 2, y - 1, 1, 1, true, true)
        else
            -- ░░ arrow‑on‑right layout ░░
            -- bottom‑right = flat corner for arrow overlap
            rectfill(right_x, y, right_x + block_size - 1, y + block_size - 1, fill_color)
            line(right_x, y + block_size, right_x + block_size - 1, y + block_size, outline_color)
            -- bottom‑left = sprite corner
            spr(10, left_x, y - 1, 1, 1, false, true)
        end

        -----------------------------------------------------------------------
        --  arrow
        -----------------------------------------------------------------------
        if flipped then
            -- arrow sprite mirrored horizontally, sits just to the right
            spr(12, x + block_size - 1, y, 1, 1, true, false)
            pset(x + block_size - 1, y, outline_color)
        else
            -- original left‑pointing arrow
            spr(12, x - block_size, y, 1, 1, false, false)
            pset(x, y, outline_color)
        end
    else
        -- bottom‑right = sprite corner
        spr(10, right_x - 2, y - 1, 1, 1, true, true)
        -- bottom‑left = sprite corner
        spr(10, left_x, y - 1, 1, 1, false, true)
    end

    return top_y + 4, left_x + 4
end


function dialogue:init(num_lines_override, advance_button_override)
    self.num_display_lines = num_lines_override or default_num_display_lines
    self.advance_button_id = advance_button_override or default_advance_button_id
    self.pipeline = {}
    self:_reset_display_state()
end

function dialogue:_reset_display_state()
    self.display_lines_cache = {}
    for i = 1, self.num_display_lines do
        add(self.display_lines_cache, "")
    end
    self.current_line_index = 0
    self.typing_timer = 0
end

function dialogue:show(txt, speaker, callback)
    local lines = {}
    local currline = ""
    local curword = ""

    for i = 1, #txt do
        local char = sub(txt, i, i)
        curword = curword .. char

        if char == " " or #curword > 15 then
            if char ~= " " and #curword > 15 then
                curword = curword .. "-"
            end
            if #curword + #currline > 10 then
                add(lines, currline)
                currline = ""
            end
            currline = currline .. curword
            curword = ""
        end
    end

    if #curword > 0 then
        if #curword + #currline > 10 then
            add(lines, currline)
            currline = curword
        else
            currline = currline .. curword
        end
    end

    if currline ~= "" then
        add(lines, currline)
    end

    local is_narration = false
    if speaker and speaker.name == "narrator" then
        is_narration = true
    end

    local entry = {
        text_lines = lines,
        speaker_entity = speaker, 
        on_finish_callback = callback or 0,
        is_narration = is_narration
    }
    add(self.pipeline, entry)
end

function dialogue:_next_line_in_message()
    self.current_line_index += 1
    for i = 1, #self.display_lines_cache - 1 do
        self.display_lines_cache[i] = self.display_lines_cache[i + 1]
    end

    local current_entry = self.pipeline[1]
    if current_entry and self.current_line_index <= #current_entry.text_lines and #current_entry.text_lines[self.current_line_index] > 0 then
        self.display_lines_cache[#self.display_lines_cache] = sub(current_entry.text_lines[self.current_line_index], 1, 1)
        self.typing_timer = 1
    else
        self.display_lines_cache[#self.display_lines_cache] = ""
    end
end

function dialogue:_next_message_in_pipeline()
    local current_entry = self.pipeline[1]
    if current_entry and current_entry.on_finish_callback ~= 0 then
        current_entry.on_finish_callback()
    end
    if #self.pipeline > 0 then
        del(self.pipeline, self.pipeline[1])
    end
    self:_reset_display_state()
end

function dialogue:update()
    if #self.pipeline == 0 then return end

    local current_entry = self.pipeline[1]

    if self.current_line_index == 0 then 
        self.current_line_index = 1
        if current_entry and #current_entry.text_lines > 0 and #current_entry.text_lines[1] > 0 then
            local first_line_text = current_entry.text_lines[1]
            local first_char = sub(first_line_text, 1, 1)
            self.display_lines_cache[#self.display_lines_cache] = first_char
            self.typing_timer = 1
            if first_char ~= " " then sfx(0) end
            if first_char == "." then self.typing_timer = 6 end
        elseif current_entry and #current_entry.text_lines > 0 then 
             self:_next_line_in_message()
        else 
            self.display_lines_cache[#self.display_lines_cache] = ""
        end
    end

    if not current_entry or not current_entry.text_lines or self.current_line_index == 0 or self.current_line_index > #current_entry.text_lines then
        if btnp(self.advance_button_id) then
            self:_next_message_in_pipeline()
        end
        return
    end
    
    local cache_last_line_idx = #self.display_lines_cache
    local source_text_lines = current_entry.text_lines 
    local current_display_line_text = self.display_lines_cache[cache_last_line_idx]
    local current_source_line_text = source_text_lines[self.current_line_index]
    local current_display_line_length = #current_display_line_text
    
    local is_current_line_fully_typed = current_display_line_length >= #current_source_line_text
    local is_last_line_of_message = self.current_line_index >= #source_text_lines

    if is_current_line_fully_typed and is_last_line_of_message then
        if btnp(self.advance_button_id) then
            self:_next_message_in_pipeline()
            return
        end
    elseif self.current_line_index > 0 and self.current_line_index <= #source_text_lines then 
        self.typing_timer -= 1
        if not is_current_line_fully_typed then
            if self.typing_timer <= 0 then
                local next_char_index = current_display_line_length + 1
                local next_char = sub(current_source_line_text, next_char_index, next_char_index)
                self.typing_timer = 1
                if next_char ~= " " then
                    sfx(0)
                end
                if next_char == "." then
                    self.typing_timer = 6
                end
                self.display_lines_cache[cache_last_line_idx] = current_display_line_text .. next_char
            end
            if btnp(self.advance_button_id) then
                self.display_lines_cache[cache_last_line_idx] = current_source_line_text
                self.typing_timer = 0 
            end
        else 
            self:_next_line_in_message()
        end
    end
end

function dialogue:draw()
    if #self.pipeline == 0 then return end

    local current_entry = self.pipeline[1]
    local speaker = current_entry.speaker_entity 
    local is_narration_flag = current_entry.is_narration
    
    local dislineslength = #self.display_lines_cache
    local flipped = false
    local bubble_render_x, bubble_render_y

    if not speaker then
      if is_narration_flag then
        -- Narration without a specific speaker entity (e.g. centered on screen)
        -- _draw_bubble handles camera offset for narration based on its 'narration' param
        bubble_render_x = 0 -- Placeholder, _draw_bubble logic for narration takes over
        bubble_render_y = 0 -- Placeholder
      else 
        -- Character dialogue MUST have a speaker
        return 
      end
    else
      bubble_render_x = speaker.x 
      bubble_render_y = speaker.y 
      if not is_narration_flag then
          local camera_x = peek2(0x5f28)
          local screen_x = speaker.x - camera_x
          if screen_x > 75 then
              flipped = true
          end
      end
    end

    local used_lines = 0
    for i = 1, dislineslength do
        if self.display_lines_cache[i] != "" then
            used_lines += 1
        end
    end

    local bubble_height = used_lines or 1 
    local bubble_width = 8 
    local line_height = 6
    local narration_offset = 0
    if is_narration_flag then
        narration_offset = used_lines * line_height
    end
    
    local final_bubble_y = bubble_render_y + narration_offset
    
    local text_y, text_x = _draw_bubble(bubble_render_x, final_bubble_y, bubble_width, bubble_height, flipped, is_narration_flag)

    local line_number = 0
    for i = 1, dislineslength do
        if self.display_lines_cache[i] != "" then
            line_number += 1
            print(self.display_lines_cache[i], text_x, text_y + ((line_number - 1) * line_height), 7)
        end
    end
end
