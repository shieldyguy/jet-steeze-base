pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
dialogue = {}

-- Default ID for the button used to advance dialogue.
local default_advance_button_id = 5

-- Method: init
-- Purpose: Initializes the dialogue system, setting up default styles and state.
-- Parameters:
--   custom_advance_button_id: (optional) number - Overrides the default advance button ID.
function dialogue:init(custom_advance_button_id)
    self.advance_button_id = custom_advance_button_id or default_advance_button_id

    -- Style configuration for the dialogue system.
    self.style = {
        text_color = 7, -- Default color for dialogue text.
        text_line_height_pixels = 6, -- Pixel height of a single line of text.

        sfx_typewriter_0 = 0, -- SFX ID for the character 1st typing sound.
        sfx_typewriter_1 = 1, -- SFX ID for the character 2nd typing sound.
        sfx_typewriter_2 = 2, -- SFX ID for the character 3rd typing sound.
        sfx_typewriter_skip = 4, -- how often to play the typewriter sfx.
        sfx_typewriter_skip_count = 0, -- keep track of how often we're palying the typewrite sfx.
        sfx_next_line = 0, -- SFX ID when advancing to a new line within the same message.
        sfx_next_message = 0, -- SFX ID when advancing to a new dialogue message.
        period_typing_delay_frames = 6, -- Extra delay (in frames) after typing a period.

        bubble_padding_pixels_x = 4, -- Horizontal padding (each side) inside the bubble before text.

        bubble_block_size = 6, -- Size (width/height) of the basic building block for bubbles in pixels.
        bubble_outline_color = 7, -- Color for the bubble's outline.
        bubble_fill_color = 1, -- Color for the bubble's fill.
        bubble_x_offset_char = 15, -- Horizontal offset from speaker for character speech bubbles.
        corner_sprite_id = 10, -- Sprite ID for bubble corners.
        arrow_sprite_id = 12, -- Sprite ID for the bubble's speech arrow.
        flip_threshold_screen_x = 75, -- Screen X-coordinate beyond which character bubbles flip direction.

        character_bubble = {
            min_width_tiles = 2, -- Minimum width of a character bubble in tiles.
            max_width_tiles = 8, -- Maximum width of a character bubble in tiles.
            max_lines = 4, -- Maximum number of lines displayed in a character bubble.
            line_wrap_chars = 10, -- Character count at which to wrap lines for character speech.
            hyphenate_word_len = 8 -- Minimum word length to consider for hyphenation in character speech.
        },

        narrator_bubble = {
            min_width_tiles = 2, -- Minimum width of a narrator bubble in tiles.
            max_width_tiles = 13, -- Maximum width of a narrator bubble in tiles.
            max_lines = 4, -- Maximum number of lines displayed in a narrator bubble.
            line_wrap_chars = 18, -- Character count at which to wrap lines for narration.
            hyphenate_word_len = 16 -- Minimum word length to consider for hyphenation in narration.
        }
    }

    self.pipeline = {}
    -- Queue for dialogue entries.
    self:_reset_display_state()
    -- Initialize display-related state variables.
end

