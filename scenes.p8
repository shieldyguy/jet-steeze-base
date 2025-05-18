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

function chop_update()
    if btnp(5) then
        switch_scene("main")
    end
end

function chop_draw()
    camera()
    clip()
    cls()
    spr(14, 64, 64, 2, 2)
    print("chop! (x)", 5, 5, 7)
end

-- title scene

function title_update()
    if btnp(5) then
        switch_scene("main")
    end
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

function title_draw()
    cls()
    print("anything you dream of it", 5, 5, 7)
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

function chop_draw()
    cls()
    spr(14, 64, 64, 2, 2)
    print("chop! (x)", 5, 5, 7)
end
