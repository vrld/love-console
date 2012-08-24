local print = print
module(..., package.seeall)
local IN  = require 'input'
local OUT = require 'output'

local console = {}
console.__index = console

function new(font, width, height, spacing)
	local self = setmetatable({}, console)
	self._out = OUT.new(font, width, height, spacing)
	self._in  = IN.new()
	self._in.onCommand = function(_, cmd)
		return self:onCommand(cmd)
	end
	self._in.unfocus = function(_)
		return self:unfocus()
	end
	self._in.complete_add_parens = true
	self._in.complete_base = _G

	self.prompt1 = "> "
	self.prompt2 = "| "
	self._prompt = self.prompt1
	return self
end

function console:print(...)
	local n_args, s = select('#', ...), {...}
	for i = 1,n_args do
		s[i] = (s[i] == nil) and "nil" or tostring(s[i])
	end
	if n_args == 0 then s = {" "} end
	self._out:push(table.concat(s, "    "))
end

function console:onCommand(cmd)
	self._out:push(self._prompt, cmd)
	cmd = cmd:gsub("^=%s?", "return "):gsub("^return%s+(.*)(%s*)$", "print(%1)%2")
	self.chunk = self.chunk and table.concat({self.chunk, cmd}, " ") or cmd
	local ok, out = pcall(function() assert(loadstring(self.chunk))() end)
	if not ok and out:match("'<eof>'") then
		self._prompt = self.prompt2
		self._in.history[#self._in.history] = nil
	else
		self._prompt = self.prompt1
		if out and out:len() > 0 then
			self._out:push(out)
		end
		self._in.history[#self._in.history] = self.chunk
		self.chunk = nil
	end
end

function console:draw(ox,oy)
	assert(ox and oy)
	local inp = table.concat{self._prompt, self._in:current(), " "}
	local n = self._out:push(inp)
	self._out:draw(4, love.graphics.getHeight() - 4, self._in:pos())
	self._out:pop(n)
end

local _current_focus
function console:focus()
	if _current_focus then
		_current_focus:unfocus()
	end
	self._keypressed = love.keypressed
	love.keypressed = function(...) self._in:keypressed(...) end
	_current_focus = self
end

function console:unfocus()
	love.keypressed = self._keypressed
	_current_focus = nil
end

function console:keypressed(...)
	self._in:keypressed(...)
end
