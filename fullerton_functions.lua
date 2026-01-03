function xor(a,b)
    return  (not a and b) or (a and not b)
end

-- Returns a string of an appropriate magnitude & prefix, with only 2 decimals
function getNumberString(num)
    local i = 0
    local prefix = {'k','M','G','T','P','E'}
    local numString = ""
    while num >= 1000 do
        num = num / 1000
        i = i + 1
        numString = prefix[i]
    end
    if math.fmod(num,0.01) > 0 then
        numString = num - num%0.01 .. numString
    else
        numString = num .. numString
    end

    return numString
    
end
