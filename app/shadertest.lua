---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/19 9:52

local vertexLayoutIdx = VertexLayoutIndex

---@class ShaderTest : Shader
local ShaderTest = declareClass("ShaderTest",classLib.Shader)

---@public
---@param renderer Renderer
function ShaderTest:SetRenderState(renderer)
    renderer:EnableAlphaBlend(true)
end

---@private
---@return VertexShaderOutput
function ShaderTest:VertexShader()
    local worldPos = self:GetVertexDataVec3(vertexLayoutIdx.worldPos)
    local clipPos = self.mvpMatrix * worldPos
    --
    ---@type VertexShaderOutput
    local o = {
        clipPos = clipPos,
        worldPos = worldPos,
    }
    return o
end

---@private
---@param input FragmentShaderInput
---@return vector4
function ShaderTest:FragmentShader(input)
    local color = self:GetVector3('color')
    return vector4.new(color.x,color.y,color.z,0.5)
end

return ShaderTest