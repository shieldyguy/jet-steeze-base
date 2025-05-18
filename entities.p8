pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
BaseEntity = {}
BaseEntity.__index = BaseEntity -- Key for inheritance

function BaseEntity:new(config)
    local instance = config or {}
    -- Start with the provided configuration
    setmetatable(instance, self)
    -- Make BaseEntity the prototype

    -- Initialize default properties if not provided in config
    instance.name = instance.name or "unnamed_entity"
    instance.x = instance.x or 0
    instance.y = instance.y or 0

    -- Collision dimensions (used by default check_player_collision)
    instance.w = instance.w or 8
    -- Default collision width
    instance.h = instance.h or 8
    -- Default collision height

    -- Drawing properties
    instance.sprite = instance.sprite or 0
    -- Default or starting sprite
    instance.sprite_w_cells = instance.sprite_w_cells or 1
    -- Sprite width in 8x8 cells
    instance.sprite_h_cells = instance.sprite_h_cells or 1
    -- Sprite height in 8x8 cells
    instance.flip_x = instance.flip_x or false
    instance.flip_y = instance.flip_y or false
    instance.visible = instance.visible or true
    -- To easily hide entities

    -- Common state flags
    instance.triggered = instance.triggered or false
    instance.active = instance.active or true
    -- To easily disable entities (stops update, draw, collision)

    -- Animation properties (we'll expand on this)
    instance.animation = instance.animation or nil
    -- Will hold animation data
    instance.current_anim_frame_index = 1
    instance.anim_timer = 0
    instance.current_display_sprite = instance.sprite
    -- Sprite to actually draw

    return instance
end

-- Default draw method
function BaseEntity:draw()
    if not self.active or not self.visible then return end
    spr(self.current_display_sprite, self.x, self.y, self.sprite_w_cells, self.sprite_h_cells, self.flip_x, self.flip_y)
end

-- Default update method
function BaseEntity:update()
    if not self.active then return end
    self:_update_animation()
    -- Call animation update logic
    -- Specific entity update logic will be called if overridden
end

-- Default event method (called on collision)
function BaseEntity:event(player_obj)
    if not self.active then return end
    -- Default behavior: mark as triggered.
    -- Specific entities will almost always override this for unique interactions.
    self.triggered = true
    if debug then
        --print("default event for: " .. self.name .. " triggered by: " .. player_obj.name)
        dialogue:show("bingus", narrator)
    end
end

-- Default player collision check
function BaseEntity:check_player_collision(player_obj)
    if not self.active or self.triggered or not self.visible then return false end

    -- Basic AABB collision check
    -- Assumes player_obj has x, y, w, h properties
    -- Assumes self (entity) has x, y, w, h properties
    if player_obj.x < self.x + self.w
            and player_obj.x + player_obj.w > self.x
            and player_obj.y < self.y + self.h
            and player_obj.y + player_obj.h > self.y then
        self:event(player_obj) -- Calls the entity's specific event method
        return true
    end
    return false
end

-- Animation handling (internal to BaseEntity)
function BaseEntity:_update_animation()
    if not self.active or not self.animation or #self.animation.frames == 0 then
        self.current_display_sprite = self.sprite -- Fallback to base sprite if no animation
        return
    end

    local anim = self.animation
    self.anim_timer += 1

    if self.anim_timer >= (anim.speed or 10) then
        -- Default speed of 10 game frames
        self.anim_timer = 0
        self.current_anim_frame_index += 1
        if self.current_anim_frame_index > #anim.frames then
            if anim.loop == false then
                -- Check for explicit false, otherwise default to loop
                self.current_anim_frame_index = #anim.frames -- Stay on last frame
                if anim.on_complete then
                    anim:on_complete(self) -- Call on_complete if defined
                end
            else
                self.current_anim_frame_index = 1 -- Loop back to start
            end
        end
    end
    self.current_display_sprite = anim.frames[self.current_anim_frame_index]
end

-- Helper to set/change animation
function BaseEntity:set_animation(animation_config)
    -- animation_config should be a table like:
    -- { frames = {sprite1, sprite2, ...}, speed = 5, loop = true/false, on_complete = function(self) ... end }
    self.animation = animation_config
    self.current_anim_frame_index = 1
    self.anim_timer = 0
    if self.animation and #self.animation.frames > 0 then
        self.current_display_sprite = self.animation.frames[1]
    else
        self.current_display_sprite = self.sprite -- Fallback
    end
end

-- You'll need to include this file in your main .p8 file:
-- #include entities.p8

-- And then you can define entities like so in your main file:
-- entities = {
--   BaseEntity:new({
--     name = "animated_guy",
--     x = 50, y = 50,
--     sprite = 16, -- Default sprite if no animation or before anim starts
--     animation = {
--       frames = {16, 17, 18, 17}, -- Sprite numbers for animation
--       speed = 8,  -- Change frame every 8 game updates
--       loop = true
--     },
--     event = function(self, player_obj)
--       dialogue:show("I'm animated!", self)
--       -- Example: change animation on event
--       -- self:set_animation({ frames = {20, 21}, speed = 10, loop = false, on_complete = function(e) e.active = false end })
--     end
--   })
-- }

-- Remember your point_rect_collision, needs player w/h
-- If pl is just a point, you might need to adjust point_rect_collision or give pl w/h for collision.
-- For simplicity, I assumed player_obj for collision check has x,y,w,h.
-- Your current pl object for collision is a point (x,y).
-- The point_rect_collision(p, r) is:
-- return p.x >= r.x and p.x <= r.x + r.w and p.y >= r.y and p.y <= r.y + r.h
-- This is fine if 'pl' is considered a point. If 'pl' should have dimensions,
-- then the check_player_collision needs to account for that, or pl needs w,h.
