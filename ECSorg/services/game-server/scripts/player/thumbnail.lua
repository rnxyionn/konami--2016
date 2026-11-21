local jobId = "InsertJobIdHere";
local userId = 65789275746246;
local mode = "R6";
local baseURL = "http://economy-simulator.org";
local uploadURL = "UPLOAD_URL_HERE";
local ScriptContext = game:GetService("ScriptContext");
local Lighting = game:GetService('Lighting');
local RunService = game:GetService('RunService');
local ContentProvider = game:GetService('ContentProvider');
local HttpService = game:GetService("HttpService");
local ThumbnailGenerator = game:GetService('ThumbnailGenerator');
local Players = game:GetService("Players");
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
game:GetService('ThumbnailGenerator').GraphicsMode = 2;
HttpService.HttpEnabled = true;
ScriptContext.ScriptsDisabled = true
Lighting.Outlines = false
ContentProvider:SetBaseUrl("RCC_CONTENT_BASE_URL")
game:GetService("InsertService"):SetAssetUrl("RCC_INSERT_ASSET_URL")
local Insert = game:GetService("InsertService")
Insert:SetAssetVersionUrl(baseURL .. "/Asset/?assetversionid=%d")

local function rewriteContentUrl(url)
    if type(url) ~= "string" then
        return url
    end
    local assetId = string.match(url, "[?&]id=(%d+)")
    if assetId then
        return "RCC_ASSET_PREFIX" .. assetId
    end
    return url
end

local function redirectAssetContent(item)
    if item:IsA("SpecialMesh") then
        item.MeshId = rewriteContentUrl(item.MeshId)
        item.TextureId = rewriteContentUrl(item.TextureId)
    elseif item:IsA("MeshPart") then
        item.MeshId = rewriteContentUrl(item.MeshId)
    elseif item:IsA("Decal") or item:IsA("Texture") then
        item.Texture = rewriteContentUrl(item.Texture)
    elseif item:IsA("Shirt") then
        item.ShirtTemplate = rewriteContentUrl(item.ShirtTemplate)
    elseif item:IsA("Pants") then
        item.PantsTemplate = rewriteContentUrl(item.PantsTemplate)
    elseif item:IsA("ShirtGraphic") then
        item.Graphic = rewriteContentUrl(item.Graphic)
    end

    for _, child in pairs(item:GetChildren()) do
        redirectAssetContent(child)
    end
end

local function applyMesh(Player, children, limb)
    local ok, msg = pcall(function() 
        local specialMesh = children[1]
        local head = Player.Character[limb]
        local m = head:FindFirstChild("Mesh")
        if not m then
            m = Instance.new("SpecialMesh")
            m.Parent = head
        end
        -- set
        m.Scale = specialMesh.Scale
        m.TextureId = specialMesh.TextureId
        m.MeshId = specialMesh.MeshId
        m.MeshType = specialMesh.MeshType
        m.VertexColor = specialMesh.VertexColor
    end)
    if not ok then
        print("error loading mesh", msg)
    end
end

