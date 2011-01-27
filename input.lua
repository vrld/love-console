local print = print
module(..., package.seeall)

local function _NULL_() end
local input = {}
input.__index = input

local function chars(str)
	local t = {}
	for c in str:gmatch(".") do
		t[#t+1] = c
	end
	return t
end

local function purge_history(history, cmd)
	for i = #history,1,-1 do
		if history[i] == cmd then
			table.remove(history, i)
		end
	end
end

local function set_default_hooks(inp)
	inp.hooks['return'] = function(self)
		local command = table.concat(self.line)
		purge_history(self.history, command)
		self.history[#self.history+1] = command
		self.selected = #self.history+1
		self.cursor = 1
		self.line = {}
		self:onCommand(command)
	end
	inp.hooks.kpenter = inp.hooks['return']

	inp.hooks.backspace = function(self)
		self.cursor = math.max(1, self.cursor - 1)
		table.remove(self.line, self.cursor)
	end

	inp.hooks.delete = function(self)
		table.remove(self.line, self.cursor)
	end

	inp.hooks.left = function(self)
		self.cursor = math.max(1, self.cursor - 1)
	end

	inp.hooks.right = function(self)
		self.cursor = math.min(#self.line+1, self.cursor + 1)
	end

	inp.hooks.up = function(self)
		self.selected = math.max(1, self.selected - 1)
		self.line = chars(self.history[self.selected] or "")
		self.cursor = #self.line + 1
	end

	inp.hooks.down = function(self)
		self.selected = math.min(#self.history+1, self.selected + 1)
		self.line = chars(self.history[self.selected] or "")
		self.cursor = #self.line + 1
	end

	inp.hooks.home = function(self)
		self.cursor = 1
	end

	inp.hooks['end'] = function(self)
		self.cursor = #self.line + 1
	end

	inp.hooks.tab = function(self)
		if self.complete_next then
			return self.complete_next()
		end

		-- get current token
		local inp = self:current()
		local left, right = 0,0
		repeat
			left, right = inp:find("[^%s%[%]%(%)%+%-%*/%%,=]+", right+1)
		until not right or right >= self.cursor - 1
		if not left or not right then return end
		inp = inp:sub(left,right)

		-- find completion table
		local tables = {}
		for t in inp:gmatch("[^\.]+") do
			tables[#tables+1] = t
		end
		local pattern = table.concat{"^", (tables[#tables] or ""):gsub("[%[%]%(%)]", function(s) return "%"..s end), ".*"}
		tables[#tables] = nil

		local search = self.complete_base
		for _, key in ipairs(tables) do
			if not search[key] then
				return
			end
			search = search[key]
		end

		-- find completion candidates
		local completions = {}
		for key,val in pairs(search or {}) do
			if key:match(pattern) then
				completions[#completions+1] = {key = key:sub(pattern:len()-2):reverse(), type = type(val)}
			end
		end
		if #completions < 1 then return end

		-- create completion function
		self.complete_next = coroutine.wrap(function()
			while true do
				for _,c in ipairs(completions) do
					local advance = #c.key
					-- insert completion and move cursor
					for char in c.key:gmatch(".") do
						table.insert(self.line, self.cursor, char)
					end
					self.cursor = self.cursor + advance
					-- if this is a function, add () and place cursor inside
					if self.complete_add_parens and c.type == "function" then
						table.insert(self.line, self.cursor,   "(")
						table.insert(self.line, self.cursor+1, ")")
						self.cursor = self.cursor + 1
					end

					coroutine.yield()

					-- if this was a function, remove the right )
					if self.complete_add_parens and c.type == "function" then
						table.remove(self.line, self.cursor)
						self.cursor = self.cursor - 1
					end
					-- remove completion
					for i = 0,advance do
						table.remove(self.line, self.cursor-i)
					end
					self.cursor = self.cursor - advance
				end
			end
		end)

		return self.complete_next()
	end
end

function new()
local inp = {
		history = {},
		selected = 1,
		line = {},
		cursor = 1,
		complete_next = nil,
		hooks = {},
		complete_base = _G,
		onCommand = _NULL_
	}
	set_default_hooks(inp)
	return setmetatable(inp, input)
end

function input:keypressed(key, code)
	if key ~= 'tab' then self.complete_next = nil end
	if self.hooks[key] then
		self.hooks[key](self)
	elseif code > 31 then
		table.insert(self.line, self.cursor, string.char(code))
		self.cursor = self.cursor + 1
	end
end

function input:current()
	return table.concat(self.line)
end

-- cursor position relative to the current line content
function input:pos()
	return self.cursor - #self.line - 1
end
