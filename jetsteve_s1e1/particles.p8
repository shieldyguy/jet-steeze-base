pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
particles = {}
splash = {}

function trigger_splashes()
    -- determine splash color based on collision
    -- default to white
    local col = 7
    if terrain.forest.collision then
        -- grass
        col = terrain.forest.particle_color
    elseif terrain.beach.collision then
        --  sand
        col = terrain.beach.particle_color
    end

    local speed = (steve.dx * steve.dx + steve.dy * steve.dy) * 0.1

    local splash_threshold = 0.05
    if (steve.z == 0) then
        if (steve.dir == dir_map.n or steve.dir == dir_map.s) then
            if (speed > splash_threshold) then
                make_splash(steve.x, steve.y + 2, -speed, steve.dy, speed, col)
                make_splash(steve.x, steve.y + 6, -speed, steve.dy, speed, col)
                make_splash(steve.x + 8, steve.y + 2, speed, steve.dy, speed, col)
                make_splash(steve.x + 8, steve.y + 6, speed, steve.dy, speed, col)
            end
        elseif (steve.dir == dir_map.e or steve.dir == dir_map.w) then
            if (speed > splash_threshold) then
                make_splash(steve.x + 2, steve.y + 7, steve.dx * 0.5, 0.3, speed, col)
                make_splash(steve.x + 4, steve.y + 7, steve.dx * 0.5, 0.3, speed, col)
                make_splash(steve.x + 6, steve.y + 7, steve.dx * 0.5, 0.3, speed, col)
            end
        elseif (steve.dir == dir_map.ne or steve.dir == dir_map.sw) then
            if (speed > splash_threshold) then
                make_splash(steve.x + 2, steve.y + 6, -speed, 0.3, speed, col)
                make_splash(steve.x + 6, steve.y + 2, -speed, 0.3, speed, col)
                make_splash(steve.x + 4, steve.y + 8, speed, 0.3, speed, col)
                make_splash(steve.x + 8, steve.y + 4, speed, 0.3, speed, col)
            end
        elseif (steve.dir == dir_map.nw or steve.dir == dir_map.se) then
            if (speed > splash_threshold) then
                make_splash(steve.x + 1, steve.y + 4, -speed, 0.3, speed, col)
                make_splash(steve.x + 5, steve.y + 8, -speed, 0.3, speed, col)
                make_splash(steve.x + 4, steve.y + 2, speed, 0.3, speed, col)
                make_splash(steve.x + 8, steve.y + 6, speed, 0.3, speed, col)
            end
        end
    end

    -- update jetski sound
    set_sfx_loop(steve.jetski_sfx_id, 0, 18 - min(15, (speed * 10)))
    set_sfx_note1(steve.jetski_sfx_id + 2, speed * 16)
end

-->8
--particles

function make_splash(x, y, dx, dy, dz, col)
    for i = 1, 2 do
        add(
            particles, {
                x = x, y = y,
                z = 0, g = 1,
                dx = dx + (rnd() - 0.5) * 0.5,
                dy = dy + (rnd() - 0.5) * 0.5,
                dz = dz + (rnd() - 0.5) * 0.5,
                life = 20,
                col = col
            }
        )
    end
end

function update_particle(p)
    p.z += p.dz
    p.dz -= 0.05 * p.g
    p.y += p.dy
    p.x += p.dx
    p.life -= 1
    if p.z < 0 or p.life <= 0 then
        del(particles, p)
    end
end

function draw_particles()
    for p in all(particles) do
        update_particle(p)
        pset(p.x, p.y - p.z, p.col)
    end
end
