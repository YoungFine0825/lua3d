---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/16 17:02
---顶点对象

VertexLayoutIndex = {
    worldPos = 1,
    uv = 2,
    color = 3,
    normal = 4,
}

---@class VertexLayout
---@field offset number
---@field stride number
---@field size number

---@class VertexObject
local VertexObject = declareClass("VertexObject")

function VertexObject:ctor()

    ---@type number[]
    self.verticesData = {}

    ---@type number[]
    self.indicesData = {}

    ---@type number
    self.verticesNumber = 0

    ---@type number
    self.trianglesNumber = 0

    ---@type table<number,VertexLayout>
    self.layout = {}
end

---@public
function VertexObject:Destory()
    self.verticesData = nil
    self.indicesData = nil
    self.layout = {}
end

---@public
function VertexObject:SetVerticesData(numberArray)
    self.verticesData = numberArray
end

---@public
function VertexObject:SetVerticesNumber(number)
    self.verticesNumber = number
end

---@public
function VertexObject:SetIndicesData(numberArray)
    self.indicesData = numberArray
end

---@public
function VertexObject:SetTrianglesNumber(number)
    self.trianglesNumber = number
end

---@public
function VertexObject:SetLayout(index,stride,offset,size)
    local layout = self.layout[index]
    if not layout then
        layout = {
            offset = offset,
            stride = stride,
            size = size
        }
        self.layout[index] = layout
        return layout
    end
    layout.offset = offset
    layout.stride = stride
    layout.size = size
    return layout
end

---@public
---@return number[]
function VertexObject:GetVertexData(layoutIndex,vertexIndex)
    local layout = self.layout[layoutIndex]
    if not layout then
        return nil
    end
    local stride = math.max(vertexIndex - 1,0) * layout.stride
    local startIndex = stride + layout.offset + 1
    local endIndex = startIndex + layout.size - 1
    local ret = {}
    for i = startIndex,endIndex do
        ret[#ret + 1] = self.verticesData[i]
    end
    return ret
end

return VertexObject