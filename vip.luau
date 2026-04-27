_G.FastAttack = true

if _G.FastAttack then
    local _ENV = (getgenv or getrenv or getfenv)()

    local function SafeWaitForChild(parent, childName)
        local success, result = pcall(function()
            return parent:WaitForChild(childName)
        end)
        if not success or not result then
            warn("noooooo: " .. childName)
        end
        return result
    end

    local function WaitChilds(path, ...)
        local last = path
        for _, child in {...} do
            last = last:FindFirstChild(child) or SafeWaitForChild(last, child)
            if not last then
                break
            end
        end
        return last
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer

    if not Player then
        warn(".")
        return
    end

    local Remotes = SafeWaitForChild(ReplicatedStorage, "Remotes")
    if not Remotes then
        return
    end

    local Validator = SafeWaitForChild(Remotes, "Validator")
    local CommF = SafeWaitForChild(Remotes, "CommF_")
    local CommE = SafeWaitForChild(Remotes, "CommE")

    local ChestModels = SafeWaitForChild(workspace, "ChestModels")
    local WorldOrigin = SafeWaitForChild(workspace, "_WorldOrigin")
    local Characters = SafeWaitForChild(workspace, "Characters")
    local Enemies = SafeWaitForChild(workspace, "Enemies")
    local Map = SafeWaitForChild(workspace, "Map")

    local EnemySpawns = SafeWaitForChild(WorldOrigin, "EnemySpawns")
    local Locations = SafeWaitForChild(WorldOrigin, "Locations")

    local RenderStepped = RunService.RenderStepped
    local Heartbeat = RunService.Heartbeat
    local Stepped = RunService.Stepped

    local Modules = SafeWaitForChild(ReplicatedStorage, "Modules")
    local Net = SafeWaitForChild(Modules, "Net")

    local sethiddenproperty = sethiddenproperty or function(...)
        return ...
    end
    local setupvalue = setupvalue or (debug and debug.setupvalue)
    local getupvalue = getupvalue or (debug and debug.getupvalue)

    local Settings = {
        AutoClick = true,
        ClickDelay = 0
    }

    local Module = {}

    Module.FastAttack = (function()
        if _ENV.rz_FastAttack then
            return _ENV.rz_FastAttack
        end

        local FastAttack = {
            Distance = 1000,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil
        }

        local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
        local RegisterHit = SafeWaitForChild(Net, "RE/RegisterHit")

        local function IsAlive(character)
            return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
        end

        local function ProcessEnemies(OthersEnemies, Folder)
            local BasePart = nil
            for _, Enemy in Folder:GetChildren() do
                local Head = Enemy:FindFirstChild("Head")
                if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < FastAttack.Distance then
                    if Enemy ~= Player.Character then
                        table.insert(OthersEnemies, {Enemy, Head})
                        BasePart = Head
                    end
                end
            end
            return BasePart
        end

        function FastAttack:Attack(BasePart, OthersEnemies)
            if not BasePart or #OthersEnemies == 0 then
                return
            end
            RegisterAttack:FireServer(Settings.ClickDelay or 0)
            RegisterHit:FireServer(BasePart, OthersEnemies)
        end

        function FastAttack:AttackNearest()
            local OthersEnemies = {}
            local Part1 = ProcessEnemies(OthersEnemies, Enemies)
            local Part2 = ProcessEnemies(OthersEnemies, Characters)

            local character = Player.Character
            if not character then
                return
            end
            local equippedWeapon = character:FindFirstChildOfClass("Tool")

            if equippedWeapon and equippedWeapon:FindFirstChild("LeftClickRemote") then
                for _, enemyData in ipairs(OthersEnemies) do
                    local enemy = enemyData[1]
                    local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
                    pcall(function()
                        equippedWeapon.LeftClickRemote:FireServer(direction, 1)
                    end)
                end
            elseif #OthersEnemies > 0 then
                self:Attack(Part1 or Part2, OthersEnemies)
            else
                task.wait(0)
            end
        end

        function FastAttack:BladeHits()
            local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip ~= "Gun" then
                self:AttackNearest()
            else
                task.wait(0)
            end
        end

        task.spawn(function()
            while task.wait(Settings.ClickDelay) do
                if Settings.AutoClick then
                    FastAttack:BladeHits()
                end
            end
        end)

        _ENV.rz_FastAttack = FastAttack
        return FastAttack
    end)()
