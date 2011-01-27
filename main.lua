local _print = print
local IN =require 'input'
local OUT = require 'output'

input = IN:new()
local output

local console_active = true

local chunk = nil
prompt1, prompt2 = "> ", "| "
local prompt = prompt1
function input:onCommand(cmd)
	output:push(prompt, cmd)
	cmd = cmd:gsub("^=%s?", "return "):gsub("^return%s+(.*)(%s*)$", "print(%1)%2")
	chunk = chunk and table.concat({chunk, cmd}, " ") or cmd
	local ok, out = pcall(function() assert(loadstring(chunk))() end)
	if not ok and out:match("'<eof>'") then
		prompt = prompt2
		input.history[#input.history] = nil
	else
		prompt = prompt1
		if out and out:len() > 0 then
			output:push(out)
		end
		input.history[#input.history] = chunk
		chunk = nil
	end
end
input.complete_add_parens = true
input.complete_base = _G

local function draw()
	love.graphics.setColor(34,34,34,180)
	love.graphics.rectangle('fill', 2,2, love.graphics.getWidth()-4, love.graphics.getHeight()-4)
	love.graphics.setColor(221,221,221)
	local inp = table.concat{prompt, input:current(), " "}
	local n = output:push(inp)
	output:draw(4, love.graphics.getHeight() - 4, input:pos())
	output:pop(n)
end

function love.run()
	love.graphics.setFont('VeraMono.ttf', 14)
	love.keyboard.setKeyRepeat(150, 50)
	love.graphics.setBackgroundColor(34,34,34)

	output = OUT.new()

	print("|  '/\\'\\  / /_\\  __  /' /\\ |\\ | /_ /\\ |   /_\\")
	print("|__ \\/  \\/  \\_       \\, \\/ | \\|  / \\/ |__ \\_   (v.1e-127)")
	print()
	print("<Escape> toggles the console. Call quit() or exit() to quit.")
	print("Try hitting <Tab> to complete your current input.")
	print("You can overwrite every love callback except love.keypressed.")
	print()

	local dt = 0
	while true do
		love.timer.step()
		dt = love.timer.getDelta()

		if love.update then love.update(dt) end
		love.graphics.clear()
		if love.draw then love.draw() end
		if console_active then
			local color = {love.graphics.getColor()}
			assert(pcall(draw))
			love.graphics.setColor(unpack(color))
		end

		for e,a,b,c in love.event.poll() do
			if e == "q" then
				if not love.quit or not love.quit() then
					love.audio.stop()
					return
				end
			elseif e == "kp" then
				if a == 'escape' then
					console_active = not console_active
				end

				if console_active then
					input:keypressed(a,b)
				end
			else
				love.handlers[e](a,b,c)
			end
		end

		love.timer.sleep(1)
		love.graphics.present()
	end
end

function print(...)
	local n_args, s = select('#', ...), {...}
	for i = 1,n_args do
		s[i] = (s[i] == nil) and "nil" or tostring(s[i])
	end
	if n_args == 0 then s = {" "} end
	output:push(table.concat(s, "    "))
end

function quit()
	love.event.push('q')
end
exit = quit
