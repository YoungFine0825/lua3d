---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/16 16:04
---固定管线渲染器

local luaMath = math
local luaPrint = print
local luaTable = table

local vec2 = vector2
local vec3 = vector3
local vec4 = vector4
local mat4x4 = matrix4x4

---@class Renderer
local Renderer = declareClass("Renderer")

function Renderer:ctor()
    self.pixelBufferWidth = 0

    self.pixelBufferHeight = 0

    self.pixelAspect = 1

    self.pixelBuffer = {}

    self.depthBuffer = {}

    ---@type VertexObject
    self.vertexObject = nil

    self.viewMatrix = mat4x4.identity()

    self.projectionMatrix = mat4x4.identity()

    ---@type matrix4x4
    self.screenMatrix = mat4x4.identity()

    ---@type Shader
    self.shader = nil

    ---@type boolean
    self.canDrawing = false

    ---@type boolean
    self.enabledAlphaBlend = true

    ---@type boolean
    self.enabledDepthWrite = true

    ---@type number
    self.drawnTriangleCnt = 0

    ---@type number
    self.drawnPixelCnt = 0
end

---@public
function Renderer:Init(pixelBufferWid,pixelBufferHei)
    self:SetPixelDimension(pixelBufferWid,pixelBufferHei)
    for w = 0,pixelBufferWid - 1 do
        self.pixelBuffer[w] = {}
        self.depthBuffer[w] = {}
        for h = 0,pixelBufferHei - 1 do
            self.pixelBuffer[w][h] = {0,0,0}
            self.depthBuffer[w][h] = 0
        end
    end
end

function Renderer:UnInit()

end

---@public
function Renderer:SetPixelDimension(width,height)
    self.pixelBufferWidth = width
    self.pixelBufferHeight = height
    self.pixelAspect = width / height
    self.screenMatrix = mat4x4.new(
            width / 2,0,0,width/2,
            0,height / 2 * -1,0,height / 2,
            0,0,0,0,
            0,0,0,0
    )
end
---@public
function Renderer:SetViewMatrix(viewMatrix)
    self.viewMatrix = viewMatrix
end

---@public
function Renderer:SetProjectionMatrix(projectionMatrix)
    self.projectionMatrix = projectionMatrix
end

---@public
function Renderer:BindVertexObject(vertexObject)
    self.vertexObject = vertexObject
end

---@public
---@param shader Shader
function Renderer:BindShader(shader)
    self.shader = shader
end

---@public
---@param color Color
function Renderer:ClearPixelBuffer(color)
    for x = 0,self.pixelBufferWidth - 1 do
        for y = 0,self.pixelBufferHeight - 1 do
            local p = self.pixelBuffer[x][y]
            p[1] = color.r
            p[2] = color.g
            p[3] = color.b
            self.depthBuffer[x][y] = 0
        end
    end
end

---@private
function Renderer:WritePixel(x,y,r,g,b)
    if not self.pixelBuffer[x] then
        return
    end
    local pixel = self.pixelBuffer[x][y]
    if pixel then
        pixel[1] = luaMath.max(0,math.min(1,r))
        pixel[2] = luaMath.max(0,math.min(1,g))
        pixel[3] = luaMath.max(0,math.min(1,b))
    end
end

---@private
function Renderer:WriteDethBuffer(x,y,depth)
    self.depthBuffer[x][y] = depth
end

---@public 是否开启alpha融合
---@param enable boolean
function Renderer:EnableAlphaBlend(enable)
    self.enabledAlphaBlend = enable
end

---@public 是否开启深度写入
---@param enable boolean
function Renderer:EnableDepthWrite(enable)
    self.enabledDepthWrite = enable
end

