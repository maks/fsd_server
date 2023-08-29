-- input is a int provided by the host
-- print("["..tid.."] lua got req:"..input.."\n")
local accum = 0
for i = 0, input do
    accum = accum + i
end
send(tid)