local old
old = hookfunction(task.delay,function(t,f,...)
    if t > 0.1 then
        return old(0,f,...)
    end
    return old(t,f,...)
end)
