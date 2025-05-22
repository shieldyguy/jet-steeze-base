pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- started with DTB: https://www.lexaloffle.com/bbs/?tid=28465

dialogue = {}

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
        bubble_x_offset_char = 15, -- Distance from tail anchor to bubble body edge
        corner_sprite_id = 10,
        arrow_sprite_id = 12,
        arrow_sprite_width_px = 6, -- Width of the arrow sprite/graphic
        flip_threshold_screen_x = 64,
        no_arrow_gap_above_speaker = 6, -- Gap for no-arrow mode

        character_bubble = {
            min_width_tiles = 2,
            max_width_tiles = 8,
            max_lines = 4,
            line_wrap_chars = 10,
            hyphenate_word_len = 10
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

-- Helper: Get screen extents of the bubble's main rectangular body
-- tail_anchor_x is the world X-coordinate where the tail conceptually attaches
function get_bubble_body_screen_extents(tail_anchor_x, is_flipped, w_tiles, x_offset, block_size, cam_x)
    local body_left_world, body_right_world
    if is_flipped then
        -- Body left, arrow right
        body_right_world = tail_anchor_x - x_offset
        body_left_world = body_right_world - (w_tiles - 1) * block_size
    else
        -- Body right, arrow left
        body_left_world = tail_anchor_x + x_offset
        body_right_world = body_left_world + w_tiles * block_size
    end
    return {
        left = body_left_world - cam_x,
        right = body_right_world - cam_x,
        world_left = body_left_world,
        world_right = body_right_world
    }
end

-- Helper: Get screen extents of the full bubble including the arrow
function get_full_bubble_screen_extents(tail_anchor_x, is_flipped, w_tiles, x_offset, block_size, arrow_width, cam_x)
    local body_extents = get_bubble_body_screen_extents(tail_anchor_x, is_flipped, w_tiles, x_offset, block_size, 0)
    -- Pass 0 for cam_x as it's about world coords here
    local full_left_world, full_right_world

    if is_flipped then
        -- Body left, arrow points right
        full_left_world = body_extents.world_left
        -- Arrow tip is at tail_anchor_x if arrow_width is 0, or extends beyond if arrow_width is actual width.
        -- Original arrow sprite logic suggests arrow is placed relative to anchor.
        -- For extent checking, let's assume arrow visually extends from anchor.
        full_right_world = tail_anchor_x + arrow_width / 2 -- Approximate center of arrow
    else
        -- Body right, arrow points left
        full_left_world = tail_anchor_x - arrow_width / 2 -- Approximate center of arrow
        full_right_world = body_extents.world_right
    end
    return {
        left = full_left_world - cam_x,
        right = full_right_world - cam_x,
        world_left = full_left_world,
        world_right = full_right_world
    }
end

function dialogue:_draw_bubble(render_x, render_y, w_tiles, h_text_lines, is_flipped_for_side_arrow, is_narration_flag, arrow_mode)
    local block_size = self.style.bubble_block_size
    local outline_color = self.style.bubble_outline_color
    local fill_color = self.style.bubble_fill_color
    local corner_spr = self.style.corner_sprite_id
    local arrow_spr = self.style.arrow_sprite_id
    local padding_x = self.style.bubble_padding_pixels_x
    local x_offset_from_anchor = self.style.bubble_x_offset_char

    pal(1, fill_color)
    pal(7, outline_color)

    -- These 'j_' prefixed variables are intended to directly map to the local variables
    -- (x, y, left_x, right_x, top_y, h_tiles) used within the drawing logic of the
    -- original jetski/_draw_bubble, after its initial coordinate setup.
    local j_x_eff
    -- The effective 'x' for jetski logic (used for arrow & deriving left/right_x)
    local j_y_eff
    -- The effective 'y' for jetski logic (Y-level of the bottom row of bubble)
    local j_h_tiles_eff = h_text_lines + 1
    local j_left_x_abs, j_right_x_abs, j_top_y_abs

    if is_narration_flag then
        local cam_adj_x = peek2(0x5f28)
        local cam_adj_y = peek2(0x5f2a)
        j_x_eff = render_x + cam_adj_x -- render_x is world top-left
        j_y_eff = render_y + cam_adj_y -- render_y is world top-left

        j_left_x_abs = j_x_eff
        j_right_x_abs = j_x_eff + (w_tiles - 1) * block_size
        j_top_y_abs = j_y_eff
        -- In jetski, for narration, 'top_y' was 'y - (h_tiles - 1) * block_size'.
        -- Since 'y' became the top-left after camera adjustment, and h_tiles was 1 more than text lines,
        -- if h_text_lines = 0 (1 line total bubble), h_tiles_eff = 1. top_y = y. Correct.
        -- if h_text_lines = 1 (2 lines total bubble), h_tiles_eff = 2. top_y = y - block_size.
        -- This implies that for narration, j_y_eff should be the Y for the *bottom* row,
        -- and j_top_y_abs is calculated from it.
        -- Let's reconsider: jetski narration: x,y = cam adjusted top-left. h_tiles++. top_y = y-(h_tiles-1)*bs.
        -- So, if render_y is top-left for narrator:
        j_top_y_abs = render_y + cam_adj_y
        j_y_eff = j_top_y_abs + (j_h_tiles_eff - 1) * block_size -- This is the Y for the bottom row elements for narrator
        -- effectively, the original 'y' passed to jetski loops for narrator
        -- was the top_left_y of the whole bubble.
    elseif arrow_mode == 'none' then
        local body_width_px = w_tiles * block_size
        j_left_x_abs = flr(render_x - body_width_px / 2) -- render_x is world center_x
        j_top_y_abs = render_y -- render_y is world top_y
        j_right_x_abs = j_left_x_abs + (w_tiles - 1) * block_size
        j_y_eff = j_top_y_abs + (j_h_tiles_eff - 1) * block_size -- Y-level of the bottom row
        j_x_eff = j_left_x_abs -- Not really used for arrow, but for consistency with jetski's 'x'
        -- For 'none' mode, the 'flipped' status is irrelevant for drawing the basic box.
    elseif arrow_mode == 'side' then
        j_y_eff = render_y - 8 -- render_y is world tail_anchor_y. This is jetski 'y'
        if is_flipped_for_side_arrow then
            j_x_eff = render_x - x_offset_from_anchor -- render_x is world tail_anchor_x. This is jetski 'x'
            j_right_x_abs = j_x_eff
            j_left_x_abs = j_x_eff - (w_tiles - 1) * block_size
        else
            j_x_eff = render_x + x_offset_from_anchor
            j_left_x_abs = j_x_eff
            j_right_x_abs = j_x_eff + (w_tiles - 1) * block_size
        end
        j_top_y_abs = j_y_eff - (j_h_tiles_eff - 1) * block_size
    end

    -- === Start of drawing logic based on jetski/dialogue.p8 ===
    -- (Using j_left_x_abs, j_right_x_abs, j_top_y_abs, j_y_eff, j_h_tiles_eff, j_x_eff)

    -- Horizontal segments
    -- In jetski, loop was w_tiles-2. If w_tiles is 1 or 2, loop doesn't run.
    for i = 1, w_tiles - 2 do
        local seg_x = j_left_x_abs + i * block_size
        -- Top edge of middle segment
        rectfill(seg_x, j_top_y_abs, seg_x + block_size - 1, j_top_y_abs + block_size - 1, fill_color)
        line(seg_x, j_top_y_abs, seg_x + block_size - 1, j_top_y_abs, outline_color)
        -- Bottom edge of middle segment
        rectfill(seg_x, j_y_eff, seg_x + block_size - 1, j_y_eff + block_size - 1, fill_color)
        line(seg_x, j_y_eff + block_size, seg_x + block_size - 1, j_y_eff + block_size, outline_color)
    end

    -- Vertical segments
    -- In jetski, loop was h_tiles-2. (j_h_tiles_eff is already h_tiles+1 from text lines)
    for i = 1, j_h_tiles_eff - 2 do
        local seg_y = j_top_y_abs + i * block_size
        -- Left edge of middle segment
        rectfill(j_left_x_abs, seg_y, j_left_x_abs + block_size - 1, seg_y + block_size - 1, fill_color)
        line(j_left_x_abs, seg_y, j_left_x_abs, seg_y + block_size - 1, outline_color)
        -- Right edge of middle segment
        rectfill(j_right_x_abs, seg_y, j_right_x_abs + block_size - 1, seg_y + block_size - 1, fill_color)
        line(j_right_x_abs + block_size - 1, seg_y, j_right_x_abs + block_size - 1, seg_y + block_size - 1, outline_color)
    end

    -- Center fill
    if w_tiles > 1 and j_h_tiles_eff > 1 then
        local center_x1 = j_left_x_abs + block_size
        local center_y1 = j_top_y_abs + block_size
        local center_x2 = j_right_x_abs - 1
        local center_y2 = j_y_eff - 1
        if center_x2 >= center_x1 and center_y2 >= center_y1 then
            rectfill(center_x1, center_y1, center_x2, center_y2, fill_color)
        end
    end

    -- Top Corners
    spr(corner_spr, j_left_x_abs, j_top_y_abs, 1, 1, false, false)
    -- TL
    spr(corner_spr, j_right_x_abs - 2, j_top_y_abs, 1, 1, true, false)
    -- TR

    -- Bottom Row: Two corners OR one corner and arrow
    if arrow_mode == 'side' then
        -- This block corresponds to 'if not narration then' in jetski
        -- Here, 'is_flipped_for_side_arrow' is 'flipped' from jetski
        -- 'j_x_eff' is 'x' from jetski
        -- 'j_y_eff' is 'y' from jetski
        if not is_flipped_for_side_arrow then
            -- Arrow on left, body on right
            rectfill(j_left_x_abs, j_y_eff, j_left_x_abs + block_size - 1, j_y_eff + block_size - 1, fill_color)
            line(j_left_x_abs, j_y_eff + block_size, j_left_x_abs + block_size - 1, j_y_eff + block_size, outline_color)
            spr(corner_spr, j_right_x_abs - 2, j_y_eff - 1, 1, 1, true, true) -- BR

            spr(arrow_spr, j_x_eff - block_size, j_y_eff, 1, 1, false, false)
            pset(j_x_eff, j_y_eff, outline_color)
        else
            -- Arrow on right, body on left
            rectfill(j_right_x_abs, j_y_eff, j_right_x_abs + block_size - 1, j_y_eff + block_size - 1, fill_color)
            line(j_right_x_abs, j_y_eff + block_size, j_right_x_abs + block_size - 1, j_y_eff + block_size, outline_color)
            spr(corner_spr, j_left_x_abs, j_y_eff - 1, 1, 1, false, true) -- BL

            spr(arrow_spr, j_x_eff + block_size - 1, j_y_eff, 1, 1, true, false)
            pset(j_x_eff + block_size - 1, j_y_eff, outline_color)
        end
    else
        -- Covers 'narrator' and 'none' modes. Corresponds to 'else' (narration) in jetski bottom row.
        spr(corner_spr, j_right_x_abs - 2, j_y_eff - 1, 1, 1, true, true) -- BR
        spr(corner_spr, j_left_x_abs, j_y_eff - 1, 1, 1, false, true) -- BL

        if w_tiles == 1 then
            -- single column bubble
            line(j_left_x_abs, j_y_eff + block_size - 1, j_left_x_abs + block_size - 1, j_y_eff + block_size - 1, outline_color)
        elseif w_tiles == 2 then
            -- two column bubble
            line(j_left_x_abs, j_y_eff + block_size - 1, j_left_x_abs + block_size - 1, j_y_eff + block_size - 1, outline_color)
            line(j_right_x_abs, j_y_eff + block_size - 1, j_right_x_abs + block_size - 1, j_y_eff + block_size - 1, outline_color)
        end
    end

    text_x_start = j_left_x_abs + padding_x
    text_y_start = j_top_y_abs + padding_x

    pal()
    return { x = text_x_start, y = text_y_start }
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

function dialogue:show(txt, speaker, partner, callback, voice)
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
        speaker = speaker,
        partner = partner,
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
    if #self.pipeline == 0 or self.current_line_index == 0 then return end

    local current_entry = self.pipeline[1]
    if not current_entry or not current_entry.speaker then
        if not (current_entry and current_entry.is_narration) then return end
    end

    local speaker = current_entry.speaker
    local partner = current_entry.partner
    local is_narration_flag = current_entry.is_narration

    local camera_x = peek2(0x5f28)
    local camera_y = peek2(0x5f2a)
    local screen_w = 128
    local screen_h = 128

    local style = self.style
    local current_bubble_config = is_narration_flag and style.narrator_bubble or style.character_bubble
    local bubble_w_tiles = current_entry.calculated_width_tiles

    local used_lines = 0
    for i = 1, #self.display_lines_cache do
        if self.display_lines_cache[i] != "" then used_lines += 1 end
    end
    used_lines = min(used_lines, current_bubble_config.max_lines)
    local bubble_h_text_lines = used_lines or 1

    local bubble_total_h_tiles = bubble_h_text_lines + 1
    local bubble_body_width_px = bubble_w_tiles * style.bubble_block_size
    local bubble_total_height_px = bubble_total_h_tiles * style.bubble_block_size

    -- Variables to be determined:
    local final_render_x, final_render_y, actual_flip_state, arrow_mode

    -- == NARRATOR LOGIC ==
    if is_narration_flag then
        arrow_mode = 'narrator'
        final_render_x = speaker.x -- World X for narrator
        final_render_y = speaker.y -- World Y for narrator (top-left of bubble)
        actual_flip_state = false
    else
        -- == CHARACTER BUBBLE LOGIC ==
        arrow_mode = 'side'

        local ideal_flip_state
        if partner then
            ideal_flip_state = (partner.x > speaker.x)
        else
            ideal_flip_state = (speaker.x - camera_x > style.flip_threshold_screen_x)
        end
        actual_flip_state = ideal_flip_state

        final_render_y = speaker.y
        local body_top_world_y = (speaker.y - 8) - bubble_h_text_lines * style.bubble_block_size
        local body_bottom_world_y = (speaker.y - 8) + style.bubble_block_size

        if body_top_world_y < camera_y then
            final_render_y += (camera_y - body_top_world_y)
        elseif body_bottom_world_y > (camera_y + screen_h - 1) then
            final_render_y -= (body_bottom_world_y - (camera_y + screen_h) + 1)
        end

        final_render_x = speaker.x

        if speaker.x < camera_x then
            actual_flip_state = false
            final_render_x = camera_x - style.bubble_block_size
            local body_ext = get_bubble_body_screen_extents(final_render_x, actual_flip_state, bubble_w_tiles, style.bubble_x_offset_char, style.bubble_block_size, camera_x)
            if body_ext.right > screen_w then
                final_render_x -= (body_ext.right - screen_w)
            end
        elseif speaker.x > camera_x + screen_w then
            actual_flip_state = true
            final_render_x = camera_x + screen_w
            local body_ext = get_bubble_body_screen_extents(final_render_x, actual_flip_state, bubble_w_tiles, style.bubble_x_offset_char, style.bubble_block_size, camera_x)
            if body_ext.left < 0 then
                final_render_x += (0 - body_ext.left)
            end
        else
            local full_ext = get_full_bubble_screen_extents(final_render_x, actual_flip_state, bubble_w_tiles, style.bubble_x_offset_char, style.bubble_block_size, style.arrow_sprite_width_px, camera_x)
            if full_ext.left < 0 then
                final_render_x += (0 - full_ext.left)
            elseif full_ext.right > screen_w then
                final_render_x -= (full_ext.right - screen_w)
            end
        end

        local final_body_ext_world = get_bubble_body_screen_extents(final_render_x, actual_flip_state, bubble_w_tiles, style.bubble_x_offset_char, style.bubble_block_size, 0)

        if speaker.x >= final_body_ext_world.world_left and speaker.x <= final_body_ext_world.world_right then
            arrow_mode = 'none'
            final_render_x = speaker.x
            local half_body_width = bubble_body_width_px / 2
            if final_render_x - half_body_width < camera_x then
                final_render_x = camera_x + half_body_width
            elseif final_render_x + half_body_width > camera_x + screen_w then
                final_render_x = camera_x + screen_w - half_body_width
            end

            final_render_y = speaker.y - style.no_arrow_gap_above_speaker - bubble_total_height_px
            if final_render_y < camera_y then
                final_render_y = camera_y
            end
            if final_render_y + bubble_total_height_px > camera_y + screen_h then
                final_render_y = camera_y + screen_h - bubble_total_height_px
            end
        end
    end

    local text_origin = self:_draw_bubble(final_render_x, final_render_y, bubble_w_tiles, bubble_h_text_lines, actual_flip_state, is_narration_flag, arrow_mode)

    local line_number = 0
    for i = 1, #self.display_lines_cache do
        if self.display_lines_cache[i] != "" and line_number < current_bubble_config.max_lines then
            line_number += 1
            print(self.display_lines_cache[i], text_origin.x, text_origin.y + ((line_number - 1) * style.text_line_height_pixels), style.text_color)
        end
    end
end
