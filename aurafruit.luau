-- // AURA FRUIT - Tự động spam tấn công khi chạy script
-- // Không cần bật/tắt, chạy là auto

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Lấy remote
local _AF_Net, _AF_RegisterAttack, _AF_RegisterHit
pcall(function()
    _AF_Net = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5)
    _AF_RegisterAttack = _AF_Net:WaitForChild("RE/RegisterAttack", 5)
    _AF_RegisterHit = _AF_Net:WaitForChild("RE/RegisterHit", 5)
end)

-- Cấu hình
local CONFIG = {
    RANGE = 10000,
    ATTACKS_PER_FRAME = 0,   -- Số lần gửi RegisterAttack mỗi frame
    HITS_PER_FRAME = 0,      -- Số lần gửi RegisterHit mỗi target mỗi frame
    FRUIT_SPAM = 8,          -- Số lần spam LeftClickRemote mỗi frame
}

-- Kiểm tra còn sống
local function isAlive(model)
    local h = model:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

-- Lấy danh sách target trong phạm vi
local function getTargets()
    local char = player.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local list = {}
    local function scan(folder)
        for _, v in pairs(folder:GetChildren()) do
            if v ~= char and v:FindFirstChild("HumanoidRootPart") and isAlive(v) then
                if (hrp.Position - v.HumanoidRootPart.Position).Magnitude <= CONFIG.RANGE then
                    table.insert(list, v)
                end
            end
        end
    end
    pcall(function() if Workspace:FindFirstChild("Enemies") then scan(Workspace.Enemies) end end)
    pcall(function() if Workspace:FindFirstChild("Characters") then scan(Workspace.Characters) end end)
    return list
end

-- Đánh thường (melee/sword)
local function attackMelee(targets)
    if not _AF_RegisterAttack or not _AF_RegisterHit then return end
    for _ = 1, CONFIG.ATTACKS_PER_FRAME do
        _AF_RegisterAttack:FireServer(0)
    end
    for _, v in ipairs(targets) do
        if v:FindFirstChild("HumanoidRootPart") then
            local args = { [1] = v.HumanoidRootPart, [2] = { {v, v.HumanoidRootPart} } }
            for _ = 1, CONFIG.HITS_PER_FRAME do
                _AF_RegisterHit:FireServer(unpack(args))
            end
        end
    end
end

-- Lấy tool trái ác quỷ
local function getFruitTool()
    local char = player.Character
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then return v end
        end
    end
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then return v end
    end
end

-- Spam trái cây (LeftClickRemote)
local function attackFruit(targets)
    local fruit = getFruitTool()
    if not fruit then return end
    local remote = fruit:FindFirstChild("LeftClickRemote")
    if not remote then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = targets[1]
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    local dir = (target.HumanoidRootPart.Position - hrp.Position).Unit
    for _ = 1, CONFIG.FRUIT_SPAM do
        remote:FireServer(dir, 1)
    end
end

-- Vòng lặp tự động (chạy ngay)
RunService.Heartbeat:Connect(function()
    -- Chỉ tránh xung đột khi đang hóa Phật (nếu có)
    if getgenv().BuddhaTransforming then return end
    local targets = getTargets()
    if #targets == 0 then return end
    attackMelee(targets)
    attackFruit(targets)
end)

print("✅ Aura Fruit script started - tự động spam tấn công")
