pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
dialogue = {}

-- started with DTB: https://www.lexaloffle.com/bbs/?tid=28465

local default_advance_button_id = 5

function dialogue:init(custom_advance_button_id)
    self.advance_button_id = custom_advance_button_id or default_advance_button_id

    self.style = {
        text_color = 7,
        text_line_height_pixels = 6,
        sfx_typewriter_0 = 0,
        sfx_typewriter_1 = 1,
        sfx_typewriter_2 = 2,
        sfx_typewriter_skip = 4,
        sfx_typewriter_skip_count = 0,
        sfx_next_line = 0,
        sfx_next_message = 0,
        period_typing_delay_frames = 6,

        bubble_padding_pixels_x = 4,
        bubble_block_size = 6,
        bubble_outline_color = 7,
        bubble_fill_color = 1,
        bubble_x_offset_char = 15,
        corner_sprite_id = 10,
        arrow_sprite_id = 12,
        flip_threshold_screen_x = 75,

        character_bubble = {
            min_width_tiles = 2,
            max_width_tiles = 8,
            max_lines = 4,
            line_wrap_chars = 10,
            hyphenate_word_len = 8
        },

        narrator_bubble = {
            min_width_tiles = 2,
            max_width_tiles = 13,
            max_lines = 4,
            line_wrap_chars = 18,
            hyphenate_word_len = 16
        }
    }

    self.pipeline = {}
    self:_reset_display_state()
end

function dialogue:_draw_bubble(x, y, w_tiles, h_tiles, flipped, narration)
    local block_size = self.style.bubble_block_size
    local outline_color = self.style.bubble_outline_color
    local fill_color = self.style.bubble_fill_color
    local x_offset_val = self.style.bubble_x_offset_char
    local corner_spr = self.style.corner_sprite_id
    local arrow_spr = self.style.arrow_sprite_id

    flipped = flipped or false

    pal(1, self.style.bubble_fill_color)
    pal(7, self.style.bubble_outline_color)

    if narration then
        x += peek2(0x5f28)
        y += peek2(0x5f2a)
    else
        y -= 8
        if flipped then
            x -= x_offset_val
        else
            x += x_offset_val
        end
    end
    h_tiles += 1

    local left_x, right_x
    if flipped then
        right_x = x
        left_x = x - (w_tiles - 1) * block_size
    else
        left_x = x
        right_x = x + (w_tiles - 1) * block_size
    end
    local top_y = y - (h_tiles - 1) * block_size

    for i = 1, w_tiles - 2 do
        local seg_x = left_x + i * block_size
        rectfill(seg_x, top_y, seg_x + block_size, top_y + block_size, fill_color)
        line(seg_x, top_y, seg_x + block_size, top_y, outline_color)
        rectfill(seg_x, y, seg_x + block_size, y + block_size, fill_color)
        line(seg_x, y + block_size, seg_x + block_size, y + block_size, outline_color)
    end

    for j = 1, h_tiles - 2 do
        local edge_y = top_y + j * block_size
        rectfill(left_x, edge_y, left_x + block_size, edge_y + block_size, fill_color)
        line(left_x, edge_y, left_x, edge_y + block_size, outline_color)
        rectfill(right_x, edge_y, right_x + block_size - 1, edge_y + block_size, fill_color)
        line(right_x + block_size - 1, edge_y, right_x + block_size - 1, edge_y + block_size, outline_color)
    end

    rectfill(
        left_x + block_size, top_y + block_size,
        left_x + block_size * (w_tiles - 1), top_y + block_size * (h_tiles - 1), fill_color
    )

    spr(corner_spr, left_x, top_y, 1, 1, false, false)
    spr(corner_spr, right_x - 2, top_y, 1, 1, true, false)

    if not narration then
        if not flipped then
            rectfill(left_x, y, left_x + block_size - 1, y + block_size - 1, fill_color)
            line(left_x, y + block_size, left_x + block_size - 1, y + block_size, outline_color)
            spr(corner_spr, right_x - 2, y - 1, 1, 1, true, true)
        else
            rectfill(right_x, y, right_x + block_size - 1, y + block_size - 1, fill_color)
            line(right_x, y + block_size, right_x + block_size - 1, y + block_size, outline_color)
            spr(corner_spr, left_x, y - 1, 1, 1, false, true)
        end
        if flipped then
            spr(arrow_spr, x + block_size - 1, y, 1, 1, true, false)
            pset(x + block_size - 1, y, outline_color)
        else
            spr(arrow_spr, x - block_size, y, 1, 1, false, false)
            pset(x, y, outline_color)
        end
    else
        spr(corner_spr, right_x - 2, y - 1, 1, 1, true, true)
        spr(corner_spr, left_x, y - 1, 1, 1, false, true)
    end

    pal()

    return top_y + 4, left_x + 4
end

function dialogue:_reset_display_state()
    self.display_lines_cache = {}

    local max_possible_lines = max(self.style.character_bubble.max_lines, self.style.narrator_bubble.max_lines)
    for i = 1, max_possible_lines do
        add(self.display_lines_cache, "")
    end

    self.current_line_index = 0
    self.typing_timer = 0
end

