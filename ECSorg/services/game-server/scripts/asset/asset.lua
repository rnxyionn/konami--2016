local assetId = {1234};
local jobId = "InsertJobIdHere";
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
local Insert = game:GetService("InsertService")
Insert:SetAssetUrl("RCC_INSERT_ASSET_URL")

local function rewriteContentUrl(url)
    if type(url) ~= "string" then
        return url
    end
    local id = string.match(url, "[?&]id=(%d+)")
    return id and "RCC_ASSET_PREFIX" .. id or url
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

local function findAssetComponent(item, predicate)
    if predicate(item) then
        return item
    end
    for _, child in pairs(item:GetChildren()) do
        local found = findAssetComponent(child, predicate)
        if found then
            return found
        end
    end
end

    local function render()
        local model = Instance.new("Model");
        local assetIds = assetId
        local renderTarget
        for _, id in pairs(assetIds) do
            local asset = Insert:LoadAsset(id)
            redirectAssetContent(asset)
            for _, child in pairs(asset:GetChildren()) do
                child.Parent = model;
                local found = findAssetComponent(child, function(item)
                    return item:IsA("Accessory") or item:IsA("Accoutrement") or item:IsA("Tool") or item:IsA("Hat")
                end)
                if found then
                    renderTarget = found
                end
            end
        end
        model.Parent = game.Workspace

        if not renderTarget then
            error("Asset contains no accessory, tool, or hat to frame")
        end

        local camera = findAssetComponent(renderTarget, function(item)
            return item:IsA("Camera") and item.Name == "ThumbnailCamera"
        end)
        if camera then
            print("Has ThumbnailCamera, now using it")
        else
            camera = Instance.new("Camera")
        end
        camera.Parent = game.Workspace
        game.Workspace.CurrentCamera = camera

        print("[debug] render test asset")
        return ThumbnailGenerator:Click('png', _X_RES_, _Y_RES_, true, true)
    end

    local ok, result = pcall(function()
        return render()
    end)
    if not ok then
        print("[error] asset thumbnail render failed", result)
    end
    print("[debug] send post request containing test asset")
    local postOk, postResult = pcall(function()
        return HttpService:PostAsync(uploadURL, HttpService:JSONEncode({
            ['type'] = 'Asset',
            ['assetId'] = assetId[1],
            ['thumbnail'] = ok and result or nil,
            ['debug'] = ok and "" or tostring(result),
            ['accessKey'] = "AccessKey",
            ['jobId'] = jobId,
        }), Enum.HttpContentType.TextPlain)
    end)
    print("[debug] post over", postOk, postResult)
    print("[debug] exit asset render game");
