pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- globals
local update=0
local draw=0
local enemies={}
local p={} -- player
local update_count=0
local day=1
local wayback=false

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
 
 frnd=function (n)
  return flr(rnd(n))
 end

 sort_enemies=function () 
  qsort(enemies, function (l,r)
   -- sort by distance to player
   local dl = abs(p.x-l.x)
   local dr = abs(p.x-r.x)
   return dl - dr
  end)
 end
end

-- menu logic
do
 function print_centered(str, y)
  print(str, 64 - (#str * 2), y) 
 end
 menu_init=function ()
  menu_time=200
  update=function()
   if btnd(❎) then
    game_init()
    game_start()
   end
  end
  draw=function ()
   cls(9)
   rectfill(1,1,126,126,0)
   color(7)
   
   cursor(0,40)
   print_centered("daily life", 40)
   print_centered("day " .. tostr(day), 48)
   print_centered("press ❎ to start", 56)
   print_centered("❎ = jump", 64)
   print_centered("🅾️ = kick", 72)
  end
 end
end

-- class logic
do
 class_init=function ()
  local class_time = 100
  update=function ()
   class_time-=1
   if class_time == 0 then
    game_start()
   end
  end
  
  draw=function ()
   cls(7)
   camera(0,0)
   map(16,0, 0,32, 16,16)
   local talk = ((class_time / 12)%2)
   spr(64 + talk, 5*8,7*8)
   rectfill(0,0,128,32,0)
   rectfill(0,96,128,128,0)
  end
  
  for i=1,#enemies do
   enemies[i].agro = 0
  end
 end
end

-- game logic
do
 local ground_level = 64
 local exit_pos=88

 function create_enemy(n)
  srand(n + day*100)
  local e={
   x=128 + frnd(6000),
   y=ground_level,
   flip=true,
   tile=11 + frnd(5),
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
 
  if c.y >= ground_level then
   c.y = ground_level
   c.vely = 0
  end
 end
 
 function enemy_logic(e)
  srand(update_count+e.id*1000)
  if e.agro > 0 then
   local v = abs(p.x, e.x) > 30 and 2 or 1
   e.velx = sgn(p.x - e.x) * v
   e.agro -= 1
  else
   -- idle
   local r = frnd(16)
   if r == 0 then e.velx = -0.5 end
   if r == 1 then e.velx = 0.5 end
   if r > 12 then e.velx = 0 end
   local dx = abs(p.x - e.x)
   if dx < 64 then
    if frnd(300) == 0 then
     e.agro = 64
    end
   end
  end
 end
 
 function next_stage()
  if wayback then
   day += 1
   wayback = false
   menu_init()
  else
   wayback = true
   class_init()
  end
 end
 
 function check_player_enemy_collision()
  local e = enemies[1] -- closest enemy
  local n = enemies[2] -- neighbour
  local dx = e.x - p.x
  local dy = e.y - p.y
  if dx > -8 and dx < 8 then
   if dy > -16 and dy < 16 then
    if p.punching > 0 then
     -- punch enemy
     e.punchvelx = wayback and -15 or 15
     e.agro = 128
     n.agro = 128
    else
     -- get punched
     if e.agro > 0 then
      p.punchvelx = wayback and 15 or -15
     end
    end
   end
  end
 end

	function player_max()
	 return exit_pos + 120
	end
 
 function player_logic(p)
  local speed = 2
 
  p.velx = 0
  if(btn(⬅️)) then
   p.velx = -speed
  end
  if(btn(➡️)) then
   p.velx = speed
  end
  if (btn(🅾️) or btn(⬆️)) and p.y == ground_level then
   p.vely = -10 -- jump
  end
  if btnd(❎) and p.punch_cooloff == 0 then
   p.punch_cooloff = 64
   p.punching = 16
  end
 
  check_player_enemy_collision()
 
  -- punch cooloff
  if p.punching > 0 then
   p.punching -= 1
  end
  if p.punch_cooloff > 0 then
   p.punch_cooloff -= 1
  end
  
  if(p.x < 0) p.x = 0
  if(p.x > player_max()) p.x = player_max()
 end

 function draw_char(e)
  spr(e.tile, e.x, e.y, 1, 2, e.flip)
 end

 game_start=function ()
  update=game_update
  draw=game_draw 
 end

 reset_enemies=function ()
  enemies={}
  for i=1,90 do
   local e = create_enemy(i)
   add(enemies, e)
  end

  sort_enemies()
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

  reset_enemies() 

  for i=1,#enemies do
   printh(tostr(enemies[i].id))
  end
  
  update_count=0
  srand(day)
  exit_pos=88+256+128*frnd(3)  
 end
 
 game_update=function ()
  update_count+=1
 
  player_logic(p)
  char_logic(p)
 
  for n=1,#enemies
  do
   local e = enemies[n]
   if e.x < 20 + player_max() then
    -- ignore enemies which are outside out range
    char_logic(e)
    enemy_logic(e)
   end
  end
  sort_enemies()
   -- player at exit
  if p.x >= exit_pos and not wayback then
   next_stage()
  end
  if p.x <= 0 and wayback then
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
  if camx > exit_pos then camx=exit_pos end
  camera(camx, 0)
 
  for i=0,20 do
   map(0,0, i*128,32, 16,16)
   print(tostr(101+i),i*128+90,50,6)
  end
 
  -- draw exit
  if not wayback then
   spr(9,exit_pos,56,2,3) 
  end
 
  if (update_count % 20) < 10 then
   spr(3,exit_pos + 96,32,2,1,true)
  end

  for n=1,#enemies
  do
   local e = enemies[n]
   draw_char(e)
   if e.agro > 0 then
    spr(43,e.x,e.y-8)
   end
  end
  -- draw player
  if p.punching == 0 then
   spr(1, p.x, p.y, 1, 2, p.flip)
  else
   if not wayback then
    spr(1, p.x - 2, p.y, 1, 1, p.flip)
    spr(18, p.x, p.y+8, 1, 1, false)
   else
    spr(1, p.x + 2, p.y, 1, 1, p.flip)
    spr(18, p.x, p.y+8, 1, 1, true)
   end
  end
 end
end

-- system intern stuff
function _init()
 menu_init()
end

function _update()
 btn_update()
 update()
end

function _draw()
 draw()
end

__gfx__
00000000000000000000000000000000000000005555555555555555aaaaaaaaaaaaaaaa99999999999999990000000000000000000000000000000000000000
0000000000bbbb000000000000000000000800005555555555555555aaaaaaaaaaaaaaaa97777755ccccccc90001111000022220000888800003333000022220
007007000bbbbbb000000000000000000008800055ccccc55ccccc55aaaaaaaaaaaaaaaa97777755ccccccc90011111100222222008888880033333300222222
00077000bbbfffb000000000008888888888880055ccccc55ccccc55aa111111111aaaaa97777755ccccccc901114441022277720888fff8033344430222fff2
00077000bbf1f10000000000008888888888888055ccccc55ccccc55aa1fffffff1aaaaa97777755ccccccc90114545002271710088f1f1003341410022f1f10
007007000bffff000000000000888888888888005555555555555555aa1fffffff1aaaaa97777755ccccccc90014444000277770008ffff000344440002ffff0
0000000000666600dddddddd00000000000880005555555555555555aa1fffffff1aaaaa9777775555555559000dddd000055550000222200001111000044440
000000000066660000000d00000000000008000055ccccc55ccccc55aa1fffffff1aaaaa9777777777777779000dddd000055550000222200001111000044440
666666660066660066660000000000000000000055ccccc55ccccc55aa1fffffff1aaaaa9777777777777779000dddd000055550000222200001111000044440
666666660066660066660000000000000000000055ccccc55ccccc55aa1fffffff1aaaaa9777777777777779000dddd000055550000222200001111000044440
66666666006666006666000300000000000000005555555555555555aa1fffffff1aaaaa9777777777777779000dddd000055550000222200001111000044440
666666660066660066663333000000000000000055ccccc55ccccc55aa111111111a55aa95fffffffffffff9000dddd000055550000222200001111000044440
666666660030030030000000000000000000000055ccccc55ccccc55aaaaaaaaaaaa565a956ffffffffffff90003003000010010000900900002002000090090
666666660030030030000000000000000000000055ccccc55ccccc55aaaaaaaaaa66665a956f5fff444444490003003000010010000900900002002000090090
66666666003003003000000000000000000000005555555555555555aaaaaaaaaaaa555a95ff5ffff44444490003003000010010000900900002002000090090
66666666003303303300000000000000000000005555555555555555aaaaaaaaaaaa555a95ff5fffffffff690003303300011011000990990002202200099099
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaa55aa95ff5fffffffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5fffffffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff555555ffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5ffff5ffff690000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5ffff5ffff690888888800000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9fff5ffff5fffff90088888000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa9ffffffffffffff90008880000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaa99999999999999990000800000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000003333333300000000000000000000000000000000000000006666666666666666666666666666666600000000000000000000000000000000
0000000005555550333333330000000000000000000000000000000000bbbb006666666666666666666666665555555600000000000000000000000000000000
05555550055fff5033333333000000000000000000000000000000000bbbbbb06666666066666666666666656666665600000000000000000000000000000000
055fff5005f1f1003333333300000000000000000000000000000000bbbfffb06666666066666666666666656666656600000000000000000000000000000000
05f1f10005ffff003333333300000444444444444444444444440000bbf1f1006666660066666666666666566666656600000000000000000000000000000000
05ffff0000ff110033333333000044444444444444444444444400000bffff006666660066666666666666566666566600000000000000000000000000000000
00444400004444003333333300004444444444444444444444400000006666006666600066666666666665666666566600000000000000000000000000000000
00444400004444003333333300044444444444444444444444400000006666006666600066666666666655666665666600000000000000000000000000000000
00444400aaaaaaaa7777777700044444444444444444444444000000006666006666000060000000666656666665666600000000000000000000000000000000
00444400aaaaaaaa7777777700444444444444444444444444000000006666006666000060000000666566666656666600000000000000000000000000000000
00444400aaaaaaaa7777777700444444444444444444444440000000006666006660000060000000666566666656666600000000000000000000000000000000
00444400aaaaaaaa7777777700000600000000000000060000000000006666006660000060000000665666666566666600000000000000000000000000000000
00d00d00aaaaaaaa7777777700000600000000000000060000000000003003006600000060000000665666666566666600000000000000000000000000000000
00d00d00aaaaaaaa7777777700000600000000000000060000000000003003006600000060000000656666665666666600000000000000000000000000000000
00d00d00aaaaaaaa7777777700000600000000000000060000000000003003006000000060000000655555555666666600000000000000000000000000000000
00dd0dd0aaaaaaaa7777777700000600000000000000060000000000003303306000000060000000666666666666666600000000000000000000000000000000
__map__
0000000000000000000000000000000049494949494949494949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000049104949494942424242424249494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000506000000050600000000000010104949494942424242424249494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001516000000151600070800000010104949494942424242424249494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020200171800020249494800005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000272800000049495843444546004344454600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101049480053545556005354555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101049580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
