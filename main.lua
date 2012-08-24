local _print = print
local Console = require "console"
console = nil
input   = nil
output  = nil

local debug = debug
local function error_handler(msg)
	print((debug.traceback("Error: " .. msg, 4):gsub("\t", "    ")))
end

function love.load()
	love.keyboard.setKeyRepeat(150, 50)
	love.graphics.setBackgroundColor(34,34,34)
	local font = love.graphics.newFont('VeraMono.ttf', 14)
	console = Console.new(font)

	print("|  '/\\'\\  / /_\\  __  /' /\\ |\\ | /_ /\\ |   /_\\")
	print("|__ \\/  \\/  \\_       \\, \\/ | \\|  / \\/ |__ \\_   (v.1e-127)")
	print()
	print("<Escape> toggles the console. Call quit() or exit() to quit.")
	print("Try hitting <Tab> to complete your current input.")
	print("You can overwrite every love callback (but love.keypressed).")
	print()	

end

function love.update(dt)

end

function love.draw()
	console:draw(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.mousepressed(x, y, button)
end

function love.keypressed(key)
	if key == "escape" then
		console:focus()
	end
end

function print(...)
	return console:print(...)
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end

function quit()
	love.event.push('quit')
end
exit = quit
