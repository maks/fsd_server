-- dummy load
local accum = 0
for i = 1, 5000 do
    accum = accum + i
end
send("completed:" .. tid)


