-- just echo
print("lua got req:"..req)
local reply = "lua says back to you:" .. req
send(reply)