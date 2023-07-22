-- 'mesg' is a String provided by the host that gives the Lua worker
-- script input data 
print("lua got req:"..mesg)
-- just echo the req string
local reply = "lua says back to you:" .. mesg
-- send is a function provided by the host for send data out of the Lua
-- worker to the host
send(reply)