end
local remote, idremote
for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes,
                    game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end
task.spawn(function()
    while task.wait(0.05) do
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts + 1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and
            (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then
                    return
                end
                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(
                    game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(
                        bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                end), bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head,
                    parts)
            end)
        end
    end
end)

--[[ 
    OPTIMIZED FAST ATTACK (SIÊU TỐC)
    - Đã loại bỏ giới hạn tốc độ.
    - Đã gộp các luồng xử lý.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")

-- Cấu hình cực đại
getgenv().PMT_GunFast = true
getgenv().PMT_GunFast_Delay = 0 -- Không có độ trễ súng
getgenv().PMT_GunFast_PrimeEvery = 0 -- Prime súng liên tục

local Config = {
    AttackDistance = 700, -- Tăng nhẹ tầm đánh
    AttackMobs = true,
    AttackPlayers = true,
    AttackCooldown = 0, -- KHÔNG CÓ COOLDOWN
    HitboxLimbs = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, 
    AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        EnemyRootPart = nil,
        _GunLastPrime = 0,
        _GunLastShot = 0,
        _LastGunTargetModel = nil,
        HitFunction = nil
    }, FastAttack)

    -- Cố gắng lấy hàm đánh từ client gốc để bypass anti-cheat (nếu có)
    pcall(function()
        local ls = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if ls and getsenv then 
            self.HitFunction = getsenv(ls)._G.SendHitsToServer 
        end
    end)
    return self
end

function FastAttack:IsEntityAlive(e)
    local h = e and e:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

-- Hàm tìm quái/người chơi gần nhất cực nhanh
function FastAttack:GetBladeHits(c, dist)
    local pos = c:GetPivot().Position
    local bh = {}
    dist = dist or Config.AttackDistance

    local function proc(folder)
        if not folder then return end
        for _, e in ipairs(folder:GetChildren()) do
            if e ~= c and self:IsEntityAlive(e) then
                local root = e:FindFirstChild("HumanoidRootPart")
                if root and (pos - root.Position).Magnitude <= dist then
                    -- Ưu tiên đánh vào Head hoặc RootPart để chắc chắn trúng
                    local hitPart = e:FindFirstChild("Head") or root 
                    table.insert(bh, {e, hitPart})
                    self.EnemyRootPart = root -- Lưu lại mục tiêu chính
                end
            end
        end
    end

    if Config.AttackMobs then proc(Workspace:FindFirstChild("Enemies")) end
    if Config.AttackPlayers then proc(Workspace:FindFirstChild("Characters")) end
    return bh
end

function FastAttack:Attack()
    if not Config.AutoClickEnabled then return end
    
    local char = Player.Character
    if not char or not self:IsEntityAlive(char) then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Xử lý Súng (Gun) siêu tốc
    if tool.ToolTip == "Gun" and getgenv().PMT_GunFast then
        -- Prime súng (nạp đạn ảo)
        pcall(function() tool:Activate() end)
        
        -- Bắn
        local targets = self:GetBladeHits(char, 120)
        local targetParams = targets[1] -- Lấy mục tiêu gần nhất
        if targetParams then
            local enemyModel = targetParams[1]
            local enemyPart = targetParams[2]
            
            -- Bắn thẳng vào vị trí mục tiêu
            pcall(function()
                ShootGunEvent:FireServer(enemyPart.Position, {enemyPart})
            end)
        end
        return -- Kết thúc xử lý súng để không bị kẹt với Melee
    end

    -- Xử lý Cận chiến (Melee/Sword/Fruit)
    local hits = self:GetBladeHits(char)
    if #hits > 0 then
        -- Gửi tín hiệu tấn công (Swing)
        RegisterAttack:FireServer(0) 
        
        -- Gửi tín hiệu trúng đòn (Hit) ngay lập tức
        if self.HitFunction then
            -- Dùng hàm game gốc nếu lấy được (an toàn hơn)
            self.HitFunction(self.EnemyRootPart, hits)
        else
            -- Dùng hàm giả lập (nhanh hơn nhưng rủi ro kick cao hơn)
            -- Cấu trúc: {Head, { {Model, HitPart}, ... } }
            local args = {nil, {}}
            args[1] = hits[1][2] -- Head hoặc part đầu tiên
            
            for i, v in ipairs(hits) do
                args[2][i] = v -- {Model, Part}
            end
            
            RegisterHit:FireServer(unpack(args))
        end
    end
end

-- KHỞI CHẠY
local AttackInstance = FastAttack.new()

-- Sử dụng Heartbeat: Chạy mỗi frame (nhanh hơn loop while do thông thường)
RunService.Heartbeat:Connect(function()
    pcall(function()
        AttackInstance:Attack()
    end)
end)

-- Hook function để đè lên hành động đánh thường của người chơi (nếu click tay)
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self.Name == "RegisterAttack" then
        AttackInstance:Attack() -- Gọi Fast Attack khi click
        return -- Chặn tín hiệu gốc để tránh spam thừa
    end
    return old(self, ...)
end)
setreadonly(mt, true)

