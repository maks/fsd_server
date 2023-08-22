-- input is a int provided by the host
print("lua got req:")
print(input)
local accum = 0
for i = 0, input do
    accum = accum + i
end
send(accum)