#!/usr/bin/env lua

-- test writing examples.lua to examples.html
arg = {[0]=arg[0], 'examples.lua'}
dofile 'luainspect'
print 'output written to examples.html'
