-- dummy load
while true do
    sleep(1000)
    local accum = 0
    for i = 1, 50 do
        accum = accum + i
    end
    send(tid)
end
