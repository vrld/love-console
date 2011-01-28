local _print = print
local Console = require "console"
console = nil
input   = nil
output  = nil

local console_active = true

local debug = debug
local function error_handler(msg)
	print((debug.traceback("Error: " .. msg, 4):gsub("\t", "    ")))
end

local handler_names = {
	kr = 'keyreleased',
	mp = 'mousepressed',
	mr = 'mousereleased',
	jp = 'joystickpressed',
	jr = 'joystickreleased',
	f = 'focus',
}

function love.run()
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

	local dt = 0
	while true do
		love.timer.step()
		dt = love.timer.getDelta()

		if love.update then
			-- if exists, call love.update. on error, remove function
			if not xpcall(function() love.update(dt) end, error_handler) then
				love.update = nil
			end
		end

		love.graphics.clear()
		if love.draw then
			-- if exists, call love.draw. on error, remove function
			if not xpcall(love.draw, error_handler) then
				love.draw = nil
			end
		end

		-- draw console
		if console_active then
			local color = {love.graphics.getColor()}
			love.graphics.setColor(34,34,34,180)
			love.graphics.rectangle('fill', 2,2, love.graphics.getWidth()-4, love.graphics.getHeight()-4)
			love.graphics.setColor(221,221,221)
			console:draw(4, love.graphics.getHeight() - 4)
			love.graphics.setColor(unpack(color))
		end

		-- process events
		for e,a,b,c in love.event.poll() do
			if e == "q" then
				-- quit event
				if not love.quit or not love.quit() then
					love.audio.stop()
					return
				end
			elseif e == "kp" then
				-- keypress event. let us catch that
				if a == 'escape' then
					console_active = not console_active
				end

				if console_active then
					console:keypressed(a,b)
				end
			else
				-- call handlers in protective mode. if they fail,
				-- show error and remove the handler
				local f = love[ handler_names[e] ]
				if type(f) == "function" and not xpcall(function() f(a,b,c) end, error_handler) then
					love[ handler_names[e] ] = nil
				end
			end
		end

		love.timer.sleep(1)
		love.graphics.present()
	end
end

function print(...)
	return console:print(...)
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end

function quit()
	love.event.push('q')
end
exit = quit