local function applyPackage(Player, children)
    local ok, msg = pcall(function() 
        print("applyPackage children", children, #children)
        for _, asset in pairs(children) do
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Child package",asset)
            asset.Parent = Player.Character
        end
    end)
    if not ok then
        print("error loading package", msg)
    end
end

local function findFirstChildOfType(model, className)
    for _, child in pairs(model:GetChildren()) do
        if child:IsA(className) then
            return child
        end
        local found = findFirstChildOfType(child, className)
        if found then
            return found
        end
    end
end

local function findFirstMatchingAttachment(model, name)
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Attachment") and child.Name == name then
            return child
        elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then
            local found = findFirstMatchingAttachment(child, name)
            if found then
                return found
            end
        end
    end
end

local function buildWeld(part0, part1, c0, c1, name)
    local weld = Instance.new("Weld")
    weld.C0 = c0
    weld.C1 = c1
    weld.Part0 = part0
    weld.Part1 = part1
    weld.Name = name
    weld.Parent = part0
end

local function addAssetToCharacter(Player, item, assetType)
    local character = Player.Character
    local handle = item:FindFirstChild("Handle")
    local attachment = handle and findFirstChildOfType(handle, "Attachment")
    local matchingAttachment = attachment and findFirstMatchingAttachment(character, attachment.Name)
    item.Parent = character

    if not handle then
        return
    end

    handle.CanCollide = false
    if matchingAttachment then
        local targetPart = matchingAttachment.Parent
        handle.CFrame = targetPart.CFrame * matchingAttachment.CFrame * attachment.CFrame:inverse()
        buildWeld(handle, matchingAttachment.Parent, attachment.CFrame, matchingAttachment.CFrame, "AccessoryWeld")
    elseif item:IsA("Accoutrement") or assetType == 8 or assetType == 41 or assetType == 42 then
        local head = character:FindFirstChild("Head")
        if head then
            local headAttachment = CFrame.new(0, head.Size.Y / 2, 0)
            local attachmentPoint = item:IsA("Accoutrement") and item.AttachmentPoint or CFrame.new()
            if attachment then
                handle.CFrame = head.CFrame * headAttachment * attachment.CFrame:inverse()
                buildWeld(handle, head, attachment.CFrame, headAttachment, "AccessoryWeld")
            else
                handle.CFrame = head.CFrame * headAttachment * attachmentPoint:inverse()
                buildWeld(handle, head, attachmentPoint, headAttachment, "AccessoryWeld")
            end
        end
    elseif item:IsA("Tool") then
        local rightHand = character:FindFirstChild("RightHand")
        local rightArm = character:FindFirstChild("Right Arm")
        if rightHand then
            local grip = CFrame.new(0.0108650923, -0.168664441, -0.0154389441, 1, 0, 0, 0, 0, 1, 0, -1, 0)
            buildWeld(handle, rightHand, item.Grip, grip, "RightGrip")
        elseif rightArm then
            local grip = CFrame.new(Vector3.new(0, -1, 0)) * CFrame.Angles(-math.pi * 0.5, 0, 0)
            buildWeld(handle, rightArm, item.Grip, grip, "RightGrip")
        end
    end
end

local function addLoadedItemToCharacter(Player, item, assetType)
    if assetType == 18 and item:IsA("Decal") then
        local head = Player.Character:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            if face then
                face:Destroy()
            end
            item.Name = "face"
            item.Parent = head
        end
        return
    end

    if item:IsA("Accoutrement") or item:IsA("Tool") or item:IsA("Shirt") or
        item:IsA("Pants") or item:IsA("ShirtGraphic") then
        addAssetToCharacter(Player, item, assetType)
        return
    end

    for _, child in pairs(item:GetChildren()) do
        addLoadedItemToCharacter(Player, child, assetType)
    end
end

    local function render(id)
        -- game.StarterPlayer.GameSettingsAvatarType = Enum.GameAvatarType.R15
        local Player = Players:CreateLocalPlayer(id)
        -- Player.CharacterAppearance = "http://localhost/Asset/AvatarAccoutrements.ashx?userId=1127502";
        Player:LoadCharacter()

        local av = HttpService:JSONDecode('JSON_AVATAR')

        --[[
        if av.playerAvatarType == 'R15' then
            local Character = Insert:LoadAsset(1664543044).Player
            Character.Parent = game.Workspace
            print('char len', #Character:GetChildren())
            local Humanoid = Character.Humanoid
            Player.Character = Character
            local hrp = Player.Character.HumanoidRootPart
            hrp.Anchored = true
        end
        ]]--


        -- this returns data in an identical format to https://avatar.roblox.com/v1/users/1/avatar
        -- Player.Character['Right Leg']:Destroy()
        local assetDebug = {}
        for _, asset in pairs(av.assets) do
            print('[debug] add',asset.name,'to char')
            local ok, err = pcall(function()
                local loadedAsset = Insert:LoadAsset(asset.id)
                redirectAssetContent(loadedAsset)
                local children = loadedAsset:GetChildren()
                table.insert(assetDebug, "loaded " .. asset.id .. " as " .. loadedAsset.ClassName .. " with " .. #children .. " children")

                if asset.assetType.id == 17 then
                    applyMesh(Player, children, "Head")
                end
                if asset.assetType.id == 27 or asset.assetType.id == 28 or asset.assetType.id == 29 or asset.assetType.id == 30 or asset.assetType.id == 31 then
                    applyPackage(Player, children)
                else
                    for _, item in pairs(children) do
                        table.insert(assetDebug, item.ClassName .. ":" .. item.Name .. " handle=" .. tostring(item:FindFirstChild("Handle") ~= nil))
                        print('[debug] add ',asset.name, '/', item.Name,'to char (type =',asset.assetType.id,')')
                        addLoadedItemToCharacter(Player, item, asset.assetType.id)
                    end
                end
            end)
            if not ok then
                table.insert(assetDebug, "failed " .. asset.id .. ": " .. tostring(err))
                print("[error] failed to apply avatar asset", asset.id, err)
            end
        end
        print("[debug] set body colors")
        local bc = av.bodyColors;
        local colors = {
            ['Head']      = bc.headColorId,
            ['Torso']     = bc.torsoColorId,
            ['Left Arm']  = bc.leftArmColorId,
            ['Right Arm'] = bc.rightArmColorId,
            ['Left Leg']  = bc.leftLegColorId,
            ['Right Leg'] = bc.rightLegColorId
        }

        for part, color in pairs(colors) do
            if Player.Character:FindFirstChild(part) then
                Player.Character[part].BrickColor = BrickColor.new(color)
            else
                print("[warning] could not find",part,"in player")
            end
        end

        for _, object in pairs(Player.Character:GetChildren()) do
            if object:IsA('Tool') then
                print("Player has gear, raise the right arm out.")
                Player.Character.Torso['Right Shoulder'].CurrentAngle = math.rad(90)
            end
        end

        --[[
        local guy = Player.Character
        guy.Head.Mesh:remove()
        guy.Torso:remove()
        guy['Right Arm']:remove()
        guy['Left Arm']:remove()
        guy['Right Leg']:remove()
        guy['Left Leg']:remove()
        ]]--
        
        -- local humanoid = Player.Character.Humanoid
        -- humanoid:BuildRigFromAttachments()
        print("[debug] render avatar")
        local hasCam = game.Workspace:GetChildren()[1];
        if hasCam ~= nil then
            if hasCam:FindFirstChild("ThumbnailCamera") ~= nil then
                print("has thumbnail camera")
            else
                print("Does not have thumbnail camera")
            end
        end
        local avatarEncoded = ThumbnailGenerator:Click('png', _X_RES_, _Y_RES_, true, false)
        print("[debug] avatar render over. delete character")
        Player.Character:Destroy()
        print("[debug] [player/thumbnail] send post request containing avatar")
        local ok, data = pcall(function()
            return HttpService:PostAsync(uploadURL, HttpService:JSONEncode({
                ['thumbnail'] = avatarEncoded,
                ['userId'] = userId,
                ['accessKey'] = "AccessKey",
                ['type'] = "PlayerThumbnail",
                ['jobId'] = jobId,
                ['debug'] = table.concat(assetDebug, "; "),
            }), Enum.HttpContentType.TextPlain)
        end)
        print("[debug] post over",ok,data)
    end

coroutine.wrap(function()
    local ok, data = pcall(function()
        render(1)
    end)
    print("[player/thumbnail]", ok, data);
    print("[debug] exit game");
end)()
