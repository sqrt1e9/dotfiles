local function run_in_split_terminal(cmd)
	vim.cmd('split')
	vim.cmd('terminal')
	vim.defer_fn(function()
		local job_id = vim.b.terminal_job_id
		if not job_id then
			print("Could not get terminal job id")
			return
		end
		vim.fn.chansend(job_id, cmd .. "\n")
	end, 100)
end

local function resolve_compiler(ft)
	if ft == "c" then
		return vim.b.c_compiler or vim.g.c_compiler or "gcc"
	elseif ft == "cpp" then
		return vim.b.cpp_compiler or vim.g.cpp_compiler or "g++"
	else
		return nil
	end
end

local function default_std_flag(ft)
	return (ft == "c") and "-std=c11" or "-std=c++20"
end

local function compile_run_core(use_openmp)
	local ft = vim.bo.filetype
	if ft ~= "c" and ft ~= "cpp" then
		print("Not a C or C++ file!")
		return
	end

	local compiler	= resolve_compiler(ft)
	if not compiler or compiler == "" then
		print("No compiler resolved for filetype: " .. tostring(ft))
		return
	end

	local filename	= vim.fn.expand("%:t:r")
	local out_dir	= ".out"
	local output	= out_dir .. "/" .. filename
	local filepath	= vim.fn.expand("%:p")

	local stdflag	= default_std_flag(ft)
	local warnflags	= "-Wall -Wextra -Wpedantic"
	local ompflag	= use_openmp and "-fopenmp" or ""
	local envpref	= use_openmp and "OMP_NUM_THREADS=${OMP_NUM_THREADS:-8} " or ""

	os.execute("mkdir -p " .. out_dir)

	local compile_cmd = compiler .. " " .. stdflag .. " " .. warnflags
	if ompflag ~= "" then compile_cmd = compile_cmd .. " " .. ompflag end
	compile_cmd = compile_cmd .. " '" .. filepath .. "' -o '" .. output .. "'"

	local run_cmd = envpref .. "./'" .. output .. "'"

	local cmd = compile_cmd .. " && " .. run_cmd

	run_in_split_terminal(cmd)
end

_G.compile_run_cpp = function()
	if vim.bo.filetype ~= "cpp" then
		print("Not a C++ file!")
		return
	end
	compile_run_core(false)
end

_G.compile_run_cpp_omp = function()
	if vim.bo.filetype ~= "cpp" then
		print("Not a C++ file!")
		return
	end
	compile_run_core(true)
end

_G.compile_run_c = function()
	if vim.bo.filetype ~= "c" then
		print("Not a C file!")
		return
	end
	compile_run_core(false)
end

_G.compile_run_c_omp = function()
	if vim.bo.filetype ~= "c" then
		print("Not a C file!")
		return
	end
	compile_run_core(true)
end

vim.api.nvim_create_user_command("SetCCompiler", function(opts)
	vim.b.c_compiler = opts.args
	print("C compiler (buffer) = " .. vim.b.c_compiler)
end, { nargs = 1 })

vim.api.nvim_create_user_command("SetCppCompiler", function(opts)
	vim.b.cpp_compiler = opts.args
	print("C++ compiler (buffer) = " .. vim.b.cpp_compiler)
end, { nargs = 1 })