-- Method: _draw_bubble
-- Purpose: Internal helper to draw the speech bubble background, corners, and arrow.
-- Parameters:
--   x: number - Anchor x-coordinate for the bubble.
--   y: number - Anchor y-coordinate for the bubble.
--   w_tiles: number - Calculated width of the bubble in tiles.
--   h_tiles: number - Calculated height of the bubble in tiles.
--   flipped: boolean - If true, the bubble arrow points right (for speakers on the right).
--   narration: boolean - If true, applies narration-specific positioning and no arrow.
-- Returns: number, number - The x and y coordinates where text printing should begin.
function dialogue:_draw_bubble(x, y, w_tiles, h_tiles, flipped, narration)
    -- Retrieve style properties for drawing the bubble itself.
    local block_size = self.style.bubble_block_size
    local outline_color = self.style.bubble_outline_color
    local fill_color = self.style.bubble_fill_color
    local x_offset_val = self.style.bubble_x_offset_char
    -- Used for character bubbles.
    local corner_spr = self.style.corner_sprite_id
    local arrow_spr = self.style.arrow_sprite_id

    flipped = flipped or false

    -- swap colors, this can get hairy!
    pal(1, self.style.bubble_fill_color)
    pal(7, self.style.bubble_outline_color)

    -- Adjust bubble position based on whether it's narration or character speech.
    if narration then
        -- Narration bubbles are pinned to screen space using camera coordinates.
        x += peek2(0x5f28)
        y += peek2(0x5f2a)
    else
        -- Character bubbles are offset from the speaker's position.
        y -= 8
        if flipped then
            x -= x_offset_val
        else
            x += x_offset_val
        end
    end
    h_tiles += 1
    -- Original logic for height adjustment based on content lines.

    -- Establish bubble boundaries in pixel space.
    local left_x, right_x
    if flipped then
        right_x = x
        left_x = x - (w_tiles - 1) * block_size
    else
        left_x = x
        right_x = x + (w_tiles - 1) * block_size
    end
    local top_y = y - (h_tiles - 1) * block_size

    -- Draw top and bottom edges of the bubble.
    for i = 1, w_tiles - 2 do
        local seg_x = left_x + i * block_size
        rectfill(seg_x, top_y, seg_x + block_size, top_y + block_size, fill_color)
        line(seg_x, top_y, seg_x + block_size, top_y, outline_color)
        rectfill(seg_x, y, seg_x + block_size, y + block_size, fill_color)
        line(seg_x, y + block_size, seg_x + block_size, y + block_size, outline_color)
    end

    -- Draw left and right edges of the bubble.
    for j = 1, h_tiles - 2 do
        local edge_y = top_y + j * block_size
        rectfill(left_x, edge_y, left_x + block_size, edge_y + block_size, fill_color)
        line(left_x, edge_y, left_x, edge_y + block_size, outline_color)
        rectfill(right_x, edge_y, right_x + block_size - 1, edge_y + block_size, fill_color)
        line(right_x + block_size - 1, edge_y, right_x + block_size - 1, edge_y + block_size, outline_color)
    end

    -- Fill the center of the bubble.
    rectfill(
        left_x + block_size, top_y + block_size,
        left_x + block_size * (w_tiles - 1), top_y + block_size * (h_tiles - 1), fill_color
    )

    -- Draw corner sprites.
    spr(corner_spr, left_x, top_y, 1, 1, false, false)
    -- Top-left
    spr(corner_spr, right_x - 2, top_y, 1, 1, true, false)
    -- Top-right

    -- Draw bottom corners and arrow (if not narration).
    if not narration then
        if not flipped then
            -- Arrow on left
            rectfill(left_x, y, left_x + block_size - 1, y + block_size - 1, fill_color) -- Flat bottom-left for arrow overlap
            line(left_x, y + block_size, left_x + block_size - 1, y + block_size, outline_color)
            spr(corner_spr, right_x - 2, y - 1, 1, 1, true, true) -- Sprite bottom-right
        else
            -- Arrow on right
            rectfill(right_x, y, right_x + block_size - 1, y + block_size - 1, fill_color) -- Flat bottom-right for arrow overlap
            line(right_x, y + block_size, right_x + block_size - 1, y + block_size, outline_color)
            spr(corner_spr, left_x, y - 1, 1, 1, false, true) -- Sprite bottom-left
        end
        -- Draw the arrow sprite.
        if flipped then
            spr(arrow_spr, x + block_size - 1, y, 1, 1, true, false)
            pset(x + block_size - 1, y, outline_color) -- Arrow tip outline fix
        else
            spr(arrow_spr, x - block_size, y, 1, 1, false, false)
            pset(x, y, outline_color) -- Arrow tip outline fix
        end
    else
        -- Narration bubble (no arrow, both bottom corners are sprites)
        spr(corner_spr, right_x - 2, y - 1, 1, 1, true, true) -- Bottom-right
        spr(corner_spr, left_x, y - 1, 1, 1, false, true) -- Bottom-left
    end

    -- restore default palette
    pal()

    -- Return the coordinates for where the text should start printing.
    return top_y + 4, left_x + 4
