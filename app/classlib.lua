---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangfan
--- DateTime: 2021/11/16 15:15
---

local classMap = {}

--执行构造函数
local function performCtor(class_type,instance,...)

    if class_type.super then
        performCtor(class_type.super,instance,...)
    end

    if class_type.ctor then
        class_type.ctor(instance,...)
    end

end


--构建类的方法
function declareClass(className,super)

    if classMap[className] then
        return classMap[className]
    end

    local class_type = {}--代表类原型的table

    class_type.__classname = className
    class_type.super = super
    --预先声明构造函数
    class_type.ctor = function() end

    --成员函数表
    local funcTable = {}
    class_type.funcTable = funcTable
    class_type.meta = { __index = class_type.funcTable }

    if super then
        setmetatable(funcTable,{
            __index = function(t,k)
                local ret = super.funcTable[k]
                return ret
            end
        })
    end

    class_type.new = function(...)

        local instance = {}

        instance.__classname = class_type.__classname

        setmetatable(instance,class_type.meta)

        performCtor(class_type,instance,...)

        return instance
    end
    --对于代表类原型的table只允许声明function类型的值
    --Tips.除了构造函数，其他声明的函数会存入funcTable表中
    setmetatable(class_type,{
        __newindex = function(t,k,v)
            if type(v) ~= 'function' then
                return
            end
            t.funcTable[k] = v
        end
    })
    --
    classMap[className] = class_type
    --
    return class_type
end

classLib = classMap