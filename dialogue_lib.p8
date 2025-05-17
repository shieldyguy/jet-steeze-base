pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
advance_button = 5

-- call this before you start using dtb.
-- optional parameter is the number of lines that are displayed. default is 3.
function dtb_init(numlines)
    dtb_queu = {}
    dtb_queuf = {}
    dtb_speakers = {}
    -- track who is speaking for each dialogue entry
    dtb_numlines = 3
    if numlines then
        dtb_numlines = numlines
    end
    _dtb_clean()
end

-- this will add a piece of text to the queu. the queu is processed automatically.
-- now accepts a speaker parameter which should be an entity with x,y coordinates
function dtb_disp(txt, speaker, callback)
    local lines = {}
    local currline = ""
    local curword = ""
    local curchar = ""
    local upt = function()
        -- max characters per line
        if #curword + #currline > 10 then
            add(lines, currline)
            currline = ""
        end
        currline = currline .. curword
        curword = ""
    end
    for i = 1, #txt do
        curchar = sub(txt, i, i)
        curword = curword .. curchar
        if curchar == " " then
            upt()
        elseif #curword > 15 then
            -- reduced from 19 to fit in bubbles better
            curword = curword .. "-"
            upt()
        end
    end
    upt()
    if currline ~= "" then
        add(lines, currline)
    end
    add(dtb_queu, lines)
    add(dtb_speakers, speaker or pl)
    -- default to player if no speaker specified
    if callback == nil then
        callback = 0
    end
    add(dtb_queuf, callback)
end

-- functions with an underscore prefix are ment for internal use, don't worry about them.
function _dtb_clean()
    dtb_dislines = {}
    for i = 1, dtb_numlines do
        add(dtb_dislines, "")
    end
    dtb_curline = 0
    dtb_ltime = 0
end

function _dtb_nextline()
    dtb_curline += 1
    for i = 1, #dtb_dislines - 1 do
        dtb_dislines[i] = dtb_dislines[i + 1]
    end

    -- Instead of setting to empty string, immediately add the first character
    if dtb_curline <= #dtb_queu[1] then
        dtb_dislines[#dtb_dislines] = sub(dtb_queu[1][dtb_curline], 1, 1)
        dtb_ltime = 1 -- Reset the typing timer
    else
        dtb_dislines[#dtb_dislines] = ""
    end
    sfx(2)
end

function _dtb_nexttext()
    if dtb_queuf[1] ~= 0 then
        dtb_queuf[1]()
    end
    del(dtb_queuf, dtb_queuf[1])
    del(dtb_queu, dtb_queu[1])
    del(dtb_speakers, dtb_speakers[1])
    _dtb_clean()
    sfx(2)
end

-- draw a speech bubble, ported from dialogue.p8
-- x,y   : anchor pixel coordinate (bottom‑left if !flipped, bottom‑right if flipped)
-- w,h   : width/height in 8×8 tiles
-- flipped?: boolean, default false (true = arrow on the right)
function _dtb_draw_bubble(x, y, w, h, flipped)
    flipped = flipped or false
    y -= 8
    h += 1

    local block_size = 6
    local outline_color = 7
    local fill_color = 1
    local x_offset = 15

    -- establish left and right limits in pixel space
    local left_x, right_x
    if flipped then
        x -= x_offset
        right_x = x -- anchor is bottom‑right
        left_x = x - (w - 1) * block_size
    else
        x += x_offset
        left_x = x -- anchor is bottom‑left
        right_x = x + (w - 1) * block_size
    end
    local top_y = y - (h - 1) * block_size

    -----------------------------------------------------------------------
    --  corners
    -----------------------------------------------------------------------

    -- top corners (unchanged)
    spr(10, left_x, top_y, 1, 1, false, false)
    -- top‑left
    spr(10, right_x - 2, top_y, 1, 1, true, false)
    -- top‑right

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
    for i = 1, w - 2 do
        for j = 1, h - 2 do
            rectfill(
                left_x + i * block_size, top_y + j * block_size,
                left_x + i * block_size + block_size, top_y + j * block_size + block_size, fill_color
            )
        end
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

    return top_y + 4, left_x + 4
end

-- make sure that this function is called each update.
function dtb_update()
    if #dtb_queu > 0 then
        if dtb_curline == 0 then
            dtb_curline = 1
        end
        local dislineslength = #dtb_dislines
        local curlines = dtb_queu[1]
        local curlinelength = #dtb_dislines[dislineslength]
        local complete = curlinelength >= #curlines[dtb_curline]
        if complete and dtb_curline >= #curlines then
            if btnp(advance_button) then
                _dtb_nexttext()
                return
            end
        elseif dtb_curline > 0 then
            dtb_ltime -= 1
            if not complete then
                if dtb_ltime <= 0 then
                    local curchari = curlinelength + 1
                    local curchar = sub(curlines[dtb_curline], curchari, curchari)
                    dtb_ltime = 1
                    if curchar ~= " " then
                        sfx(0)
                    end
                    if curchar == "." then
                        dtb_ltime = 6
                    end
                    dtb_dislines[dislineslength] = dtb_dislines[dislineslength] .. curchar
                end
                if btnp(advance_button) then
                    dtb_dislines[dislineslength] = curlines[dtb_curline]
                end
            else
                _dtb_nextline()
            end
        end
    end
end

-- make sure to call this function everytime you draw.
function dtb_draw()
    if #dtb_queu > 0 then
        local speaker = dtb_speakers[1]
        local dislineslength = #dtb_dislines

        -- determine if we need to flip based on screen position
        local flipped = false
        local camera_x = peek2(0x5f28) -- get current camera x position
        local screen_x = speaker.x - camera_x

        -- flip if too close to the right edge
        if screen_x > 90 then
            flipped = true
        end

        -- calculate height based on actually used lines
        local used_lines = 0
        for i = 1, dislineslength do
            if dtb_dislines[i] != "" then
                used_lines += 1
            end
        end

        -- bubble height exactly matches the content
        local bubble_height = max(2, used_lines)

        -- fixed width
        local bubble_width = 8

        -- draw the bubble
        local text_y, text_x = _dtb_draw_bubble(speaker.x, speaker.y, bubble_width, bubble_height, flipped)

        -- draw the text
        local line_height = 6
        local line_number = 0
        for i = 1, dislineslength do
            if dtb_dislines[i] != "" then
                line_number += 1
                print(dtb_dislines[i], text_x, text_y + ((line_number - 1) * line_height), 7)
            end
        end
    end
end