function dialogue:show(txt, speaker, callback, voice)
    local lines = {}
    local currline = ""
    local curword = ""

    local is_narration = false
    if speaker and speaker.name == "narrator" then
        is_narration = true
    end
    local current_text_style = is_narration and self.style.narrator_bubble or self.style.character_bubble
    local wrap_chars = current_text_style.line_wrap_chars
    local hyp_len = current_text_style.hyphenate_word_len

    for i = 1, #txt do
        local char = sub(txt, i, i)
        curword = curword .. char

        if char == " " or #curword > hyp_len then
            if char ~= " " and #curword > hyp_len then
                curword = curword .. "-"
            end
            if #curword + #currline > wrap_chars then
                add(lines, currline)
                currline = ""
            end
            currline = currline .. curword
            curword = ""
        end
    end

    if #curword > 0 then
        if #curword + #currline > wrap_chars then
            add(lines, currline)
            currline = curword
        else
            currline = currline .. curword
        end
    end
    if currline ~= "" then
        add(lines, currline)
    end

    local max_line_chars = 0
    for _, line_text in pairs(lines) do
        max_line_chars = max(max_line_chars, #line_text)
    end

    local text_pixel_width = max_line_chars * 4

    local total_content_pixel_width = text_pixel_width + (self.style.bubble_padding_pixels_x * 2)

    local required_tiles = ceil(total_content_pixel_width / self.style.bubble_block_size)

    local active_bubble_style = is_narration and self.style.narrator_bubble or self.style.character_bubble
    local calculated_w_tiles = max(active_bubble_style.min_width_tiles, min(active_bubble_style.max_width_tiles, required_tiles))

    local entry = {
        text_lines = lines,
        speaker_entity = speaker,
        on_finish_callback = callback or 0,
        is_narration = is_narration,
        calculated_width_tiles = calculated_w_tiles,
        voice = voice or { 63, 63 }
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
            if first_char ~= " " then sfx(rnd({ current_entry.voice[1], current_entry.voice[2] })) end
            if first_char == "." then self.typing_timer = self.style.period_typing_delay_frames end
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
                    self.style.sfx_typewriter_skip_count += 1
                    if self.style.sfx_typewriter_skip_count >= self.style.sfx_typewriter_skip then
                        self.style.sfx_typewriter_skip_count = 0
                        sfx(rnd({ current_entry.voice[1], current_entry.voice[2] }))
                    end
                end
                if next_char == "." then
                    self.typing_timer = self.style.period_typing_delay_frames
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

    if self.current_line_index == 0 then
        return
    end

    local current_entry = self.pipeline[1]
    if not current_entry or not current_entry.speaker_entity then
        if not (current_entry and current_entry.is_narration) then
            return
        end
    end

    local speaker = current_entry.speaker_entity
    local is_narration_flag = current_entry.is_narration
    local bubble_y_offset = 0

    local camera_x = peek2(0x5f28)
    local camera_y = peek2(0x5f2a)
    local screen_x = speaker.x - camera_x
    local screen_y = speaker.y - camera_y

    local current_bubble_style = is_narration_flag and self.style.narrator_bubble or self.style.character_bubble
    local bubble_w_tiles = current_entry.calculated_width_tiles
    local current_max_display_lines = current_bubble_style.max_lines

    local display_cache_actual_lines = #self.display_lines_cache

    local used_lines = 0
    for i = 1, display_cache_actual_lines do
        if self.display_lines_cache[i] != "" then
            used_lines += 1
        end
    end
    used_lines = min(used_lines, current_max_display_lines)

    local bubble_h_tiles = used_lines or 1
    local line_h_pixels = self.style.text_line_height_pixels
    local narration_offset = 0
    if is_narration_flag then
        narration_offset = used_lines * line_h_pixels
    end

    local flipped = false
    local bubble_render_x, bubble_render_y

    if is_narration_flag then
        bubble_render_x = speaker and speaker.x or 0
        bubble_render_y = speaker and speaker.y or 0
    else
        bubble_render_x = speaker.x
        bubble_render_y = speaker.y
        if screen_x > self.style.flip_threshold_screen_x then
            flipped = true
        end

        if screen_x < 0 then
            bubble_render_x = camera_x
        elseif screen_x > 128 then
            bubble_render_x = camera_x + 128
        end

        local bubble_y_screen_threshold = used_lines * line_h_pixels + 10

        if screen_y < bubble_y_screen_threshold then
            bubble_render_y = camera_y + bubble_y_screen_threshold
        elseif screen_y > 125 then
            bubble_render_y = camera_y + 125
        end
    end

    local final_bubble_y = bubble_render_y + narration_offset + bubble_y_offset

    local text_y, text_x = self:_draw_bubble(bubble_render_x, final_bubble_y, bubble_w_tiles, bubble_h_tiles, flipped, is_narration_flag)

    local line_number = 0
    for i = 1, display_cache_actual_lines do
        if self.display_lines_cache[i] != "" and line_number < current_max_display_lines then
            line_number += 1
            print(self.display_lines_cache[i], text_x, text_y + ((line_number - 1) * line_h_pixels), self.style.text_color)
        end
    end
end
