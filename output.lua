local print = print
module(..., package.seeall)

local output = {}
output.__index = output

function new(...)
	o = setmetatable({}, output)
	return o:reset(...)
end

function output:reset(font, width, height, spacing)
	self.font = font or love.graphics.getFont()
	self.width = width or love.graphics.getWidth()
	self.height = height or love.graphics.getHeight()
	self.spacing = self.spacing or 4

	self.lines = {}

	self.char_width  = self.font:getWidth("_")
	self.char_height = self.font:getHeight("|")
	self.line_height = self.char_height + self.spacing

	self.lines_per_screen = math.floor(self.height / self.line_height) - 1
	self.chars_per_line = math.floor(self.width / self.char_width) - 1

	return self
end

function output:draw(ox,oy, cursor_pos)
	assert(ox and oy)
	local current_font = love.graphics.getFont() or self.font
	love.graphics.setFont(self.font)
	local lines_to_display = self.lines_per_screen - math.floor((self.height - oy) / self.line_height)
	for i = #self.lines, math.max(1, #self.lines - lines_to_display), -1 do
		love.graphics.print(self.lines[i], ox, oy - (#self.lines - i + 1) * self.line_height)
	end
	love.graphics.setFont(current_font)

	if not cursor_pos then return end
	local color = {love.graphics.getColor()}
	love.graphics.setColor(color[1],color[2],color[3],color[4]/3)

	-- calculate cursor offsets
	cursor_pos = self.lines[#self.lines]:len() + cursor_pos - 1
	local char_offset = cursor_pos % self.chars_per_line
	local line_offset = math.floor(cursor_pos / self.chars_per_line)

	local cur = {}
	cur.w = self.char_width + 1
	cur.h = self.char_height + 1
	cur.x = ox + self.char_width * char_offset
	cur.y = oy - cur.h + self.line_height * line_offset - 1
	love.graphics.rectangle('fill', cur.x, cur.y, cur.w, cur.h)
	love.graphics.setColor(unpack(color))
end

function output:push(...)
	local str = table.concat{...}
	local added = 0
	-- split newlines
	for line in str:gmatch("[^\n]+") do
		-- wrap lines
		while line:len() > self.chars_per_line do
			self.lines[#self.lines + 1] = line:sub(1, self.chars_per_line)
			line = line:sub(self.chars_per_line+1)
			added = added + 1
		end
		self.lines[#self.lines+1] = line
		added = added + 1
	end
	return added
end

function output:pop(n)
	local n = n or 1
	if n < 1 then return nil end
	return table.remove(self.lines), self:pop(n-1)
end

function output:push_char(c, ...)
	if not c then return end

	local line = self.lines[#self.lines]

	if line:len() + 1 < self.chars_per_line then
		line = line .. c
	else
		line = c
	end

	self.lines[#self.lines] = line
	return self:push_char(...)
end
