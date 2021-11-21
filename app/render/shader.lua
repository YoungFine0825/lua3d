---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/16 18:09

---@class VertexShaderOutput
---@field clipPos vector4
---@field worldPos vector4
---@field uv vector2
---@field color vector3
---@field normal vector3

---@class FragmentShaderInput : VertexShaderOutput
---@field screenPos vector2
---@field canonicalPos vector3


---着色器基类
---@class Shader
local Shader = declareClass("Shader")

function Shader:ctor()

    ---@type VertexObject
    self.vertexObject = nil

    ---@type number
    self.curVertexIndex = 0

    ---@type matrix4x4
    self.mvpMatrix = matrix4x4.identity()

    ---@type table<string,vector2>
    self.uniformVector2 = {}

    ---@type table<string,vector3>
    self.uniformVector3 = {}

    ---@type table<string,vector4>
    self.uniformVector4 = {}

    ---@type table<string,matrix4x4>
    self.uniformMatrix4x4 = {}

    ---@type table<string,number>
    self.uniformNumber = {}

    ---@type table<string,Color>
    self.uniformColor = {}

    ---@type table<string,Texture2d>
    self.uniformTexture2d = {}
end

---@public 渲染器状态设置
---@param renderer Renderer
function Shader:SetRenderState(renderer)

end

---@public 顶点着色器
---@return VertexShaderOutput
function Shader:VertexShader()
    return {}
end

---@public 片元着色器
---@param input FragmentShaderInput
---@return number,number,number,number r,g,b,a
function Shader:FragmentShader(input)
    return 0,0,0,1
end

---@public
---@param name string
---@param number number
function Shader:SetNumber(name,number)
    self.uniformNumber[name] = number
end

---@public
---@param name string
---@return number
function Shader:GetNumber(name)
    return self.uniformNumber[name] or 0
end

---@public
---@param name string
---@param vector3 vector3
function Shader:SetVector3(name,vector3)
    self.uniformVector3[name] = vector3
end

---@public
---@param name string
---@return vector3
function Shader:GetVector3(name)
    local ret = self.uniformVector3[name]
    if ret == nil then
        ret = vector3.zero()
    end
    return ret
end

---@public
---@param name string
---@param vector3 vector2
function Shader:SetVector2(name,vector2)
    self.uniformVector2[name] = vector2
end

---@public
---@param name string
---@return vector2
function Shader:GetVector2(name)
    local ret = self.uniformVector2[name]
    if ret == nil then
        ret = vector2.zero()
    end
    return ret
end

---@public
---@param name string
---@param vector4 vector4
function Shader:SetVector4(name,vector4)
    self.uniformVector4[name] = vector4
end

---@public
---@param name string
---@return vector4
function Shader:GetVector4(name)
    return self.uniformVector4[name] or vector4.zero()
end

---@public
---@param name string
---@param matrix4x4 matrix4x4
function Shader:SetMatrix4x4(name,matrix4x4)
    self.uniformMatrix4x4[name] = matrix4x4
end

---@public
---@param name string
---@return matrix4x4
function Shader:GetMatrix4x4(name)
    local ret = self.uniformMatrix4x4[name]
    if ret == nil then
        ret = matrix4x4.identity()
    end
    return ret
end

---@public
---@param name string
---@param color Color
function Shader:SetColor(name,color)
    self.uniformColor[name] = color
end

---@public
---@param name string
---@return Color
function Shader:GetColor(name)
    return self.uniformColor[name] or Color.black
end

---@public
function Shader:SetMVPMatrix(mvpMat)
    self.mvpMatrix = mvpMat
end

---@public
function Shader:SetVertexObject(vertexObject)
    self.vertexObject = vertexObject
end

---@public
function Shader:SetCurVertexIndex(curVertexIndex)
    self.curVertexIndex = curVertexIndex
end

---@public
function Shader:GetVertexDataVec2(layoutType)
    if not self.vertexObject then
        return vector2.zero()
    end
    local data = self.vertexObject:GetVertexData(layoutType,self.curVertexIndex)
    if not data then
        return vector2.zero()
    end
    return vector2.new(data[1],data[2])
end

---@public
function Shader:GetVertexDataVec3(layoutType)
    if not self.vertexObject then
        return vector3.zero()
    end
    local data = self.vertexObject:GetVertexData(layoutType,self.curVertexIndex)
    if not data then
        return vector3.zero()
    end
    return vector3.new(data[1],data[2],data[3])
end

---@public
function Shader:GetVertexDataVec4(layoutType)
    if not self.vertexObject then
        return vector4.zero()
    end
    local data = self.vertexObject:GetVertexData(layoutType,self.curVertexIndex)
    if not data then
        return vector4.zero()
    end
    return vector4.new(data[1],data[2],data[3],data[4])
end

---@public
---@param name string
---@param texture Texture2d
function Shader:SetTexture2d(name,texture)
    self.uniformTexture2d[name] = texture
end

---@public
---@param texName string
---@param uv vector2
---@return Color
function Shader:SampleTex2d(texName,uv)
    local texture2d = self.uniformTexture2d[texName]
    local r,g,b,a = 0,0,0,1
    if texture2d then
        local w = texture2d.width - 1
        local h = texture2d.height - 1
        local uvX = math.min(uv.x,1)
        local uvY = 1 - math.min(uv.y,1)
        r,g,b,a = texture2d.data:getPixel(w * uvX,h * uvY)
    end
    return Color.new(r,g,b,a)
end

return Shader