---@public
function Renderer:Draw()
    self.canDrawing = self.vertexObject ~= nil and self.shader ~= nil
    if not  self.canDrawing then
        return
    end
    --
    if self.shader then
        --渲染前，传入一些shader需要的数据
        self.shader:SetMVPMatrix(self.projectionMatrix * self.viewMatrix)
        self.shader:SetVertexObject(self.vertexObject)
        --让Shader根据需求设置渲染状态
        self.shader:SetRenderState(self)
    end
    --
    local indicesData = self.vertexObject.indicesData
    local viewSpaceVertices = {}
    local visableVertices = {}
    local visableTriangles = {}
    --
    --将所有顶点转换到观察空间
    for vertexIdx = 1,self.vertexObject.verticesNumber do
        local point = self.vertexObject:GetVertexData(1,vertexIdx)
        local vertex = vec4.new(point[1],point[2],point[3],1)
        viewSpaceVertices[vertexIdx] = self.viewMatrix * vertex
    end
    --在观察空间中，剔除背面的三角形
    for triIdx = 0,self.vertexObject.trianglesNumber - 1 do
        local startIdx = triIdx * 3
        local vertexIdx1 = indicesData[startIdx + 1]
        local vertexIdx2 = indicesData[startIdx + 2]
        local vertexIdx3 = indicesData[startIdx + 3]
        local p1 = viewSpaceVertices[ vertexIdx1 ]
        local p2 = viewSpaceVertices[ vertexIdx2 ]
        local p3 = viewSpaceVertices[ vertexIdx3 ]
        local p12 = p2 - p1
        local p13 = p3 - p1
        --通过叉乘取三角形的法线。（我们使用的是右手坐标系)
        --p12 X p13
        local crossX = p12.y * p13.z - p12.z * p13.y
        local crossY = p12.z * p13.x - p12.x * p13.z
        local crossZ = p12.x * p13.y - p12.y * p13.x
        --通过点乘取三角形法线与三角形第一个点到原点的方向向量的夹角
        local dot = crossX * (0 - p1.x) + crossY * (0 - p1.y) + crossZ * (0 - p1.z)
        if dot > 0 then--夹角小于于90度，表示该三角形面向视点，需要渲染出来
            visableTriangles[#visableTriangles + 1] = triIdx
            visableVertices[vertexIdx1] = 1
            visableVertices[vertexIdx2] = 1
            visableVertices[vertexIdx3] = 1
        end
    end
    --执行顶点着色器，着色器应当返回顶点的裁剪空间坐标
    local vertexShaderOutputList = {}
    for vertexIdx in pairs(visableVertices) do
        self.shader:SetCurVertexIndex(vertexIdx)
        ---@type VertexShaderOutput 顶点着色器返回的结构中必须包含clipPos字段
        vertexShaderOutputList[vertexIdx] = self.shader:VertexShader()
    end
    --剔除完全位于剪裁空间外的三角形
    local drawableTriangles = {}
    local drawableTriangleCnt = 0
    local fragmentsCache = {}
    for i = #visableTriangles,1,-1 do
        local startIdx = visableTriangles[i] * 3
        local vertex1 = indicesData[startIdx + 1]
        local vertex2 = indicesData[startIdx + 2]
        local vertex3 = indicesData[startIdx + 3]
        local p1 = vertexShaderOutputList[ vertex1 ]
        local p2 = vertexShaderOutputList[ vertex2 ]
        local p3 = vertexShaderOutputList[ vertex3 ]
        if not self:IsClipTri(p1.clipPos,p2.clipPos,p3.clipPos) then
            drawableTriangleCnt = drawableTriangleCnt + 1
            drawableTriangles[drawableTriangleCnt] = visableTriangles[i]
            if not fragmentsCache[vertex1] then fragmentsCache[vertex1] = self:GenFragmentInput(p1) end
            if not fragmentsCache[vertex2] then fragmentsCache[vertex2] = self:GenFragmentInput(p2) end
            if not fragmentsCache[vertex3] then fragmentsCache[vertex3] = self:GenFragmentInput(p3) end
        end
    end
    -----光栅化三角形-----
    local CalcuSignedTriangleArea = function(triP1,triP2,pixelX,pixelY)
        return (triP1.y - triP2.y) * pixelX + (triP2.x - triP1.x) * pixelY + triP1.x * triP2.y - triP1.y * triP2.x
    end
    local pixelCnt = 0
    local fragment = {}
    for i = 1,drawableTriangleCnt do
        local startIdx = drawableTriangles[i] * 3
        local vertexIdx1 = indicesData[startIdx + 1]
        local vertexIdx2 = indicesData[startIdx + 2]
        local vertexIdx3 = indicesData[startIdx + 3]
        local frag1 = fragmentsCache[vertexIdx1]
        local frag2 = fragmentsCache[vertexIdx2]
        local frag3 = fragmentsCache[vertexIdx3]
        --
        if frag1 and frag2 and frag3 then
            local p1 = frag1.screenPos
            local p2 = frag2.screenPos
            local p3 = frag3.screenPos
            local triArea1 = CalcuSignedTriangleArea(p2,p3, p1.x,p1.y)
            local triArea2 = CalcuSignedTriangleArea(p3,p1, p2.x,p2.y)
            local triArea3 = CalcuSignedTriangleArea(p1,p2, p3.x,p3.y)
            local minX,maxX,minY,maxY = self:CalcuTriangleBound(p1,p2,p3)
            for y = minY,maxY do
                for x = minX,maxX do
                    --求像素在屏幕空间中的重心坐标
                    local bcScreenX = CalcuSignedTriangleArea(p2,p3,x,y) / triArea1
                    local bcScreenY = CalcuSignedTriangleArea(p3,p1,x,y) / triArea2
                    local bcScreenZ = CalcuSignedTriangleArea(p1,p2,x,y) / triArea3
                    if bcScreenX >= 0 and bcScreenY >= 0 and bcScreenZ >= 0 then
                        --使用重心坐标对三角形三个（观察空间下）顶点的w分量的倒数进行差值得出该像素的深度。
                        --1/w依然是线性的，能确保正确透视关系，同时取值范围是-1~1可以直接作为颜色保存。
                        local fragmentDepth = 1 - (bcScreenX * frag1.rhw + bcScreenY * frag2.rhw + bcScreenZ * frag3.rhw)
                        local depthBuffer = self.depthBuffer[x][y]
                        --先进行深度测试（深度值越大表示越接近视点）
                        if depthBuffer == 0 or fragmentDepth < depthBuffer then
                            --写入深度值
                            if self.enabledDepthWrite then
                                self.depthBuffer[x][y] = fragmentDepth
                            end
                            --将像素的重心坐标(屏幕空间)转换到观察空间中
                            local bcView = vec3.new(bcScreenX / frag1.w,bcScreenY / frag2.w,bcScreenZ / frag3.w)
                            bcView = bcView / (bcView.x + bcView.y + bcView.z)
                            --使用裁剪空间重心坐标进行片元差值
                            for k in pairs(frag1) do
                                fragment[k] = frag1[k] * bcView.x + frag2[k] * bcView.y + frag3[k] * bcView.z
                            end
                            --执行片元着色器
                            local dstColorR,dstColorG,dstColorB,dstColorA = self.shader:FragmentShader(fragment)
                            --执行Alpha融合
                            local alphaFactor = self.enabledAlphaBlend and dstColorA or 1
                            local srcColor = self.pixelBuffer[x][y]
                            local finalR = srcColor[1] * (1 - alphaFactor) + dstColorR * alphaFactor
                            local finalG = srcColor[2] * (1 - alphaFactor) + dstColorG * alphaFactor
                            local finalB = srcColor[3] * (1 - alphaFactor) + dstColorB * alphaFactor
                            --把最终颜色写入像素缓存
                            self:WritePixel(x,y,finalR,finalG,finalB)
                            --
                            pixelCnt = pixelCnt + 1
                        end
                        --
                    end
                end
            end
        end
    end
    self.drawnPixelCnt = pixelCnt
    self.drawnTriangleCnt = drawableTriangleCnt
end

---@private 三角裁剪  根据据三 角形三个顶点是否都在裁剪空 间之外，决定三角形是否应该被裁减掉
---@param p1 vector4
---@param p2 vector4
---@param p3 vector4
function Renderer:IsClipTri(p1,p2,p3)
    local w = p1.w
    local negW = w * -1
    local isP1Visable = (p1.x <= w and p1.x >= negW) and (p1.y <= w and p1.y >= negW)and (p1.z <= w and p1.z >= negW)
    w = p2.w
    negW = w * -1
    local isP2Visable = (p2.x <= w and p2.x >= negW) and (p2.y <= w and p2.y >= negW)and (p2.z <= w and p2.z >= negW)
    w = p3.w
    negW = w * -1
    local isP3Visable = (p3.x <= w and p3.x >= negW) and (p3.y <= w and p3.y >= negW)and (p3.z <= w and p3.z >= negW)
    return not isP1Visable and not isP2Visable and not isP3Visable
end


---@private
---@param input VertexShaderOutput
---@return FragmentShaderInput
function Renderer:GenFragmentInput(input)
    ---@type FragmentShaderInput
    local fragmentShaderInput = {}
    --local ve3One = vec3.one()
    --
    for k,v in pairs(input) do
        fragmentShaderInput[k] = v
    end
    local clipPos = input.clipPos
    local w = (clipPos.w ~= 0 and clipPos.w or 1)
    --裁剪空间坐标转为齐次空间坐标
    local canonicalPos = vec3.new(clipPos.x / w,clipPos.y / w,clipPos.z / w)
    --变换到屏幕坐标
    local screenX,screenY = mat4x4.mulXYZW(self.screenMatrix,canonicalPos.x,canonicalPos.y,0,1)
    fragmentShaderInput.screenPos = vec2.new(luaMath.floor(screenX) + 0.5,luaMath.floor(screenY) + 0.5)
    fragmentShaderInput.w = w
    fragmentShaderInput.rhw = 1 / w
    return fragmentShaderInput
end

---@private 计算2d空间三角形轴对称包围盒
function Renderer:CalcuTriangleBound(p1,p2,p3)
    local minX = 0
    local maxX = 0
    local minY = 0
    local maxY = 0
    local Math = luaMath
    --
    minX = Math.min(minX,p1.x)
    maxX = Math.max(maxX,p1.x)
    minY = Math.min(minY,p1.y)
    maxY = Math.max(maxY,p1.y)
    --
    minX = Math.min(minX,p2.x)
    maxX = Math.max(maxX,p2.x)
    minY = Math.min(minY,p2.y)
    maxY = Math.max(maxY,p2.y)
    --
    minX = Math.min(minX,p3.x)
    maxX = Math.max(maxX,p3.x)
    minY = Math.min(minY,p3.y)
    maxY = Math.max(maxY,p3.y)
    return luaMath.max(luaMath.floor(minX),0),
    luaMath.min( luaMath.ceil(maxX), self.pixelBufferWidth - 1),
    luaMath.max( luaMath.floor(minY), 0),
    luaMath.min( luaMath.ceil(maxY),self.pixelBufferHeight - 1)
end

---@public
function Renderer:DrawLine(x0,y0,x1,y1)
    local swap = function(a,b)
        local t = a
        a = b
        b = t
        return a,b
    end
    local steep = luaMath.abs(y1 - y0) > luaMath.abs(x1 - x0)
    if steep then
        x0,y0 = swap(x0,y0)
        x1,y1 = swap(x1,y1)
    end
    if x0 > x1 then
        x0,x1 = swap(x0,x1)
        y0,y1 = swap(y0,y1)
    end
    local deltax = x1 - x0
    local deltay = luaMath.abs(y1 - y0)
    local error = 0
    local slope = deltay / deltax
    local ystep = 0
    local y = y0
    if y0 < y1 then ystep = 1 else ystep = -1 end
    for x = x0,x1 do
        if steep then
            self:WritePixel(y,x,1,0,0)
        else
            self:WritePixel(x,y,1,0,0)
        end
        error = error + slope
        if error >= 0.5 then
            y = y + ystep
            error = error - 1
        end
    end
end

return Renderer