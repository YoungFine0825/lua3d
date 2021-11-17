---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/16 11:40
---4x4矩阵类

local setmetatable = setmetatable
local luaMath = math
local getLuaDataType = type

---@class matrix4x4
---@field m11 number
---@field m12 number
---@field m13 number
---@field m14 number
---@field m21 number
---@field m22 number
---@field m23 number
---@field m24 number
---@field m31 number
---@field m32 number
---@field m33 number
---@field m34 number
---@field m41 number
---@field m42 number
---@field m43 number
---@field m44 number
local matrix4x4 = {
    __type = 'matrix4x4'
}


---@public 各个分量以行优先的方式传入
---@return matrix4x4
function matrix4x4.new(
        m11,m12,m13,m14,
        m21,m22,m23,m24,
        m31,m32,m33,m34,
        m41,m42,m43,m44
)
    --以二维数组的方式存储
    local matrix = {
        {m11,m12,m13,m14},
        {m21,m22,m23,m24},
        {m31,m32,m33,m34},
        {m41,m42,m43,m44}
    }
    setmetatable(matrix,matrix4x4)
    return matrix
end

---@public 将四个四维向量合并为一个4x4矩阵
---@return matrix4x4
function matrix4x4.combine(vec1,vec2,vec3,vec4)
    local matrix = {
        {vec1.x or 0, vec2.x or 0,vec3.x or 0, vec4.x or 0},
        {vec1.y or 0, vec2.y or 0,vec3.y or 0, vec4.y or 0},
        {vec1.z or 0, vec2.z or 0,vec3.z or 0, vec4.z or 0},
        {vec1.w or 0, vec2.w or 0,vec3.w or 0, vec4.w or 0},
    }
    setmetatable(matrix,matrix4x4)
    return matrix
end

---@public 创建一个单位矩阵
---@return matrix4x4
function matrix4x4.identity()
    local matrix = {
        {1,0,0,0},
        {0,1,0,0},
        {0,0,1,0},
        {0,0,0,1},
    }
    setmetatable(matrix,matrix4x4)
    return matrix
end

---@public
function matrix4x4.mulXYZW(matrix,x,y,z,w)
    local outX = x * matrix[1][1] + y * matrix[1][2] + z * matrix[1][3] + w * matrix[1][4]
    local outY = x * matrix[2][1] + y * matrix[2][2] + z * matrix[2][3] + w * matrix[2][4]
    local outZ = x * matrix[3][1] + y * matrix[3][2] + z * matrix[3][3] + w * matrix[3][4]
    local outW = x * matrix[4][1] + y * matrix[4][2] + z * matrix[4][3] + w * matrix[4][4]
    return outX,outY,outZ,outW
end

---@public 两个矩阵相乘
---@param mat1 matrix4x4
---@param mat2 matrix4x4
---@return matrix4x4
function matrix4x4.mul(mat1,mat2)
    local x1,y1,z1,w1 = matrix4x4.mulXYZW(mat1,mat2[1][1],mat2[2][1],mat2[3][1],mat2[4][1])
    local x2,y2,z2,w2 = matrix4x4.mulXYZW(mat1,mat2[1][2],mat2[2][2],mat2[3][2],mat2[4][2])
    local x3,y3,z3,w3 = matrix4x4.mulXYZW(mat1,mat2[1][3],mat2[2][3],mat2[3][3],mat2[4][3])
    local x4,y4,z4,w4 = matrix4x4.mulXYZW(mat1,mat2[1][4],mat2[2][4],mat2[3][4],mat2[4][4])
    local ret = matrix4x4.new(
            x1,x2,x3,x4,
            y1,y2,y3,y4,
            z1,z2,z3,z4,
            w1,w2,w3,w4
    )
    return ret
end

---@public 矩阵乘以向量。我们使用矩阵右乘向量的约定
---@param matrix matrix4x4
---@param vector vector4 不一定是四维的，三维也可以
---@return vector4
function matrix4x4.mulVector(matrix,vector)
    local x,y,z,w = matrix4x4.mulXYZW(matrix,vector.x,vector.y,vector.z or 0,vector.w or 0)
    return vector4.new(x,y,z,w)
end

---@public 标量乘
---@param matrix matrix4x4
---@param scalar number
---@return matrix4x4
function matrix4x4.mulScalar(matrix,scalar)
    local ret = matrix4x4.new(
            matrix[1][1] * scalar,matrix[1][2] * scalar,matrix[1][3] * scalar,matrix[1][4] * scalar,
            matrix[2][1] * scalar,matrix[2][2] * scalar,matrix[2][3] * scalar,matrix[2][4] * scalar,
            matrix[3][1] * scalar,matrix[3][2] * scalar,matrix[3][3] * scalar,matrix[3][4] * scalar,
            matrix[4][1] * scalar,matrix[4][2] * scalar,matrix[4][3] * scalar,matrix[4][4] * scalar
    )
    return ret
end

---@public 转置
---@param matrix matrix4x4
---@return matrix4x4
function matrix4x4.transpose(matrix)
    local ret = matrix4x4.new(
            matrix[1][1],matrix[2][1],matrix[3][1],matrix[4][1],
            matrix[1][2],matrix[2][2],matrix[3][2],matrix[4][2],
            matrix[1][3],matrix[2][3],matrix[3][3],matrix[4][3],
            matrix[1][4],matrix[2][4],matrix[3][4],matrix[4][4]
    )
    return ret
end

---@public 正交投影
function matrix4x4.orthographice(size,near,far)
    local ret = matrix4x4.new(
            2 / size,0,0,0,
            0,2 / size,0,0,
            0,0,2 / (near - far),(near + far)/(near - far) * -1,
            0,0,0,1
    )
    return ret
end

---@public 透视投影
function matrix4x4.perspective(fov,aspect,near,far)
    local cotFov = 1 / luaMath.tan( fov / 2 )
    local ret = matrix4x4.new(
           cotFov / aspect,0,0,0,
            0,cotFov,0,0,
            0,0,(near + far) / (near - far) * -1,(2 * near * far)/(near - far) * -1,
            0,0,-1,0
    )
    return ret
end

-----------------运算符重载------------------------

---重载乘法
matrix4x4.__mul = function(lhs,rhs)
    local rhsType = getLuaDataType(rhs)
    if rhsType == 'number' then
        return matrix4x4.mulScalar(lhs,rhs)
    elseif rhsType == 'table' then
        if rhs.x then
            return matrix4x4.mulVector(lhs,rhs)
        else
            return matrix4x4.mul(lhs,rhs)
        end
    else
        return lhs
    end
end

matrix4x4.__tostring = function(matrix)
    local str = table.concat({
        ' [',matrix[1][1],matrix[1][2],matrix[1][3],matrix[1][4],']\n',
        '|',matrix[2][1],matrix[2][2],matrix[2][3],matrix[2][4],'|\n',
        '|',matrix[3][1],matrix[3][2],matrix[3][3],matrix[3][4],'|\n',
        '[',matrix[4][1],matrix[4][2],matrix[4][3],matrix[4][4],']\n',
    },' ')
    return str
end

---@type matrix4x4
_G['matrix4x4'] = matrix4x4