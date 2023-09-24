-- input is a int provided by the host
print("Lua TID:", tid)
print("Sum to:", sum_to)
local accum = 0
for i = 0, sum_to do
    accum = accum + i
end
send(accum)