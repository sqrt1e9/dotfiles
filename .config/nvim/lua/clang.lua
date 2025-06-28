function CompileRunCpp()
	if vim.bo.filetype ~= "cpp" then
		print("Not a C++ file!")
		return
	end
	local filename = vim.fn.expand("%:t:r")
	local out_dir = ".out"
	local output = out_dir .. "/" .. filename
	local filepath = vim.fn.expand("%:p")

	os.execute("mkdir -p " .. out_dir)

	vim.cmd('split')
	vim.cmd('terminal')
	vim.defer_fn(function()
		local job_id = vim.b.terminal_job_id
		if not job_id then
			print("Could not get terminal job id")
			return
		end
		local cmd = string.format("g++ '%s' -o '%s' && ./'%s'\n", filepath, output, output)
		vim.fn.chansend(job_id, cmd)
	end, 100)
end

