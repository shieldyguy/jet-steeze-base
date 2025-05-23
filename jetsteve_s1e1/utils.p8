pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--> utils
--97 tokens with Scaling and arbitrary size
function pd_rotate(x, y, rot, mx, my, w, flip, scale)
    scale = scale or 1
    w *= scale * 4

    local cs, ss = cos(rot) * .125 / scale, sin(rot) * .125 / scale
    local sx, sy = mx + cs * -w, my + ss * -w
    local hx = flip and -w or w

    local halfw = -w
    for py = y - w, y + w do
        tline(x - hx, py, x + hx, py, sx - ss * halfw, sy + cs * halfw, cs, ss)
        halfw += 1
    end
end
