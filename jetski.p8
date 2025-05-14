pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

debug=true

pl = {
 x = 64,
 y = 64,
 dx = 0,
 dy = 0,
 spd = 0.08,  -- same speed as basics.p8
 dir = 0
}

dir_map = {
 n = 4,
 s = 6,
 e = 0,
 w = -1,
 nw = -2,
 ne = 2,
 sw = -8,
 se = 8,
}

function _init()
    splash={}
    particles={}
    frame_count = 0
end

function _update()
    move_player(pl)
    get_direction()
    frame_count += 1
    local speed = (max(abs(pl.dx), abs(pl.dy))*0.3)
    local splash_threshold = 0.05
    if(speed > splash_threshold) then
        if(pl.dir == dir_map.n or pl.dir == dir_map.s) then
            make_splash(pl.x,pl.y+2,-speed,pl.dy,speed)
            make_splash(pl.x,pl.y+4,-speed,pl.dy,speed)
            make_splash(pl.x,pl.y+6,-speed,pl.dy,speed)
            make_splash(pl.x+8,pl.y+2,speed,pl.dy,speed)
            make_splash(pl.x+8,pl.y+4,speed,pl.dy,speed)
            make_splash(pl.x+8,pl.y+6,speed,pl.dy,speed)
        elseif(pl.dir == dir_map.e or pl.dir == dir_map.w) then
            make_splash(pl.x+2,pl.y+7,pl.dx*0.5,0.3,speed)
            make_splash(pl.x+4,pl.y+7,pl.dx*0.5,0.3,speed)
            make_splash(pl.x+6,pl.y+7,pl.dx*0.5,0.3,speed)
        elseif(pl.dir == dir_map.ne or pl.dir == dir_map.sw) then
            make_splash(pl.x+2,pl.y+6,-speed,0.3,speed)
            make_splash(pl.x+4,pl.y+4,-speed,0.3,speed)
            make_splash(pl.x+6,pl.y+2,-speed,0.3,speed)
            make_splash(pl.x+4,pl.y+8,speed,0.3,speed)
            make_splash(pl.x+6,pl.y+6,speed,0.3,speed)
            make_splash(pl.x+8,pl.y+4,speed,0.3,speed)
        elseif(pl.dir == dir_map.nw or pl.dir == dir_map.se) then
            make_splash(pl.x+1,pl.y+4,-speed,0.3,speed)
            make_splash(pl.x+3,pl.y+6,-speed,0.3,speed)
            make_splash(pl.x+5,pl.y+8,-speed,0.3,speed)
            make_splash(pl.x+4,pl.y+2,speed,0.3,speed)
            make_splash(pl.x+6,pl.y+4,speed,0.3,speed)
            make_splash(pl.x+8,pl.y+6,speed,0.3,speed)
        end
        
    end
end

function _draw()
    cls(0)
    update_direction()

    for p in all(particles) do
		update_particle(p)
		pset(p.x,p.y-p.z,p.col)
	end

    spr(sprite_index, pl.x-4, pl.y-4, 2, 2, flip_x)
end

function update_direction()
    sprite_index = abs(pl.dir)
    flip_x = pl.dir < 0
    if(pl.dir == -1) then
        sprite_index = 0
    end
end

function get_direction()
    local up = btn(⬆️)
    local down = btn(⬇️)
    local left = btn(⬅️)
    local right = btn(➡️)
    
    -- Determine compass direction
    dir_key = ""
    if up then
        if right then dir_key = "ne"
        elseif left then dir_key = "nw"
        else dir_key = "n" end
    elseif down then
        if right then dir_key = "se"
        elseif left then dir_key = "sw"
        else dir_key = "s" end
    elseif right then
        dir_key = "e"
    elseif left then
        dir_key = "w"
    else
        return -- no input
    end

    
    pl.dir = dir_map[dir_key]
end

-->8
--particles

function make_splash(x,y,dx,dy,dz)

	for i=1,4 do
		add(particles, {
		 x=x, y=y,
		 z=0, g=1,
		 dx=dx+(rnd()-0.5)*0.5,
		 dy=dy+(rnd()-0.5)*0.5,
		 dz=dz+(rnd()-0.5)*0.5,
		 life=20,
		 col=7
		})
	end
end

function update_particle(p)
    p.z+=p.dz
    p.dz-=0.05*p.g
    p.y+=p.dy
    p.x+=p.dx
    p.life-=1
    if p.z<0 or p.life<=0 then
     del(particles,p)
    end
   end

-->8
--player

function move_player(p)
    -- acceleration based on input
    if (btn(⬅️)) then
        p.dx -= p.spd
    elseif (btn(➡️)) then
        p.dx += p.spd
    else
        p.dx *= 0.8  -- deceleration when no input
    end
    
    if (btn(⬆️)) then
        p.dy -= p.spd
    elseif (btn(⬇️)) then
        p.dy += p.spd
    else
        p.dy *= 0.8  -- deceleration when no input
    end
    
    -- update position
    p.x += p.dx
    p.y += p.dy
    
    -- keep in bounds (optional)
    p.x = mid(0, p.x, 127)
    p.y = mid(0, p.y, 127)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000777700000000009777777700000000007700000000000000000000000000000000000000000000000000000000
00000000000000000000000557770000000007555570000000007766667700000000766777000000000000000000000000000000000000000000000000000000
00000000000000000000007755777000000095555557000000007666666900000076667677700000000000000000000000000000000000000000000000000000
00000000055700000000076666559000000077777799000000009677666700000076676666770000000000000000000000000000000000000000000000000000
00600000007970000000766766757000000096666669000000009666666700000077666766670000000000000000000000000000000000000000000000000000
00666676077999000006666676779000000096677767000000009667777900000079766666677000000000000000000000000000000000000000000000000000
07777777779999700076676666799000000096666667000000009666666700000079976667775000000000000000000000000000000000000000000000000000
07799999779979700077667667797000000076666667000000007666666700000007997777955700000000000000000000000000000000000000000000000000
00777777777777700077776679970000000076677667000000007977779700000000799775557000000000000000000000000000000000000000000000000000
00000777777770000007777997700000000076666667000000007555555700000000079955977000000000000000000000000000000000000000000000000000
00000000000000000000077777000000000077666677000000000755557000000000000777770000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007777770000000000077770000000000000000000000000000000000000000000000000000000000000000000000
