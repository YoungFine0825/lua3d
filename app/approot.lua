---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/21 18:03
---

require("app/const")
require("app/classlib")
require("app/mathlib")
require("app/render")

require("app/shadertest")
require("app/vertexobjecthelper")

--
local bgColor = Color.new(59 / 255,1,1,1)
local winWid = SCREEN_WIDTH
local winHei = SCREEN_HEIGHT

---@type ShaderTest
local shader = classLib.ShaderTest.new()

local near = 0.1
local far = 10
local fov = 60
local aspect = winWid / winHei


local modelTrans = matrix4x4.identity()
local modelRotate = matrix4x4.identity()
local modelYaw = 0

---@class AppRoot
---@field renderer Renderer
---@field textureMgr TextureManager
local AppRoot = declareClass("AppRoot")

function AppRoot:ctor()
    ---@type Renderer
    self.renderer = classLib.Renderer.new()
    ---@type TextureManager
    self.textureMgr = classLib.TextureManager.new()
    ---
    self.deltaTime = 0
end

---@public
function AppRoot:Init()
    self.renderer:Init(PIXEL_WIDTH,PIXEL_HEIGHT)
    --
    self.textureMgr:Init()
end

---@public
function AppRoot:Quit()

end

---@public
function AppRoot:OnLoad()
    --加载ply格式模型数据
    ---@type VertexObject
    local plyModel = VertexObjectHelper.LoadFromPLY('res/tangdao.ply')
    --加载模型纹理
    local texId,texData = self.textureMgr:LoadTexture('res/tangdao.png')
    --绑定顶点数据对象
    self.renderer:BindVertexObject(plyModel)
    --设置投影矩阵(这里用的是透视投影)
    local projectionMat = matrix4x4.perspective(math.rad(fov),aspect,near,far)
    self.renderer:SetProjectionMatrix(projectionMat)
    --设置Shader光照参数
    shader:SetVector3('lightDir',vector3.new(-1,-1,-1))
    shader:SetColor('lightColor',Color.new(0.97,0.9,0.73,1))
    shader:SetNumber('lightIntensity',0.7)
    shader:SetVector3('viewPoint',vector3.new(0,0,0))
    --
    shader:SetColor('specularColor',Color.white)
    shader:SetNumber('gloss',40)
    --设置纹理
    shader:SetTexture2d('albedo',texData)
    --绑定Shader对象
    self.renderer:BindShader(shader)
    --
end

---@public
function AppRoot:OnUpdate(dt)
    self.deltaTime = self.deltaTime + dt
    --
    modelTrans[2][4] = -1.5--y轴位移
    modelTrans[3][4] = -1--z轴位移
    ---绕Y轴旋转矩阵
    modelYaw = modelYaw + 10 * dt
    local angleInRad = math.rad(modelYaw)
    modelRotate[1][1] = math.cos(angleInRad)
    modelRotate[3][1] = math.sin(angleInRad)
    modelRotate[1][3] = math.sin(angleInRad) * -1
    modelRotate[3][3] = math.cos(angleInRad)
    --设置观察空间变换矩阵（即某个点从世界空间变换到摄像机局部空间的矩阵）
    --虽然SetViewMatrix方法是设置的相机的变换矩阵，但我们让相机始终未位于原点，并朝向-z方向(我们使用的是右手Y-up坐标系)。
    --因此，所谓观察空间变换矩阵其实就是模型的世界空间矩阵。
    self.renderer:SetViewMatrix(modelTrans * modelRotate)
    --为了得到正确的光照效果，需要在shader中手动对于模型的法线进行旋转。
    --如果不旋转法线，那么最终渲染呈现出来的效果就是摄像机围绕模型旋转。
    shader:SetMatrix4x4('normalRotateMat',modelRotate)
    --
end

---@public
function AppRoot:RenderOneFrame()
    --
    self.renderer:ClearPixelBuffer(bgColor)
    --
    self.renderer:Draw()
    --
end

---@public
function AppRoot:OuputFrame()
    local pixelBufferW = self.renderer.pixelBufferWidth
    local pixelBufferH = self.renderer.pixelBufferHeight
    local pW = winWid / pixelBufferW
    local pH = winHei / pixelBufferH
    local pixels = self.renderer.pixelBuffer
    --
    local loveGraphics = love.graphics
    loveGraphics.setPointSize(pW + 0.5)
    for x = 0,pixelBufferW - 1 do
        for y = 0,pixelBufferH - 1 do
            local p = pixels[x][y]
            loveGraphics.setColor(p[1],p[2],p[3],1)
            loveGraphics.points(x * pW + pW / 2 ,y * pH + pH / 2  )
        end
    end
end

return AppRoot