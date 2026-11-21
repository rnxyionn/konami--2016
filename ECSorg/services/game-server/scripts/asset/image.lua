local jobId = "InsertJobIdHere";
local assetId = 65789275746246;
local assetType = 358843;
local mode = "R6";
local baseURL = "https://economy-simulator.org";
local goToAsset = "/asset/?id="
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
print(ContentProvider.BaseUrl)
game:GetService("InsertService"):SetAssetUrl("RCC_INSERT_ASSET_URL")
Players:SetChatFilterUrl(baseURL .. "/Game/ChatFilter.ashx")
local Insert = game:GetService("InsertService")
game:GetService("InsertService"):SetAssetUrl("RCC_INSERT_ASSET_URL")
game:GetService("InsertService"):SetAssetVersionUrl(baseURL .. "/Asset/?assetversionid=%d")

game:GetService("InsertService"):SetAssetVersionUrl(baseURL .. "/asset/?assetversionid=%d")

local function rewriteContentUrl(url)
    if type(url) ~= "string" then
        return url
    end
    local id = string.match(url, "[?&]id=(%d+)")
    return id and "RCC_ASSET_PREFIX" .. id or url
end

local function findTexture(item)
    if item:IsA("Decal") then
        return item.Texture
    elseif item:IsA("Texture") then
        return item.Texture
    end
    for _, child in pairs(item:GetChildren()) do
        local texture = findTexture(child)
        if texture then
            return texture
        end
    end
end

    local function render(id)

        print("[debug] render image - type",assetType, "id",assetId)
        local assetUrl = "RCC_ASSET_PREFIX" .. tostring(assetId);
        if assetType == 13 or assetType == 18 then
            local ok, image = pcall(function() 
                return Insert:LoadAsset(assetId)
            end)
            print("LoadAsset() pcall over - result",ok,image)
            if not ok then
                error(image)
            end
            local texture = findTexture(image)
            if not texture or texture == "" then
                error("Asset contains no usable texture")
            end
            assetUrl = rewriteContentUrl(texture)
        end

        local part = Instance.new("Part")
        part.Name = "TexturePreview"
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(4, 4, 0.2)
        part.Parent = game.Workspace

        for _, face in pairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
            local decal = Instance.new("Decal")
            decal.Face = face
            decal.Texture = assetUrl
            decal.Parent = part
        end

        local camera = Instance.new("Camera")
        camera.CFrame = CFrame.new(0, 0, 7)
        camera.Parent = game.Workspace
        game.Workspace.CurrentCamera = camera
        ThumbnailGenerator:Click('png', 1, 1, true, false)
        wait(2)
        return ThumbnailGenerator:Click('png', 420, 420, true, false)
    end

    local ok, result = pcall(function()
        return render(assetId)
    end)
    if not ok then
        print("[error] texture thumbnail render failed", result)
    end
    print("[debug] send post request containing image")
    local postOk, postResult = pcall(function()
        return HttpService:PostAsync(uploadURL, HttpService:JSONEncode({
            ['thumbnail'] = ok and result or nil,
            ['assetId'] = assetId,
            ['debug'] = ok and "" or tostring(result),
            ['accessKey'] = "AccessKey",
            ['type'] = "Image",
            ['jobId'] = jobId,
        }), Enum.HttpContentType.TextPlain)
    end)
    print("[debug] post over", postOk, postResult)
    print("[debug] exit game");
