pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Global scene table
scenes = {}
timeline = {
    { fs = 30, fn = function() cls(3) end }
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
end

function seq_drw()
    local step = seq[seq_idx]
    if step and step.fn then
        step.fn()
    end
    if seq_t == 1 and step.fn_e then
        step.fn_e()
    end
    if (step.fs == 0) then
        -- chill
    elseif seq_t > step.fs then
        seq_idx += 1
        seq_t = 0
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

function draw_big_sprite(x, y, w, h, sprite, scale)
    local scale = scale or 2
    local sx, sy = (sprite % 16) * 8, (sprite \ 16) * 8
    sspr(sx, sy, w, h, x, y, w * scale, h * scale)
end

-- title scene

function title_setup()
    --dialogue:show("is this... a dream?", narrator)
    dialogue:show(
        "press x to start", narrator, nil, function()
            switch_scene("main")
        end
    )
end

function title_update()
    update_camera()
    dialogue:update()
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
    --wave_init()
end

function main_update()
    --wave_update(steve.x, steve.y, (steve.dx * steve.dy))
    move_player(steve)
    trigger_splashes()
    get_terrain_collision()
    handle_entity_collisions()
    update_entities()
    update_camera()
    dialogue:update()
end

function main_draw()
    palt(12, false)
    cls(12)
    palt(12, true)

    camera(cam_x, cam_y)

    --wave_draw()
    -- draw the map
    -- flags:
    -- 0 interactable zones
    -- 4 blocking objects
    -- 6 top layer objects

    -- sand island background
    rectfill(5 * 8, 1 * 8, 23 * 8, 9 * 8, 15)
    map(0, 0, 0, 0, 39, 39)

    --for i = 0, 39 do
    --for j = 0, 39 do
    --spr(110, i * 8, j * 4)
    --end
    --end
    --local sx, sy = (64 % 16) * 8, (64 \ 16) * 8
    --sspr(sx, sy, 13 * 8, 32, 10, 32)

    draw_player_shadow()
    map(0, 0, 0, 0, 39, 39, 0x40)
    draw_particles()
    draw_player()

    selected = find_closest_interactable()
    if selected then
        if btnp(5) then
            selected:event()
        end
    else
        if #steve.inventory > 0 then
            if btnp(5) then
                drop(steve.inventory[#steve.inventory])
            end
        end
    end
    draw_entities()
    draw_inventory()
    if selected then
        draw_interact_icon(selected)
    end

    print(steve.dir, steve.x + 10, steve.y)
    dialogue:draw()
end

-- Register states
add_scene("title", title_update, title_draw, title_setup)
add_scene("main", main_update, main_draw, main_setup)

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

function lerp(a, b, t)
    return flr(a + (b - a) * t)
end

function slice(x0, y0, x1, y1, frames, col)
    if seq_t > frames then
        return
    end
    local t = min(seq_t / frames, 1)
    local t0 = max((seq_t - 3) / frames, 0)
    line(lerp(x0, x1, t0), lerp(y0, y1, t0), lerp(x0, x1, t), lerp(y0, y1, t), col or 7)
end
