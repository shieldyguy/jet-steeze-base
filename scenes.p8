pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Global scene table
scenes = {}

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
        -- run one-time setup
        scene.setup()
        -- reassign update/draw
        game_update = scene.update
        game_draw = scene.draw
    else
        printh("unknown state: " .. name)
    end
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
            sx, sy = (knife.knife_sprite % 16) * 8, (knife.knife_sprite \ 16) * 8
            sspr(sx, sy, 16, 8, knife.x - 16, knife.y - 20, 32, 16)
        end
        -- choppin' block
        sx, sy = (knife.block_sprite % 16) * 8, (knife.block_sprite \ 16) * 8
        sspr(sx, sy, 16, 8, knife.x - 16, knife.y, 32, 16)

        sx, sy = (knife.apple_sprite % 16) * 8, (knife.apple_sprite \ 16) * 8
        sspr(sx, sy, 8, 8, knife.x - 4, knife.y - 4, 16, 16)
    else
        -- Time since chop
        local dt = t() - knife.chop_time
        local spread = min(dt * 10, 20) -- how far pieces spread
        -- choppin' block
        sx, sy = (knife.block_sprite % 16) * 8, (knife.block_sprite \ 16) * 8
        sspr(sx, sy, 16, 8, knife.x - 16, knife.y, 32, 16)

        if not fade(knife.chop_time, 4) then
            sx, sy = ((knife.chopped_apple_sprite + 1) % 16) * 8, ((knife.chopped_apple_sprite + 1) \ 16) * 8
            sspr(sx, sy, 8, 8, knife.x + spread, knife.y - 2, 16, 16)
        end

        -- knife
        sx, sy = (knife.knife_sprite % 16) * 8, (knife.knife_sprite \ 16) * 8
        sspr(sx, sy, 16, 8, knife.x - 16, knife.y - 1, 32, 16)

        if not fade(knife.chop_time, 4) then
            sx, sy = (knife.chopped_apple_sprite % 16) * 8, (knife.chopped_apple_sprite \ 16) * 8
            sspr(sx, sy, 8, 8, knife.x - 16 - spread, knife.y, 16, 16)
        end
    end

    if (t() - knife.chop_time > 4) and (knife.chop_state == "down") then
        print("~", knife.x + 30, knife.y + 5)
        print("~", knife.x - 30, knife.y + 5)
    end

    if (t() - knife.chop_time > 8) and (knife.chop_state == "down") then
        switch_scene("main")
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

-- title scene

function title_setup()
    --dialogue:show("is this... a dream?", narrator)
    dialogue:show("press x to start", narrator)
end

function title_update()
    update_camera()
    dialogue:update()
    if btnp(5) then
        switch_scene("chop")
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
