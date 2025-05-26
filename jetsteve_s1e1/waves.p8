pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- grid size
grid_w = 16
grid_h = 16
grid_size = 8

-- simulation buffers
height = {}
velocity = {}
wave_offsets = {}

-- wave simulation params
damping = 0.92
spring = 0.1

-- helper ヌ●★ iso screen coords for a grid point
function iso(gx, gy, h)
    local hw, hh = 8, 4
    local z = 2
    local ox, oy = 64, 16
    local sx = ox + (gx - gy) * hw
    local sy = oy + (gx + gy) * hh - h * z
    return sx, sy
end

-- initialize
function wave_init()
    for i = 0, grid_w * grid_h - 1 do
        height[i] = 0
        velocity[i] = 0
        --wave_offsets[i] = { x = rnd(5) - 2.5, y = rnd(5) - 2.5 }
        wave_offsets[i] = { x = 0, y = 0 }
    end
end

-- convert 2d to 1d index
function idx(x, y)
    return y * grid_w + x
end

function wave_update(px, py, speed)
    -- excite random point on button press
    --if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
    --local x = flr(rnd(grid_w))
    --local y = flr(rnd(grid_h))
    px += 8
    py += 8
    local gx = flr((px - 8) / grid_size)
    local gy = flr((py - 4) / grid_size)

    if gx >= 0 and gx < grid_w and gy >= 0 and gy < grid_h then
        velocity[idx(gx, gy)] += speed
    end
    --end

    for y = 0, grid_h - 1 do
        for x = 0, grid_w - 1 do
            local i = idx(x, y)

            -- compute average height of 8 neighbors (with reflection)
            local sum = 0
            local count = 0
            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx != 0 or dy != 0 then
                        local nx = x + dx
                        local ny = y + dy
                        if nx >= 0 and nx < grid_w and ny >= 0 and ny < grid_h then
                            sum += height[idx(nx, ny)]
                        else
                            sum += height[i]
                        end
                        count += 1
                    end
                end
            end

            local avg = sum / count

            -- include restoring force to flat (0)
            local force = (avg - height[i]) * spring + (0 - height[i]) * spring

            velocity[i] += force
            velocity[i] *= damping
        end
    end

    -- apply velocity to height
    for i = 0, grid_w * grid_h - 1 do
        height[i] += velocity[i]
    end
end

-- draw the grid
function wave_draw()
    for y = 0, grid_h - 1 do
        for x = 0, grid_w - 1 do
            local i = idx(x, y)
            local h = height[i]
            local state = mid(0, flr(h + 8), 16)
            local color = 7

            --circ(8 + x * 4, (4 + y * 4) + (height[i] * 2), 1, state)
            if (x == 0) then
                line(8 + x * grid_size + wave_offsets[i].x, (4 + y * grid_size + wave_offsets[i].y) + h, 8 + (x + 1) * grid_size + wave_offsets[i].x, (4 + y * grid_size + wave_offsets[i].y) + height[i + 1], color)
            else
                line(8 + x * grid_size + wave_offsets[i].x, (4 + y * grid_size + wave_offsets[i].y) + h, color)
            end

            --local sx, sy = iso(x, y, h)

            --pset(8 + x * grid_size + wave_offsets[i].x, (4 + y * grid_size + wave_offsets[i].y) + h * 2, color)
        end
    end
    --print(height[15], 50, 50, 7)
    print(stat(1), 50, 50, 7)
end

-- draw the grid
function wave_draw_dots()
    for y = 0, grid_h - 1 do
        for x = 0, grid_w - 1 do
            local i = idx(x, y)
            local h = height[i]
            local state = mid(0, flr(h + 8), 16)
            local color = 7

            pset(8 + x * grid_size + wave_offsets[i].x, (4 + y * grid_size + wave_offsets[i].y) + h * 2, color)
        end
    end
    --print(height[15], 50, 50, 7)
    print(stat(1), 50, 50, 7)
end

-- draw the grid in isometric projection
function wave_draw_iso()
    cls(1)

    -- ---------- 1) draw rows (same as before) ----------
    for gy = 0, grid_h - 1 do
        local px, py = nil, nil
        for gx = 0, grid_w - 1 do
            local i = idx(gx, gy)
            local h = height[i]
            local col = (abs(h) > 0.1) and 7 or 1
            local sx, sy = iso(gx, gy, h)

            if px then line(px, py, sx, sy, col) end
            px, py = sx, sy
        end
    end

    -- ---------- 2) draw columns (your ヌ█うverticalヌ█え lines) ----------
    --for gx = 0, grid_w - 1 do
    --    local px, py = nil, nil
    --    for gy = 0, grid_h - 1 do
    --        local i = idx(gx, gy)
    --        local h = height[i]
    --        local col = (abs(h) > 0.5) and 12 or 1
    --        local sx, sy = iso(gx, gy, h)

    --        if px then line(px, py, sx, sy, col) end
    --        px, py = sx, sy
    --    end
    --end

    --print(stat(1), 50, 50, 7)
end
