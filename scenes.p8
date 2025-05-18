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
    done = false
}

function chop_setup()
    dialogue:show("before we speak... ", narrator)
    dialogue:show(
        "i must chop! (z)", knife, function()
            knife.done = true
        end
    )
end

function chop_update()
    chop_move()
    update_camera()
    dialogue:update()
    if knife.done then
        if btnp(4) then
            switch_scene("main")
        end
    end
end

function chop_draw()
    cls(12)
    spr(14, knife.x, knife.y, 4, 4)
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
    dialogue:show("anything you dream of it..", narrator)
end

function title_update()
    update_camera()
    dialogue:update()
    if btnp(5) then
        switch_scene("chop")
    end
end

function title_draw()
    cls(12)
    dialogue:draw()
end

-- main scene

function main_update()
    frame_count += 1
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
add_scene("main", main_update, main_draw)
add_scene("chop", chop_update, chop_draw, chop_setup)