-- ts file was generated at discord.gg/25ms

local v1 = next
local v2 = {
    game.ReplicatedStorage.Util,
    game.ReplicatedStorage.Common,
    game.ReplicatedStorage.Remotes,
    game.ReplicatedStorage.Assets,
    game.ReplicatedStorage.FX,
}
local v3 = nil
local u4 = nil
local u5 = nil

while true do
    local v6

    v3, v6 = v1(v2, v3)

    if v3 == nil then
        break
    end

    local v7 = next
    local v8, v9 = v6:GetChildren()

    while true do
        local v10

        v9, v10 = v7(v8, v9)

        if v9 == nil then
            break
        end
        if v10:IsA('RemoteEvent') and v10:GetAttribute('Id') then
            u5 = v10:GetAttribute('Id')
            u4 = v10
        end
    end

    v6.ChildAdded:Connect(function(p11)
        if p11:IsA('RemoteEvent') and p11:GetAttribute('Id') then
            u5 = p11:GetAttribute('Id')
            u4 = p11
        end
    end)
end

task.spawn(function()
    while task.wait(0.0001) do
        local _Character = game.Players.LocalPlayer.Character
        local v13

        if _Character then
            v13 = _Character:FindFirstChild('HumanoidRootPart')
        else
            v13 = _Character
        end

        local v14, v15, v16 = ipairs({
            workspace.Enemies,
            workspace.Characters,
        })
        local u17 = {}

        while true do
            local v18

            v16, v18 = v14(v15, v16)

            if v16 == nil then
                break
            end

            local v19, v20, v21 = ipairs(v18 and v18:GetChildren() or {})

            while true do
                local v22

                v21, v22 = v19(v20, v21)

                if v21 == nil then
                    break
                end

                local _HumanoidRootPart = v22:FindFirstChild('HumanoidRootPart')
                local _Humanoid = v22:FindFirstChild('Humanoid')

                if v22 ~= _Character and (_HumanoidRootPart and (_Humanoid and (_Humanoid.Health > 0 and (_HumanoidRootPart.Position - v13.Position).Magnitude <= 60))) then
                    local v25, v26, v27 = ipairs(v22:GetChildren())

                    while true do
                        local v28

                        v27, v28 = v25(v26, v27)

                        if v27 == nil then
                            break
                        end
                        if v28:IsA('BasePart') and (_HumanoidRootPart.Position - v13.Position).Magnitude <= 60 then
                            u17[#u17 + 1] = {v22, v28}
                        end
                    end
                end
            end
        end

        local _Tool = _Character:FindFirstChildOfClass('Tool')

        if #u17 > 0 and (_Tool and (_Tool:GetAttribute('WeaponType') == 'Melee' or _Tool:GetAttribute('WeaponType') == 'Sword')) then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent('RegisterHit', true)
                game.ReplicatedStorage.Modules.Net['RE/RegisterAttack']:FireServer()

                local _Head = u17[1][1]:FindFirstChild('Head')

                if _Head then
                    game.ReplicatedStorage.Modules.Net['RE/RegisterHit']:FireServer(_Head, u17, {}, tostring(game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                    cloneref(u4):FireServer(string.gsub('RE/RegisterHit', '.', function(p31)
                        return string.char(bit32.bxor(string.byte(p31), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                    end), bit32.bxor(u5 + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), _Head, u17)
                end
            end)
        end
    end
end)

local DanhNhanhBuCu36 = {}
local HacNoCu = {}
local BuCuAnhKo = {}

--36

local B1 = {}
local B2 = {}
local B3 = {}
local B4 = {}
local B5 = {}
local B6 = {}
local B7 = {}
--67


local X001 = game
local X002 = X001:GetService("Players")

--36





local X003 = X001:GetService("RunService")
local X004 = X001:GetService("ReplicatedStorage")

--67




local X005 = X001:GetService("Workspace")
local X006 = X002.LocalPlayer

--36

local X007 = X006.Character or X006.CharacterAdded:Wait()
local function DanhNhanhBuCu36_Wait(a, b)

--67

    local s, r = pcall(function()
        return a:WaitForChild(b)
    end)
    return r
end

--36

local X008 = DanhNhanhBuCu36_Wait(X005, "Enemies")
local X009 = DanhNhanhBuCu36_Wait(X005, "Characters")

--67

local X010 = DanhNhanhBuCu36_Wait(X004, "Modules")
local X011 = DanhNhanhBuCu36_Wait(X010, "Net")

--36

DanhNhanhBuCu36.Rate = 0.000000002
DanhNhanhBuCu36.Enabled = true

--67

function DanhNhanhBuCu36.CoreCheck(a)
    local h = a:FindFirstChild("Humanoid")
    if h and h.Health > 0 then
        return true
    end

--36

    return false
end

function DanhNhanhBuCu36.PositionScan(ch, folder)

--67

    local p = ch:GetPivot().Position
    local t = {}
    local l = folder:GetChildren()
    for i = 1, #l do
        local m = l[i]
        local h1 = m:FindFirstChild("Humanoid")

--36

        local h2 = m:FindFirstChild("HumanoidRootPart")
        if h1 and h2 and h1.Health > 0 then
            local d = (h2.Position - p).Magnitude

--67

            if d <= 60 then
                t[#t+1] = m
            end
        end
    end
    return t
end

--36

function DanhNhanhBuCu36.HeadExtract(list)
    local result = {}
    local c = #list

--67

    for i = 1, c do
        local v = list[i]
        local h = v:FindFirstChild("Head") or v.PrimaryPart
        if h then
            result[#result+1] = {v, h}
        end
    end
    return result
end

--36

function DanhNhanhBuCu36.CollectAll(ch)
    local a = DanhNhanhBuCu36.PositionScan(ch, X008)
    local b = DanhNhanhBuCu36.PositionScan(ch, X009)

--67

    local final = {}
    for i=1,#a do final[#final+1] = a[i] end
    for i=1,#b do final[#final+1] = b[i] end
    return final
end

--36

function DanhNhanhBuCu36.FastCore()
    local c = X006.Character
    if not c then return end

--67

    local tool = c:FindFirstChildOfClass("Tool")
    if not tool then return end

    local mobs = DanhNhanhBuCu36.CollectAll(c)
    if #mobs < 1 then return end

--36

    local parts = DanhNhanhBuCu36.HeadExtract(mobs)
    if #parts < 1 then return end

    local A = X011["RE/RegisterAttack"]
    local B = X011["RE/RegisterHit"]

--67

    A:FireServer(DanhNhanhBuCu36.Rate)
    local head = parts[1][2]
    B:FireServer(head, parts)
end

--36

local REMOTE_TARGET
local REMOTE_ID

--67

local function HacNoCu_Init()
    local listA = {
        X004.Util,
        X004.Common,
        X004.Remotes,

--36

        X004.Assets,
        X004.FX
    }

    for _, c in next, listA do
        local kids = c:GetChildren()

--67

        for _, n in next, kids do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                REMOTE_TARGET = n
                REMOTE_ID = n:GetAttribute("Id")
            end
        end

--36

        c.ChildAdded:Connect(function(n)
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                REMOTE_TARGET = n
                REMOTE_ID = n:GetAttribute("Id")
            end
        end)
    end
end

--67

HacNoCu_Init()

function HacNoCu.Execute()
    local ch = X006.Character
    if not ch then return end

--36

    local HRP = ch:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    local gather = {}

    local function Q(folder)

--67

        local l = folder:GetChildren()
        for i=1,#l do
            local mob = l[i]
            local hm = mob:FindFirstChild("Humanoid")

--36

            local hr = mob:FindFirstChild("HumanoidRootPart")
            if hm and hr and hm.Health > 0 and mob ~= ch then
                local dist = (hr.Position - HRP.Position).Magnitude

--67

                if dist <= 60 then
                    local kids = mob:GetChildren()
                    for _, k in ipairs(kids) do
                        if k:IsA("BasePart") then
                            gather[#gather+1] = {mob, k}
                        end
                    end
                end
            end
        end
    end

--36

    Q(X008)
    Q(X009)

    local tool = ch:FindFirstChildOfClass("Tool")

--67

    if #gather > 0 and tool and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
        
        local seed = X010.Net.seed:InvokeServer()





--36







        local R1 = X011["RE/RegisterAttack"]
        local R2 = X011["RE/RegisterHit"]
        
        R1:FireServer()

--67










        local head = gather[1][1]:FindFirstChild("Head")
        if not head then return end

        R2:FireServer(head, gather, {})







--36







        if REMOTE_TARGET then
            local code = "RE/RegisterHit"
            local t = math.floor(X005:GetServerTimeNow()/10%10)+1








--67








            local encoded = string.gsub(code, ".", function(s)
                return string.char(bit32.bxor(string.byte(s), t))
            end)

            local finalid = bit32.bxor(REMOTE_ID + 909090, seed * 2)








--36







            cloneref(REMOTE_TARGET):FireServer(
                encoded,
                finalid,
                head,
                gather
            )
        end
    end
end









--67











local function BuCuAnhKo_DisableCam()
    local cam = require(X004.Util.CameraShaker)
    cam:Stop()
end







--36






local function BuCuAnhKo_StartLoops()
    task.spawn(function()
        while task.wait(DanhNhanhBuCu36.Rate) do
            DanhNhanhBuCu36.FastCore()
        end
    end)








--67







    X003.Heartbeat:Connect(function()
        pcall(HacNoCu.Execute)
    end)
end








--36








function BuCuAnhKo.Start()
    BuCuAnhKo_DisableCam()
    BuCuAnhKo_StartLoops()
end






--67







BuCuAnhKo.Start()

local Z001 = {}
local Z002 = {}




--36






local Z003 = {}
local Z004 = {}
local Z005 = {}

local function ExtraPad(a)



--67





    return tostring(a) .. tostring(a) .. tostring(a)
end

Z001.a = ExtraPad("d")
Z002.b = ExtraPad("x")




--36




Z003.c = ExtraPad("o")
Z004.d = ExtraPad("k")
Z005.e = ExtraPad("p")

local Accumulate = 0



--67




for i=1,1000 do
    Accumulate = Accumulate + i
end

local Fake = {}
for i=1,250 do

--36





    Fake[i] = i * 3
end

local function Empty(n)
    local s = ""
    for i=1, n do

--67





        s = s .. string.char((i % 26) + 97)
    end
    return s
end






local junk = Empty(5000)

--36





local junk2 = Empty(3000)
local junk3 = Empty(2000)

loadstring(game:HttpGet("https://xhider.xyz/raw/Zylos/Fastattack5.lua"))()
local function GetBladeHits()
    local targets = {}
    local function GetDistance(v)
        return (v.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    end
    
    for _, part in pairs({game.Workspace.Enemies, game.Workspace.Characters}) do
        for _, v in pairs(part:GetChildren()) do
            if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Head") and v:FindFirstChild("Humanoid") then
                if GetDistance(v.HumanoidRootPart) < 60 then
                    table.insert(targets, v)
                end
            end
        end
    end

    return targets
end

local function AttackAll()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local equippedWeapon = character:FindFirstChild("EquippedWeapon")
    if not equippedWeapon then return end


    local enemies = GetBladeHits()
    if #enemies > 0 then
        local netModule = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
        netModule:WaitForChild("RE/RegisterAttack"):FireServer(-math.huge)
        
        local args = {nil, {}}
        for i, v in pairs(enemies) do
            if not args[1] then
                args[1] = v.Head
            end
            args[2][i] = {v, v.HumanoidRootPart}
        end
        
        netModule:WaitForChild("RE/RegisterHit"):FireServer(unpack(args))
    end
end

spawn(function()
    while task.wait() do AttackAll() end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
local GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")

local Config = {
    AttackDistance = 65,
    AttackMobs = true,
    AttackPlayers = true,
    AttackCooldown = 0.2,
    ComboResetTime = 0.3,
    MaxCombo = 4,
    HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
    AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        EnemyRootPart = nil,
        Connections = {},
        Overheat = {Dragonstorm = {MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 350, Shooting = false}},
        ShootsPerTarget = {["Dual Flintlock"] = 2},
        SpecialShoots = {["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat"}
    }, FastAttack)
    
    pcall(function()
        self.CombatFlags = require(Modules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction = getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)
    
    return self
end

function FastAttack:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end

function FastAttack:GetBladeHits(Character, Distance)
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or Config.AttackDistance
    
    local function ProcessTargets(Folder, CanAttack)
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local BasePart = Enemy:FindFirstChild(Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]) or Enemy:FindFirstChild("HumanoidRootPart")
                if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                    if not self.EnemyRootPart then
                        self.EnemyRootPart = BasePart
                    else
                        table.insert(BladeHits, {Enemy, BasePart})
                    end
                end
            end
        end
    end
    
    if Config.AttackMobs then ProcessTargets(Workspace.Enemies) end
    if Config.AttackPlayers then ProcessTargets(Workspace.Characters, true) end
    
    return BladeHits
end

function FastAttack:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    
    for _, Hit in ipairs(BladeHits) do
        local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Magnitude < MinDistance then
            MinDistance = Magnitude
            Closest = Hit[2]
        end
    end
    return Closest
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
    local Character = Player.Character
    if not self:IsEntityAlive(Character) then return end
    
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        GunValidator:FireServer(self:GetValidator2())
        
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end

function FastAttack:GetValidator2()
    local v1 = getupvalue(self.ShootFunction, 15)
    local v2 = getupvalue(self.ShootFunction, 13)
    local v3 = getupvalue(self.ShootFunction, 16)
    local v4 = getupvalue(self.ShootFunction, 17)
    local v5 = getupvalue(self.ShootFunction, 14)
    local v6 = getupvalue(self.ShootFunction, 12)
    local v7 = getupvalue(self.ShootFunction, 18)
    
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    
    return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    
    if self.EnemyRootPart then
        RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local Targets = self:GetBladeHits(Character)
    if not Targets[1] then return end
    
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end

function FastAttack:Attack()
    if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
    local Character = Player.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    
    local Humanoid = Character.Humanoid
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end
    
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
    
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then
            self:ShootInTarget(Target.Position)
        end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end

local AttackInstance = FastAttack.new()
table.insert(AttackInstance.Connections, RunService.Stepped:Connect(function()
    AttackInstance:Attack()
end))

for _, v in pairs(getgc(true)) do
    if typeof(v) == "function" and iscclosure(v) then
        local name = debug.getinfo(v).name
        if name == "Attack" or name == "attack" or name == "RegisterHit" then
            hookfunction(v, function(...)
                AttackInstance:Attack()
                return v(...)
            end)
        end
    end
end
---Fast 2 ---
local Modules = game.ReplicatedStorage.Modules
local Net = Modules.Net
local Register_Hit, Register_Attack = Net:WaitForChild("RE/RegisterHit"), Net:WaitForChild("RE/RegisterAttack")
local Funcs = {}
function GetAllBladeHits()
    bladehits = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 
        and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end
function Getplayerhit()
    bladehits = {}
    for _, v in pairs(workspace.Characters:GetChildren()) do
        if v.Name ~= game.Players.LocalPlayer.Name and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 
        and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end
function Funcs:Attack()
    local bladehits = {}
    for r,v in pairs(GetAllBladeHits()) do
        table.insert(bladehits, v)
    end
    for r,v in pairs(Getplayerhit()) do
        table.insert(bladehits, v)
    end
    if #bladehits == 0 then return end
    local args = {
        [1] = nil;
        [2] = {},
        [4] = "078da341"
    }
    for r, v in pairs(bladehits) do
        Register_Attack:FireServer(0)
        if not args[1] then
            args[1] = v.Head
        end
        args[2][r] = {
            [1] = v,
            [2] = v.HumanoidRootPart
        }
    end
    Register_Hit:FireServer(unpack(args))
end
