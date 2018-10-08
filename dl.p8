pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

local ground_level = 64

-- player
local p={
 x=0,
 y=ground_level,
 flip=false,
 tile=1,
 velx=0,
 vely=0,
 punchvelx=0,
 punchvely=0,
 punching=0,
 punch_cooloff=0
 }

local enemies={}
local update_count=0

function draw_char(e)
 spr(e.tile, e.x, e.y, 1, 2, e.flip) 
end

function char_logic(c)
 if c.velx < 0 then c.flip = true end
 if c.velx > 0 then c.flip = false end

 c.vely += 1 --gravity
 --fritction
 c.punchvelx *= 0.8
 c.punchvely *= 0.8 

 c.x += c.velx + c.punchvelx
 c.y += c.vely + c.punchvely
 
 if c.x < 0 then c.x = 0 end
 
 if c.y >= ground_level then
  c.y = ground_level
  c.vely = 0
 end
end

function enemy_logic(e)
 if e.tick == nil then e.tick = 0 end
 if e.agro > 0 then
  e.velx = sgn(p.x - e.x) * 1.5
  e.agro -= 1
 else
  srand(update_count+e.id*1000)
  local r = flr(rnd(16))
  if r == 0 then e.velx = -0.5 end
  if r == 1 then e.velx = 0.5 end
  if r > 12 then e.velx = 0 end
  local dx = abs(p.x - e.x)
  if dx < 64 then
   if flr(rnd(300)) == 0 then
    e.agro = 64
   end
  end
 end 
end

function create_enemy(n)
 srand(n)
 local e={
  x=128 + flr(rnd(6000)),
  y=ground_level,
  flip=true, 
  tile=4,
  velx=0,
  vely=0,
  punchvelx=0,
  punchvely=0,
  id=n,
  agro=0
  }
 return e
end

function _init()
 for i=1,120 do
  local e = create_enemy(i)
  add(enemies, e)
 end
end

function _draw() 
 camera(0,0)
 cls(0)
 --print(p.punching)
 --print(p.punch_cooloff)
 --print(btnp(❎))
 print("day 1                @ricotweet")

 rectfill(0,32,128,95,7)
 
 local camx=p.x - 48
 if camx < 0 then camx=0 end
 camera(camx, 0)
 
 for i=0,20 do
  map(0,0, i*128,32, 16,16)
 end
 for n=1,#enemies
 do
  local e = enemies[n]
  draw_char(e)
  if e.agro > 0 then
   spr(36,e.x,e.y-8)
  end
 end 
 draw_char(p)
 if p.punching > 0 then
  spr(3, p.x+8, p.y+3)
 end
end

local xreleased=true
function player_logic(p)
 local speed = btn(❎) and 2 or 1
 
 p.velx = 0
 if(btn(⬅️)) then 
  p.velx = -speed
 end
 if(btn(➡️)) then 
  p.velx = speed
 end
 if btn(🅾️) and p.y == ground_level then
  p.vely = -10 -- jump
 end
 if not btn(❎) then xreleased = true end
 if btn(❎) and xreleased and p.punch_cooloff == 0 then
  p.punch_cooloff = 64
  p.punching = 16
  xreleased = false
 end
 
 -- collision
 for n=1,#enemies 
 do
  local e = enemies[n]
  local dx = e.x - p.x
  local dy = e.y - p.y
  if dx > -8 and dx < 8 then
   if dy > -16 and dy < 16 then
    if p.punching > 0 then
     e.punchvelx = 15
     e.agro = 128
     --get neighbour
     local nn = enemies[1]
     for m=2,#enemies
     do
      local ndx = abs(e.x - nn.x)
      if e != nn then
       if ndx > abs(e.x - enemies[m].x) then
        nn = enemies[m]
       end
      end
     end
     nn.agro = 128
     
     --cursor()
     --print(e.id)
     --print(nn.id)
     --stop(2)
     
    else
     if e.agro > 0 then
      p.punchvelx = -15
     end
    end
   end
  end
 end 

 if p.punching > 0 then
  p.punching -= 1
 end
 if p.punch_cooloff > 0 then
  p.punch_cooloff -= 1
 end
end

function _update()
 update_count+=1

 player_logic(p)
 char_logic(p)
 
 for n=1,#enemies 
 do
  char_logic(enemies[n])
  enemy_logic(enemies[n])
 end 

end

__gfx__
00000000000000000000000000000000000000005555555555555555444444440000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb000000000000000000000888805555555555555555444444440000000000000000000000000000000000000000000000000000000000000000
007007000bbbbbb000000000000eee000088888855ccccc55ccccc55444444440000000000000000000000000000000000000000000000000000000000000000
00077000bbbfffb0000000000eeeee800888fff855ccccc55ccccc55444444440000000000000000000000000000000000000000000000000000000000000000
00077000bbf1f100000000000eeeee80088f1f1055ccccc55ccccc55444444440000000000000000000000000000000000000000000000000000000000000000
007007000bffff0000000000000eee00008ffff05555555555555555444444440000000000000000000000000000000000000000000000000000000000000000
0000000000666600dddddddd00000000000222205555555555555555444444440000000000000000000000000000000000000000000000000000000000000000
000000000066660000000d00000000000002222055ccccc55ccccc55444444440000000000000000000000000000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55444444440000000000000000000000000000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55444455440000000000000000000000000000000000000000000000000000000000000000
66666666006666000000000000000000000222205555555555555555444556540000000000000000000000000000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55446666540000000000000000000000000000000000000000000000000000000000000000
666666660030030000000000000000000009009055ccccc55ccccc55444555540000000000000000000000000000000000000000000000000000000000000000
666666660030030000000000000000000009009055ccccc55ccccc55444555540000000000000000000000000000000000000000000000000000000000000000
66666666003003000000000000000000000900905555555555555555444455440000000000000000000000000000000000000000000000000000000000000000
66666666003303300000000000000000000990995555555555555555444444440000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000506000000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001516000000151600070700000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020200071700020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
