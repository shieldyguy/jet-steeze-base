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
    dtb_dislines[#dtb_dislines] = ""
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

    -- establish left and right limits in pixel space
    local left_x, right_x
    if flipped then
        x -= 20
        right_x = x -- anchor is bottom‑right
        left_x = x - (w - 1) * 8
    else
        x += 20
        left_x = x -- anchor is bottom‑left
        right_x = x + (w - 1) * 8
    end
    local top_y = y - (h - 1) * 8

    -----------------------------------------------------------------------
    --  corners
    -----------------------------------------------------------------------

    -- top corners (unchanged)
    spr(10, left_x, top_y, 1, 1, false, false)
    -- top‑left
    spr(10, right_x, top_y, 1, 1, true, false)
    -- top‑right

    if not flipped then
        -- ░░ arrow‑on‑left layout ░░
        -- bottom‑left = flat corner for arrow overlap
        rectfill(left_x, y, left_x + 7, y + 7, 1)
        line(left_x, y + 7, left_x + 7, y + 7, 7)
        -- bottom‑right = sprite corner
        spr(10, right_x, y, 1, 1, true, true)
    else
        -- ░░ arrow‑on‑right layout ░░
        -- bottom‑right = flat corner for arrow overlap
        rectfill(right_x, y, right_x + 7, y + 7, 1)
        line(right_x, y + 7, right_x + 7, y + 7, 7)
        -- bottom‑left = sprite corner
        spr(10, left_x, y, 1, 1, false, true)
    end

    -----------------------------------------------------------------------
    --  top & bottom edges
    -----------------------------------------------------------------------
    for i = 1, w - 2 do
        local seg_x = left_x + i * 8
        spr(11, seg_x, top_y, 1, 1, false, false) -- top edge
        spr(11, seg_x, y, 1, 1, false, true) -- bottom edge (flip_y)
    end

    -----------------------------------------------------------------------
    --  left & right edges
    -----------------------------------------------------------------------
    for j = 1, h - 2 do
        local edge_y = top_y + j * 8
        -- left edge
        rectfill(left_x, edge_y, left_x + 8, edge_y + 8, 1)
        line(left_x, edge_y, left_x, edge_y + 8, 7)
        -- right edge
        rectfill(right_x, edge_y, right_x + 7, edge_y + 8, 1)
        line(right_x + 7, edge_y, right_x + 7, edge_y + 8, 7)
    end

    -----------------------------------------------------------------------
    --  centre fill
    -----------------------------------------------------------------------
    for i = 1, w - 2 do
        for j = 1, h - 2 do
            rectfill(
                left_x + i * 8, top_y + j * 8,
                left_x + i * 8 + 8, top_y + j * 8 + 8, 1
            )
        end
    end

    -----------------------------------------------------------------------
    --  arrow
    -----------------------------------------------------------------------
    if flipped then
        -- arrow sprite mirrored horizontally, sits just to the right
        spr(12, x + 8, y, 1, 1, true, false)
        pset(x + 7, y, 7)
    else
        -- original left‑pointing arrow
        spr(12, x - 8, y, 1, 1, false, false)
        pset(x, y, 7)
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

        -- fixed width of 5 tiles
        local bubble_width = 6

        -- draw the bubble
        local text_y, text_x = _dtb_draw_bubble(speaker.x, speaker.y, bubble_width, bubble_height, flipped)

        -- draw the text
        local line_number = 0
        for i = 1, dislineslength do
            if dtb_dislines[i] != "" then
                line_number += 1
                print(dtb_dislines[i], text_x, text_y + ((line_number - 1) * 8), 7)
            end
        end

        -- draw advance indicator
        if dtb_curline > 0 and dtb_curline >= #dtb_queu[1] and #dtb_dislines[#dtb_dislines] == #dtb_queu[1][dtb_curline] then
            -- Find the last non-empty line
            local last_line_idx = 0
            for i = dislineslength, 1, -1 do
                if dtb_dislines[i] != "" then
                    last_line_idx = i
                    break
                end
            end

            local last_line_text = dtb_dislines[last_line_idx]
            local indicator_x = flipped and (text_x - 6) or (text_x + 4 * #last_line_text + 2)
            local indicator_y = text_y + (last_line_idx - 1) * 6
            print("\x8e", indicator_x, indicator_y, 7)
        end
    end
end

--{ example usage }--

-- initialize
dtb_init()

-- add text to the queu, this can be done at any point in time.
--dtb_disp("hello world! welcome to this amazing dialogue box!")

dtb_disp("a dialogue can be queud with: dtb_disp(text,speaker,callback)")

dtb_disp("this is a character speech bubble that follows characters!")

dtb_disp(
    "dtb_prompt also has a callback which is called when the piece of dialogue is finished.", nil, function()
        --whatever is in this function is called after this dialogue is done.
        sfx(1)
    end
)

dtb_disp("just like that!")
dtb_disp("another cool feature is that a . will take longer.")
dtb_disp("which is great for some akward pauses... right?")
dtb_disp("the bubble will flip automatically if near screen edges!")
dtb_disp("oh and shorter lines now fit in these cool speech bubbles!")
dtb_disp("anyways, feel free to use and/or modify this code!")

function _update()
    -- make sure to update dtb. no need for logic additional here, dtb takes care of everything.
    dtb_update()
end
function _draw()
    cls(6)
    -- as with the update function. just make sure dtb is being drawn.
    dtb_draw()
end
