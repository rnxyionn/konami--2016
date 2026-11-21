local jobId = "InsertJobIdHere";
local userId = 65789275746246;
local mode = 'R6'
local baseURL = "http://economy-simulator.org";
local uploadURL = "UPLOAD_URL_HERE";

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

local function FindFirstChildWhichIsA(inst, className)
    for _, asset in pairs(inst:GetChildren()) do
        if asset.ClassName == className then
            return asset
        end
    end
    return nil
end

    local HttpService = game:GetService('HttpService')
    local ScriptContext = game:GetService('ScriptContext')
    local Lighting = game:GetService('Lighting')
    local Players = game:GetService('Players')
    local RunService = game:GetService('RunService')
    local ContentProvider = game:GetService('ContentProvider')
    local ThumbnailGenerator = game:GetService('ThumbnailGenerator')
    game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    ThumbnailGenerator.GraphicsMode = 4; -- switch to 4 (apparently noop but all roblox code has this line so...)

    HttpService.HttpEnabled = true
    ScriptContext.ScriptsDisabled = true
    Lighting.Outlines = false
    ContentProvider:SetBaseUrl("RCC_CONTENT_BASE_URL")
    game:GetService("InsertService"):SetAssetUrl("RCC_INSERT_ASSET_URL")
    game:GetService("ContentProvider"):SetBaseUrl("RCC_CONTENT_BASE_URL")
    game:GetService("Players"):SetChatFilterUrl(baseURL .. "/Game/ChatFilter.ashx")
    local Insert = game:GetService("InsertService")
    game:GetService("InsertService"):SetAssetUrl("RCC_INSERT_ASSET_URL")
    game:GetService("InsertService"):SetAssetVersionUrl(baseURL .. "/Asset/?assetversionid=%d")

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

    local function render(id)
        -- game.StarterPlayer.GameSettingsAvatarType = Enum.GameAvatarType.R15
        local Player = Players:CreateLocalPlayer(id)
        Player:LoadCharacter()
        -- this returns data in an identical format to https://avatar.roblox.com/v1/users/1/avatar
        local av = HttpService:JSONDecode('JSON_AVATAR')
        -- Player.Character['Right Leg']:Destroy()
        for _, asset in pairs(av.assets) do
            print('[debug] add',asset.name,'to char')
            local ok, err = pcall(function()
                local loadedAsset = Insert:LoadAsset(asset.id)
                redirectAssetContent(loadedAsset)
                local children = loadedAsset:GetChildren()

                if asset.assetType.id == 17 then
                    applyMesh(Player, children, "Head")
                end
                if asset.assetType.id == 27 or asset.assetType.id == 28 or asset.assetType.id == 29 or asset.assetType.id == 30 or asset.assetType.id == 31 then
                    applyPackage(Player, children)
                else
                    for _, item in pairs(children) do
                        print('[debug] add ',asset.name,'/',item.Name,'to char')
                        addLoadedItemToCharacter(Player, item, asset.assetType.id)
                    end
                end
            end)
            if not ok then
                print("[error] failed to apply avatar asset", asset.id, err)
            end
        end
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
            end
        end

        for _, object in pairs(Player.Character:GetChildren()) do
            if object:IsA('Tool') then
                object:Destroy()
                -- Player.Character.Torso['Right Shoulder'].CurrentAngle = math.pi / 2
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
        
        print('use cam')
        -- cam:Destroy()
        -- cam = Instance.new("Camera", game.Workspace)
        -- cam.CameraType = Enum.CameraType.Watch
        -- cam.CameraSubject = Player.Character.Head
        print("[debug] render avatar")
        -- Player.Character.HumanoidRootPart.Anchored = true
        -- local c = game.Workspace.CurrentCamera

        local player = Player
        local FFlagNewHeadshotLighting = false
        local FFlagOnlyCheckHeadAccessoryInHeadShot = false
        local cameraOffsetX = 0
        local cameraOffsetY = 0
        local maxHatZoom = 100
        local baseHatZoom = 30


        local maxDimension = 0

        local quadratic = true


    -- Remove gear
	for _, child in pairs(player.Character:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		elseif child:IsA("Accoutrement") then
            local handle = child:FindFirstChild("Handle")
			if handle then
				local attachment = FindFirstChildWhichIsA(handle, "Attachment")
                
                --legacy hat does not have attachment in it and should be considered when zoom out camera
				if not FFlagOnlyCheckHeadAccessoryInHeadShot or not attachment or headAttachments[attachment.Name] then
					local size = handle.Size / 2 + handle.Position - player.Character.Head.Position
					local xy = Vector2.new(size.x, size.y)
					if xy.magnitude > maxDimension then
						maxDimension = xy.magnitude
					end
				end
			end
		end
	end

	-- Setup Camera
	local maxHatOffset = 0.5 -- Maximum amount to move camera upward to accomodate large hats
    maxDimension = math.min(1, maxDimension / 3) -- Confine maxdimension to specific bounds

    if quadratic then
        maxDimension = maxDimension * maxDimension -- Zoom out on quadratic interpolation
    end

    local viewOffset     = player.Character.Head.CFrame * CFrame.new(cameraOffsetX, cameraOffsetY + maxHatOffset * maxDimension, 0.1) -- View vector offset from head

    local yAngle = -math.pi / 16
	
	local positionOffset = player.Character.Head.CFrame + (CFrame.Angles(0, yAngle, 0).lookVector.unit * 3) -- Position vector offset from head

    local camera = Instance.new("Camera", player.Character)-- Instance.new("Camera", player.Character)
    camera.Name = "ThumbnailCamera"
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CoordinateFrame = CFrame.new(positionOffset.p, viewOffset.p)
    camera.FieldOfView = baseHatZoom + (maxHatZoom - baseHatZoom) * maxDimension
    print("cam fov",camera.FieldOfView)

	workspace.CurrentCamera = camera
    
        local clickOk, avatarEncoded = pcall(function()
            return ThumbnailGenerator:Click('png', _X_RES_, _Y_RES_, true, true)
        end)
        print("[debug] headshot click result", clickOk, clickOk and #avatarEncoded or avatarEncoded)
        if not clickOk then error(avatarEncoded) end
        print("[debug] [player/headshot] send post request containing avatar")
        local uploadOk, uploadResult = pcall(function()
            return HttpService:PostAsync(uploadURL, HttpService:JSONEncode({
                ['thumbnail'] = avatarEncoded,
                ['userId'] = userId,
                ['accessKey'] = "AccessKey",
                ['type'] = "PlayerHeadshot",
                ['jobId'] = jobId,
            }), Enum.HttpContentType.TextPlain)
        end)
        print("[debug] headshot upload result", uploadOk, uploadResult)
        if not uploadOk then error(uploadResult) end
        print("[debug] post over")
    end

    local ok, data = pcall(function()
        render(userId)
    end)
    print("[player/headshot]", ok, data);

