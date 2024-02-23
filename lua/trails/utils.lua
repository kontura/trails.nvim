
local U = {}

U.get_value_index = function(list, value)
    for i,v in pairs(list) do
        if v == value then
            return i
        end
    end
    return -1
end

return U
