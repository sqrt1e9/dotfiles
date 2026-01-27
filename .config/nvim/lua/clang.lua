-- Split-terminal helper: opens a terminal in a horizontal split (used for RUN and for compile errors).
local function open_split_terminal()
	vim.cmd("split")
	vim.cmd("terminal")
	vim.cmd("startinsert")
	return vim.b.terminal_job_id
end

local function send_to_terminal(job_id, cmd)
	if not job_id then
		print("Could not get terminal job id")
		return
	end
	vim.fn.chansend(job_id, cmd .. "\n")
end

local function resolve_compiler(ft)
	if ft == "c" then
		return vim.b.c_compiler or vim.g.c_compiler or "gcc"
	elseif ft == "cpp" then
		return vim.b.cpp_compiler or vim.g.cpp_compiler or "g++"
	end
	return nil
end

local function default_std_flag(ft)
	return (ft == "c") and "-std=c11" or "-std=c++20"
end

local function get_paths()
	local filename	= vim.fn.expand("%:t:r")
	local out_dir	= ".out"
	local output	= out_dir .. "/" .. filename
	local filepath	= vim.fn.expand("%:p")
	return out_dir, output, filepath
end

local function ensure_out_dir(out_dir)
	vim.fn.mkdir(out_dir, "p")
end

-- Returns: compile_cmd, output_path, err
local function build_compile_cmd()
	local ft = vim.bo.filetype
	if ft ~= "c" and ft ~= "cpp" then
		return nil, nil, "Not a C or C++ file!"
	end

	local compiler = resolve_compiler(ft)
	if not compiler or compiler == "" then
		return nil, nil, "No compiler resolved for filetype: " .. tostring(ft)
	end

	local out_dir, output, filepath = get_paths()
	ensure_out_dir(out_dir)

	local stdflag	= default_std_flag(ft)
	local warnflags	= "-Wall -Wextra -Wpedantic"

	local src = vim.fn.shellescape(filepath)
	local out = vim.fn.shellescape(output)

	local compile_cmd = table.concat({
		compiler,
		stdflag,
		warnflags,
		src,
		"-o",
		out,
	}, " ")

	return compile_cmd, output, nil
end

-- Option 1: compile only
-- success: no terminal, show message
-- fail: open terminal and show errors (without shell prompt between lines)
_G.compile_c_cpp = function()
	local compile_cmd, output, err = build_compile_cmd()
	if err then
		print(err)
		return
	end

	local lines = {}

	local function collect(data)
		if not data then return end
		for _, line in ipairs(data) do
			if line and line ~= "" then
				table.insert(lines, line)
			end
		end
	end

	vim.fn.jobstart(compile_cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data, _)
			collect(data)
		end,
		on_stderr = function(_, data, _)
			collect(data)
		end,
		on_exit = function(_, code, _)
			vim.schedule(function()
				if code == 0 then
					print("Compiled OK -> " .. output)
					return
				end

				-- Failed: open terminal and dump everything in ONE heredoc command
				local job_id = open_split_terminal()

				local header = {
					"=== COMPILE FAILED ===",
					"CMD: " .. compile_cmd,
					"----------------------",
				}

				local all = {}
				for _, h in ipairs(header) do table.insert(all, h) end
				for _, l in ipairs(lines) do table.insert(all, l) end
				table.insert(all, "----------------------")

				local heredoc = "cat <<'__NVIM_COMPILE__'\n"
					.. table.concat(all, "\n")
					.. "\n__NVIM_COMPILE__"

				vim.defer_fn(function()
					send_to_terminal(job_id, heredoc)
				end, 50)
			end)
		end,
	})
end

-- Option 2: run only (assumes you've already compiled)
-- terminal is required for stdin
_G.run_c_cpp = function()
	local ft = vim.bo.filetype
	if ft ~= "c" and ft ~= "cpp" then
		print("Not a C or C++ file!")
		return
	end

	local _, output, _ = get_paths()
	local run_cmd = "./" .. vim.fn.shellescape(output)

	local job_id = open_split_terminal()
	vim.defer_fn(function()
		send_to_terminal(job_id, run_cmd)
	end, 50)
end

-- Optional: convenience function (compile then run)
_G.compile_and_run_c_cpp = function()
	local compile_cmd, output, err = build_compile_cmd()
	if err then
		print(err)
		return
	end

	local run_cmd = "./" .. vim.fn.shellescape(output)
	local cmd = compile_cmd .. " && " .. run_cmd

	local job_id = open_split_terminal()
	vim.defer_fn(function()
		send_to_terminal(job_id, cmd)
	end, 50)
end

vim.api.nvim_create_user_command("SetCCompiler", function(opts)
	vim.b.c_compiler = opts.args
	print("C compiler (buffer) = " .. vim.b.c_compiler)
end, { nargs = 1 })

vim.api.nvim_create_user_command("SetCppCompiler", function(opts)
	vim.b.cpp_compiler = opts.args
	print("C++ compiler (buffer) = " .. vim.b.cpp_compiler)
end, { nargs = 1 })