end

-- Method: _reset_display_state
-- Purpose: Internal helper to reset variables related to the current message being displayed.
--          Called when initializing or moving to a new message.
function dialogue:_reset_display_state()
    self.display_lines_cache = {}
    -- Lines currently visible on screen (built up by typing effect).

    -- Ensure cache is large enough for either narrator or character max lines.
    local max_possible_lines = max(self.style.character_bubble.max_lines, self.style.narrator_bubble.max_lines)
    for i = 1, max_possible_lines do
        add(self.display_lines_cache, "")
    end

    self.current_line_index = 0
    -- Index of the line within the current message being typed/displayed.
    self.typing_timer = 0
    -- Timer controlling the speed of the typing effect.
end

-- Method: show
-- Purpose: Adds a new dialogue message to the processing queue.
-- Parameters:
--   txt: string - The raw text to be displayed.
--   speaker: table - The entity speaking (must have .x, .y, and .name properties).
--                    If speaker.name == "narrator", it's treated as narration.
--   callback: (optional) function - A function to call when this dialogue message concludes.
--   voice: (optional) table - A table containing two SFX IDs for the voice of the speaker.
function dialogue:show(txt, speaker, callback, voice)
    local lines = {}
    -- Stores the processed, wrapped lines of text.
    local currline = ""
    -- The current line being built.
    local curword = ""
    -- The current word being built.

    -- Determine if this is narration and select the appropriate style for text processing.
    local is_narration = false
    if speaker and speaker.name == "narrator" then
        is_narration = true
    end
    local current_text_style = is_narration and self.style.narrator_bubble or self.style.character_bubble
    local wrap_chars = current_text_style.line_wrap_chars
    local hyp_len = current_text_style.hyphenate_word_len

    -- Process the input text character by character to implement line wrapping and hyphenation.
    for i = 1, #txt do
        local char = sub(txt, i, i)
        curword = curword .. char

        -- Check if the current word needs to be processed (due to space or exceeding hyphenation length).
        if char == " " or #curword > hyp_len then
            -- If the word is being broken due to length (not space) and meets hyphenation criteria, add a hyphen.
            if char ~= " " and #curword > hyp_len then
                curword = curword .. "-"
            end
            -- If the current word won't fit on the current line, add the current line to the list and start a new one.
            if #curword + #currline > wrap_chars then
                add(lines, currline)
                currline = ""
            end
            -- Add the processed word to the current line.
            currline = currline .. curword
            curword = "" -- Reset for the next word.
        end
    end

    -- Add any remaining part of the last word or current line.
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

    -- Calculate dynamic width for this message entry using precise PICO-8 font metrics.
    local max_line_chars = 0
    for _, line_text in pairs(lines) do
        max_line_chars = max(max_line_chars, #line_text)
    end

    -- Each character effectively takes 4 pixels (3px char width + 1px space).
    local text_pixel_width = max_line_chars * 4

    -- Add configured horizontal padding from style.
    local total_content_pixel_width = text_pixel_width + (self.style.bubble_padding_pixels_x * 2)

    -- Calculate required tiles based on bubble block size.
    local required_tiles = ceil(total_content_pixel_width / self.style.bubble_block_size)

    -- Clamp the calculated tiles to the min/max defined in the style.
    local active_bubble_style = is_narration and self.style.narrator_bubble or self.style.character_bubble
    local calculated_w_tiles = max(active_bubble_style.min_width_tiles, min(active_bubble_style.max_width_tiles, required_tiles))

    -- Create the dialogue entry table.
    local entry = {
        text_lines = lines,
        speaker_entity = speaker,
        on_finish_callback = callback or 0,
        is_narration = is_narration,
        calculated_width_tiles = calculated_w_tiles, -- Store the calculated width.
        voice = voice or { 63, 63 }
    }
    add(self.pipeline, entry)
    -- Add the entry to the dialogue queue.
end

-- Method: _next_line_in_message
-- Purpose: Internal helper to advance the display to the next line within the current dialogue message.
--          Handles scrolling existing lines up and starting the typing effect for the new line.
function dialogue:_next_line_in_message()
    self.current_line_index += 1
    -- Scroll existing displayed lines up.
    for i = 1, #self.display_lines_cache - 1 do
        self.display_lines_cache[i] = self.display_lines_cache[i + 1]
    end

    local current_entry = self.pipeline[1]
    -- If there's a valid next line, start displaying its first character.
    if current_entry and self.current_line_index <= #current_entry.text_lines and #current_entry.text_lines[self.current_line_index] > 0 then
        self.display_lines_cache[#self.display_lines_cache] = sub(current_entry.text_lines[self.current_line_index], 1, 1)
        self.typing_timer = 1 -- Reset typing timer for the new character.
    else
        -- No more lines or current line is empty, clear the last display slot.
        self.display_lines_cache[#self.display_lines_cache] = ""
    end
    --sfx(self.style.sfx_next_line)
    -- Play sound for line advance.
end

-- Method: _next_message_in_pipeline
-- Purpose: Internal helper to conclude the current dialogue message and move to the next one in the queue.
--          Executes callback, removes current message, resets display state, and plays SFX.
function dialogue:_next_message_in_pipeline()
    local current_entry = self.pipeline[1]
    -- Execute callback if one exists for the concluding message.
    if current_entry and current_entry.on_finish_callback ~= 0 then
        current_entry.on_finish_callback()
    end
    -- Remove the concluded message from the pipeline.
    if #self.pipeline > 0 then
        del(self.pipeline, self.pipeline[1])
    end
    self:_reset_display_state()
    -- Prepare for the next message or idle state.
    --sfx(self.style.sfx_next_message)
    -- Play sound for message advance.
end

-- Method: update
-- Purpose: Updates the dialogue state each frame. Handles typing animation, line advancement,
--          and message advancement based on player input or completed typing.
function dialogue:update()
    if #self.pipeline == 0 then return end
    -- Nothing to do if the dialogue queue is empty.

    local current_entry = self.pipeline[1]

    -- Initialize display for a newly started message.
    if self.current_line_index == 0 then
        self.current_line_index = 1 -- Start with the first line.
        -- Check if the first line has text to start the typing effect.
        if current_entry and #current_entry.text_lines > 0 and #current_entry.text_lines[1] > 0 then
            local first_line_text = current_entry.text_lines[1]
            local first_char = sub(first_line_text, 1, 1)
            self.display_lines_cache[#self.display_lines_cache] = first_char -- Display first character.
            self.typing_timer = 1
            if first_char ~= " " then sfx(rnd({ current_entry.voice[1], current_entry.voice[2] })) end
            if first_char == "." then self.typing_timer = self.style.period_typing_delay_frames end
        elseif current_entry and #current_entry.text_lines > 0 then
            -- First line is empty, but other lines exist; try to advance to the next line.
            self:_next_line_in_message()
        else
            -- No text lines in this entry, clear the display cache.
            self.display_lines_cache[#self.display_lines_cache] = ""
        end
    end

    -- Early exit if current entry/text is invalid or line index is out of bounds, but allow advancing.
    if not current_entry or not current_entry.text_lines or self.current_line_index == 0 or self.current_line_index > #current_entry.text_lines then
        if btnp(self.advance_button_id) then
            self:_next_message_in_pipeline()
        end
        return
    end

    -- Variables for current line processing.
    local cache_last_line_idx = #self.display_lines_cache
    local source_text_lines = current_entry.text_lines
    local current_display_line_text = self.display_lines_cache[cache_last_line_idx]
    local current_source_line_text = source_text_lines[self.current_line_index]
    local current_display_line_length = #current_display_line_text

    -- Check completion states.
    local is_current_line_fully_typed = current_display_line_length >= #current_source_line_text
    local is_last_line_of_message = self.current_line_index >= #source_text_lines

    -- Handle state based on whether the entire message is typed.
    if is_current_line_fully_typed and is_last_line_of_message then
        -- Entire message is displayed, wait for advance button.
        if btnp(self.advance_button_id) then
            self:_next_message_in_pipeline()
            return
        end
    elseif self.current_line_index > 0 and self.current_line_index <= #source_text_lines then
        -- Message is not fully displayed; handle typing or line advancement.
        self.typing_timer -= 1
        if not is_current_line_fully_typed then
            -- Current line is not yet fully typed, continue typing effect.
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
            -- If advance button is pressed during typing, complete the current line instantly.
            if btnp(self.advance_button_id) then
                self.display_lines_cache[cache_last_line_idx] = current_source_line_text
                self.typing_timer = 0 -- Stop further typing on this line for this frame.
            end
        else
            -- Current line is complete, but not the last line of the message; advance to next line.
            self:_next_line_in_message()
        end
    end
end

-- Method: draw
-- Purpose: Draws the active dialogue bubble and its text on screen.
function dialogue:draw()
    if #self.pipeline == 0 then return end
    -- No dialogue to draw.

    local current_entry = self.pipeline[1]
    -- Ensure there is a speaker entity for character dialogue.
    if not current_entry or not current_entry.speaker_entity then
        if not (current_entry and current_entry.is_narration) then
            -- Allow narration if speaker is nil but is_narration is true
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

    -- Determine bubble style and dimensions based on narration status and pre-calculated width.
    local current_bubble_style = is_narration_flag and self.style.narrator_bubble or self.style.character_bubble
    local bubble_w_tiles = current_entry.calculated_width_tiles
    -- Use pre-calculated dynamic width.
    local current_max_display_lines = current_bubble_style.max_lines

    local display_cache_actual_lines = #self.display_lines_cache

    -- Calculate number of lines currently used in the display cache.
    local used_lines = 0
    for i = 1, display_cache_actual_lines do
        if self.display_lines_cache[i] != "" then
            used_lines += 1
        end
    end
    used_lines = min(used_lines, current_max_display_lines)
    -- Cap by the styled max lines for this bubble type.

    local bubble_h_tiles = used_lines or 1
    -- Ensure at least 1 tile high.
    local line_h_pixels = self.style.text_line_height_pixels
    local narration_offset = 0
    -- Apply vertical offset for narration bubble (often placed higher or lower).
    if is_narration_flag then
        narration_offset = used_lines * line_h_pixels -- Example offset, adjust as needed in style or logic.
    end

    local flipped = false
    -- For character bubble arrow direction.
    local bubble_render_x, bubble_render_y

    -- Determine base render position for the bubble.
    if is_narration_flag then
        -- Narration uses speaker object's x/y, but _draw_bubble applies camera offset.
        bubble_render_x = speaker and speaker.x or 0 -- Fallback if narrator object somehow nil
        bubble_render_y = speaker and speaker.y or 0
    else
        bubble_render_x = speaker.x
        bubble_render_y = speaker.y
        -- Check if character bubble needs to be flipped.
        if screen_x > self.style.flip_threshold_screen_x then
            flipped = true
        end

        -- Keep bubble in screen
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

    -- Draw the bubble background.
    local text_y, text_x = self:_draw_bubble(bubble_render_x, final_bubble_y, bubble_w_tiles, bubble_h_tiles, flipped, is_narration_flag)

    -- Print the text lines within the bubble.
    local line_number = 0
    for i = 1, display_cache_actual_lines do
        -- Only print lines that have content and are within the allowed max lines for this bubble.
        if self.display_lines_cache[i] != "" and line_number < current_max_display_lines then
            line_number += 1
            print(self.display_lines_cache[i], text_x, text_y + ((line_number - 1) * line_h_pixels), self.style.text_color)
        end
    end
end
