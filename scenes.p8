pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Global scene table
scenes = {}

timeline = {
    { fs = 30, fn = function() cls(3) end },
    {
        fs = 30,
        fn = function()
            if flash(5) then
                cls(7)
            else
                cls(0)
            end
        end,
        fn_e = function() cls(7) end
    },
    { fs = 10, fn = function() cls(0) draw_big_sprite(knife.x - 16, knife.y - 20, 16, 16, 194) end },
    { fs = 15, fn = function() cls(0) end },
    { fs = 10, fn = function() cls(0) draw_big_sprite(knife.x - 16, knife.y - 20, 16, 16, 192) end },
    { fs = 15, fn = function() cls(0) end },
    { fs = 2000, fn = function() cls(0) draw_big_sprite(knife.x - 16, knife.y - 20, 16, 16, 196) end }
}

seq = timeline
seq_t = 0
seq_idx = 1
seq_f = 0

function seq_next()
    seq_t = 0
    seq_idx += 1
end

function seq_rst()
    seq_t = 0
    seq_idx = 1
end

function seq_upd()
    local step = seq[seq_idx]
    if not step then
        seq_idx = 1
        seq_t = 0
        return
    end

    seq_t += 1
    if seq_t == 1 and step.fn_e then
        step.fn_e()
    end

    if seq_t > step.fs then
        seq_idx += 1
        seq_t = 0
    end
end

function seq_drw()
    local step = seq[seq_idx]
    if step and step.fn then
        step.fn()
    end
end

-- Register a state
function add_scene(name, update_fn, draw_fn, setup_fn)
    scenes[name] = {
        update = update_fn,
        draw = draw_fn,
        setup = setup_fn or function()
            camera()
            clip()
        end
    }
end

-- Switch to a state by name
function switch_scene(name)
    local scene = scenes[name]
    if scene then
        seq_rst()
        -- run one-time setup
        scene.setup()
        -- reassign update/draw
        game_update = scene.update
        game_draw = scene.draw
    else
        printh("unknown state: " .. name)
    end
end

function draw_big_sprite(x, y, w, h, sprite)
    sx, sy = (sprite % 16) * 8, (sprite \ 16) * 8
    sspr(sx, sy, w, h, x, y, w * 2, h * 2)
end

-- chop scene

knife = {
    x = 64,
    y = 64,
    w = 4,
    h = 4,
    done = false,
    start_time = 0,
    knife_sprite = 14,
    block_sprite = 30,
    apple_sprite = 13,
    chopped_apple_sprite = 46,
    chop_state = "up",
    chop_time = 0,
    flash_count = 0
}

function chop_setup()
    knife.start_time = t()
    dialogue:show(
        "when in doubt... chop!", narrator, function()
            knife.done = true
            knife.chop_state = "down"
            knife.chop_time = t()
            sfx(12)
        end
    )
end

function chop_update()
    update_camera()
    dialogue:update()
    if knife.done then
        if btnp(4) then
            switch_scene("main")
        end
    end
end

function chop_draw()
    camera()
    cls(0)
    if knife.flash_count < 5 and knife.chop_state == "down" then
        cls(7)
        knife.flash_count += 1
        return
    end
    if (knife.chop_state == "up") then
        -- knife
        if fade(knife.start_time, 4) then
            draw_big_sprite(knife.x - 16, knife.y - 20, 16, 8, knife.knife_sprite)
        end
        -- choppin' block
        draw_big_sprite(knife.x - 16, knife.y, 16, 8, knife.block_sprite)

        draw_big_sprite(knife.x - 4, knife.y - 4, 8, 8, knife.apple_sprite)
    else
        -- Time since chop
        local dt = t() - knife.chop_time
        local spread = min(dt * 10, 20) -- how far pieces spread
        -- choppin' block
        draw_big_sprite(knife.x - 16, knife.y, 16, 8, knife.block_sprite)

        if not fade(knife.chop_time, 4) then
            draw_big_sprite(knife.x + spread, knife.y - 2, 8, 8, knife.chopped_apple_sprite + 1)
        end

        -- knife
        draw_big_sprite(knife.x - 16, knife.y - 1, 16, 8, knife.knife_sprite)

        if not fade(knife.chop_time, 4) then
            draw_big_sprite(knife.x - 16 - spread, knife.y, 8, 8, knife.chopped_apple_sprite)
        end
    end

    if (t() - knife.chop_time > 4) and (knife.chop_state == "down") then
        print("~", knife.x + 30, knife.y + 5)
        print("~", knife.x - 30, knife.y + 5)
    end

    if (t() - knife.chop_time > 8) and (knife.chop_state == "down") then
        switch_scene("sushi")
    end

    -- dialogue
    dialogue:draw()
end

function chop_move()
    if btnp(0) then
        knife.x -= 1
    elseif btnp(1) then
        knife.x += 1
    elseif btnp(2) then
        knife.y -= 1
    elseif btnp(3) then
        knife.y += 1
    end
end

-- sushi
function sushi_setup()
    dialogue:show("sushi", narrator)
end

function sushi_update()
    update_camera()
    seq_upd()
    dialogue:update()
end

function sushi_draw()
    camera()
    seq_drw()
    dialogue:draw()
end

-- title scene

function title_setup()
    --dialogue:show("is this... a dream?", narrator)
    dialogue:show("press x to start", narrator)
end

function title_update()
    update_camera()
    dialogue:update()
    if btnp(5) then
        switch_scene("main")
    end
end

function title_draw()
    camera()
    cls(0)
    dialogue:draw()
end

-- main scene

function main_setup()
    -- start jetski sound
    sfx(steve.jetski_sfx_id)
    sfx(steve.jetski_sfx_id + 2)
end

function main_update()
    move_player(steve)
    trigger_splashes()
    get_terrain_collision()
    handle_entity_collisions()
    update_entities()
    update_camera()
    dialogue:update()
end

function main_draw()
    cls(12)

    camera(cam_x, cam_y)

    map(0, 0, 0, 0, 39, 39)

    draw_player_shadow()
    draw_particles()
    draw_entities()
    draw_player()
    dialogue:draw()
end

-- Register states
add_scene("title", title_update, title_draw, title_setup)
add_scene("main", main_update, main_draw, main_setup)
add_scene("chop", chop_update, chop_draw, chop_setup)
add_scene("sushi", sushi_update, sushi_draw, sushi_setup)

-- helpers
-- returns true if sprite should be drawn this frame
function fade(start_time, duration)
    local elapsed = t() - start_time
    if elapsed >= duration then return true end

    -- fade progression (0 to 1)
    local progress = elapsed / duration

    -- slows down early flicker
    local eased = progress ^ 2

    -- pulse-width modulation: wider duty cycle = more visible
    local pulse = flr(eased * 10)
    -- control steps
    return (frame_count % 7) < pulse
end

function flash(period)
    return (seq_t % period * 2) < period
end
