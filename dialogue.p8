pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-->8
--dialogue

-- Original bubble drawing function moved to dialogue_lib.p8
-- This file now handles dialogue activation and coroutines

-- dialogue ---------------------------------------------------------------
-- draw a speech bubble, optional mirror around the anchor point
-- x,y   : anchor pixel coordinate (bottom‑left if !flipped, bottom‑right if flipped)
-- w,h   : width/height in 8×8 tiles
-- flipped?: boolean, default false (true = arrow on the right)

function draw_bubble(x, y, w, h, flipped)
    flipped = flipped or false
    y -= 8

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
    else
        -- original left‑pointing arrow
        spr(12, x - 8, y, 1, 1, false, false)
    end

    return top_y + 3, left_x + 3
end

dialogue = {
    active = false,
    current_line = "",
    line1 = "EY BUBBY!",
    line2 = "i THINK IT'S WORKING, PAPA.",
    line3 = "rOLL ON!"
}

function handle_dialogue()
    if dialogue.active then
        if btnp(5) then
            coresume(d)
        end
    end
end

function dialogue_co()
    dialogue.current_line = dialogue.line1
    yield()
    dialogue.current_line = dialogue.line2
    yield()
    dialogue.current_line = dialogue.line3
    yield()
end

function draw_dialogue()
    -- Only used if not using the dialogue_lib system
    if dialogue.active and not dtb_queu then
        local flip_dialogue = false
        -- Check if player is on right side of screen
        local camera_x = peek2(0x5f28)
        if (pl.x - camera_x) > 90 then
            flip_dialogue = true
        end

        local y, x = draw_bubble(pl.x, pl.y, 5, 3, flip_dialogue)
        print(dialogue.current_line, x, y, 7)
    end
end

d = cocreate(dialogue_co)

-- Helper function to start a conversation using dialogue_lib
function start_conversation(lines, speaker)
    speaker = speaker or pl
    dtb_init()
    for line in all(lines) do
        dtb_disp(line, speaker)
    end
end
