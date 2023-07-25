-- dummy load
while true do
    local accum = 0
    for i = 1, 50, 1 do
        accum = accum + 1
    end
    send("completed:" .. accum)
    wait(1)
end
