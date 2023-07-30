-- dummy load
local accum = 0
for i = 1, 500, 1 do
    accum = accum + 1
end
send("completed:" .. tid)


