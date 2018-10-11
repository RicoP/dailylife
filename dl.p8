pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- globals
local update=0
local draw=0
local enemies={}
local update_count=0

-- helper function for buttons state
do
 local state = {0,0,0,0,0,0}
 btn_update=function ()
  for b=0,6 do
   if state[b] == 0 and btn(b) then
    state[b] = 1
   elseif state[b] == 1 then
    state[b] = 2
   elseif state[b] == 2 and not btn(b) then
    state[b] = 3
   elseif state[b] == 3 then
    state[b] = 0
   end
  end
 end

 btnd=function (b)
  return state[b] == 1
 end

 btnu=function (b)
  return state[b] == 3
 end
 --https://www.lexaloffle.com/bbs/?pid=18374#p18374
 qsort=function (t, cmp, i, j)
  i = i or 1
  j = j or #t
  if i < j then
   local p = i
   for k = i, j - 1 do
    if cmp(t[k], t[j]) <= 0 then
     t[p], t[k] = t[k], t[p]
     p = p + 1
    end
   end
   t[p], t[j] = t[j], t[p]
   qsort(t, cmp, i, p - 1)
   qsort(t, cmp, p + 1, j)  
  end
 end
end

-- game logic
do
 local ground_level = 64
 local exit_pos=88
 local day=1
 -- player
 local p={
  }

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

 function char_logic(c)
  if c.velx < 0 then c.flip = true end
  if c.velx > 0 then c.flip = false end
 
  c.vely += 1 --gravity
  --friction
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
 
 function next_stage()
  day += 1
 end
 
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
  if btnd(❎) and p.punch_cooloff == 0 then
   p.punch_cooloff = 64
   p.punching = 16
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
 
  -- punch cooloff
  if p.punching > 0 then
   p.punching -= 1
  end
  if p.punch_cooloff > 0 then
   p.punch_cooloff -= 1
  end
 end

 function draw_char(e)
  spr(e.tile, e.x, e.y, 1, 2, e.flip)
 end
  
 game_init=function ()
  p={
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
  enemies={}
  for i=1,90 do
   local e = create_enemy(i)
   add(enemies, e)
  end
  -- sort by x position
  qsort(enemies,function (l,r)
   return l.x - r.x
  end)
  
  update_count=0
 end
 
 game_update=function ()
  update_count+=1
 
  player_logic(p)
  char_logic(p)
 
  for n=1,#enemies
  do
   char_logic(enemies[n])
   enemy_logic(enemies[n])
  end
 
   -- player at exit
  if p.x >= exit_pos then
   next_stage()
  end
 end

 game_draw=function ()
  cls(0)
  camera(0,0)
  print("day " .. tostr(day))
  cursor(89,0)
  print("@ricotweet")
 
  rectfill(0,32,128,95,7)
 
  local camx=p.x - 48
  if camx < 0 then camx=0 end
  camera(camx, 0)
 
  for i=0,20 do
   map(0,0, i*128,32, 16,16)
  end
 
  -- draw exit
  spr(9,exit_pos,56,2,3) 
 
  for n=1,#enemies
  do
   local e = enemies[n]
   draw_char(e)
   if e.agro > 0 then
    spr(36,e.x,e.y-8)
   end
  end
  -- draw player
  if p.punching == 0 then
   spr(p.tile, p.x, p.y, 1, 2, p.flip)
  else
    spr(p.tile, p.x - 2, p.y, 1, 1, p.flip)
    spr(3, p.x, p.y+8)
  end
  if p.punching > 0 then
  end
 end
end

function _init()
 update=game_update
 draw=game_draw
 game_init()
end

function _update()
 btn_update()
 update()
end

function _draw()
 draw()
end

__gfx__
00000000000000000000000066660000000000005555555555555555aaaaaaaaaaaaaaaa99999999999999990000000000000000000000000000000000000000
0000000000bbbb000000000066660000000888805555555555555555aaaaaaaaaaaaaaaa97777755ccccccc90000000000000000000000000000000000000000
007007000bbbbbb000000000666600030088888855ccccc55ccccc55aaaaaaaaaaaaaaaa97777755ccccccc90000000000000000000000000000000000000000
00077000bbbfffb000000000666633330888fff855ccccc55ccccc55aa111111111aaaaa97777755ccccccc90000000000000000000000000000000000000000
00077000bbf1f1000000000030000000088f1f1055ccccc55ccccc55aa1fffffff1aaaaa97777755ccccccc90000000000000000000000000000000000000000
007007000bffff000000000030000000008ffff05555555555555555aa1fffffff1aaaaa97777755ccccccc90000000000000000000000000000000000000000
0000000000666600dddddddd30000000000222205555555555555555aa1fffffff1aaaaa97777755555555590000000000000000000000000000000000000000
000000000066660000000d00330000000002222055ccccc55ccccc55aa1fffffff1aaaaa97777777777777790000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55aa1fffffff1aaaaa97777777777777790000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55aa1fffffff1aaaaa97777777777777790000000000000000000000000000000000000000
66666666006666000000000000000000000222205555555555555555aa1fffffff1aaaaa97777777777777790000000000000000000000000000000000000000
666666660066660000000000000000000002222055ccccc55ccccc55aa111111111a55aa95fffffffffffff90000000000000000000000000000000000000000
666666660030030000000000000000000009009055ccccc55ccccc55aaaaaaaaaaaa565a956ffffffffffff90000000000000000000000000000000000000000
666666660030030000000000000000000009009055ccccc55ccccc55aaaaaaaaaa66665a956f5fff444444490000000000000000000000000000000000000000
66666666003003000000000000000000000900905555555555555555aaaaaaaaaaaa555a95ff5ffff44444490000000000000000000000000000000000000000
66666666003303300000000000000000000990995555555555555555aaaaaaaaaaaa555a95ff5fffffffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaa55aa95ff5fffffffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5fffffffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff555555ffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5ffff5ffff690000000000000000000000000000000000000000
00000000000000000000000000000000088888880000000000000000aaaaaaaaaaaaaaaa9fff5ffff5ffff690000000000000000000000000000000000000000
00000000000000000000000000000000008888800000000000000000aaaaaaaaaaaaaaaa9fff5ffff5fffff90000000000000000000000000000000000000000
00000000000000000000000000000000000888000000000000000000aaaaaaaaaaaaaaaa9ffffffffffffff90000000000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000aaaaaaaaaaaaaaaa99999999999999990000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000506000000050600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001516000000151600070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020200171800020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000272800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
