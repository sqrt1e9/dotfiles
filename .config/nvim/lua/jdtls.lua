local function get_jdtls()
    local mason_registry = require("mason-registry")
    local jdtls = mason_registry.get_package("jdtls")
    local jdtls_path = jdtls:get_install_path()
    local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
    local SYSTEM = "linux"
    local os_config = jdtls_path .. "/config_" .. SYSTEM
    local lombok = jdtls_path .. "/lombok.jar"
    return launcher, os_config, lombok
end

local function get_bundles()
    local mason_registry = require("mason-registry")
    local bundles = {}

    if mason_registry.has_package("java-debug-adapter") then
        local java_debug = mason_registry.get_package("java-debug-adapter")
        local debug_path = java_debug:get_install_path()
        local main_jar = vim.fn.glob(debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1)
        if main_jar ~= "" then
            table.insert(bundles, main_jar)
        end
    end

    if mason_registry.has_package("java-test") then
        local java_test = mason_registry.get_package("java-test")
        local test_path = java_test:get_install_path()
        local test_jars = vim.split(vim.fn.glob(test_path .. "/extension/server/*.jar", 1), "\n")
        vim.list_extend(bundles, test_jars)
    end
    return bundles
end

local function get_workspace()
    local home = os.getenv "HOME"
    local workspace_path = home .. "/.cache/Devworx/"
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    local workspace_dir = workspace_path .. project_name
    return workspace_dir
end

local function java_keymaps()
    vim.cmd("command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)")
    vim.cmd("command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()")
    vim.cmd("command! -buffer JdtBytecode lua require('jdtls').javap()")
    vim.cmd("command! -buffer JdtJshell lua require('jdtls').jshell()")

    vim.keymap.set('n', '<leader>Jo', "<Cmd> lua require('jdtls').organize_imports()<CR>", { desc = "organize_imports" })
    vim.keymap.set('n', '<leader>Jv', "<Cmd> lua require('jdtls').extract_variable()<CR>", { desc = "extract_variable" })
    vim.keymap.set('v', '<leader>Jv', "<Esc><Cmd> lua require('jdtls').extract_variable(true)<CR>", { desc = "extract_variable" })
    vim.keymap.set('n', '<leader>JC', "<Cmd> lua require('jdtls').extract_constant()<CR>", { desc = "extract_constant" })
    vim.keymap.set('v', '<leader>JC', "<Esc><Cmd> lua require('jdtls').extract_constant(true)<CR>", { desc = "extract_constant" })
    vim.keymap.set('n', '<leader>Jt', "<Cmd> lua require('jdtls').test_nearest_method()<CR>", { desc = "test_nearest_method" })
    vim.keymap.set('v', '<leader>Jt', "<Esc><Cmd> lua require('jdtls').test_nearest_method(true)<CR>", { desc = "test_nearest_method" })
    vim.keymap.set('n', '<leader>JT', "<Cmd> lua require('jdtls').test_class()<CR>", { desc = "test_class" })
    vim.keymap.set('n', '<leader>Ju', "<Cmd> JdtUpdateConfig<CR>", { desc = "jdt_update_config" })
end

local function setup_jdtls()
    local jdtls = require("jdtls.setup")
    local launcher, os_config, lombok = get_jdtls()
    local workspace_dir = get_workspace()
    local bundles = get_bundles()
    local root_dir = vim.fs.root(0, { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }) or vim.fn.getcwd()
    local capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                snippetSupport = false
            }
        }
    }

    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

    for k,v in pairs(lsp_capabilities) do capabilities[k] = v end
    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
    local cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-javaagent:' .. lombok,
        '-jar',
        launcher,
        '-configuration',
        os_config,
        '-data',
        workspace_dir
    }

    local settings = {
        java = {
            format = {
                enabled = true,
                settings = {
                    url = vim.fn.stdpath("config") .. "/intellij-java-google-style.xml",
                    profile = "GoogleStyle"
                }
            },
            eclipse = {
                downloadSource = true
            },
            maven = {
                downloadSources = true
            },
            signatureHelp = {
                enabled = true
            },
            contentProvider = {
                preferred = "fernflower"
            },
            saveActions = {
                organizeImports = true
            },
            completion = {
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*",
                },
                filteredTypes = {
                    "com.sun.*",
                    "io.micrometer.shaded.*",
                    "java.awt.*",
                    "jdk.*",
                    "sun.*",
                },
                importOrder = {
                    "java",
                    "jakarta",
                    "javax",
                    "com",
                    "org",
                }
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticThreshold = 9999
                }
            },
            codeGeneration = {
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                },
                hashCodeEquals = {
                    useJava7Objects = true
                },
                useBlocks = true
            },
            configuration = {
                updateBuildConfiguration = "interactive",
                runtimes = {
                    {
                        name = 'JavaSE-17',
                        path = '/usr/lib/jvm/java-17-openjdk'
                    }
                }
            },
            referencesCodeLens = {
                enabled = true
            },
            inlayHints = {
                parameterNames = {
                    enabled = "all"
                }
            }
        }
    }

    local init_options = {
        bundles = bundles,
        extendedClientCapabilities = extendedClientCapabilities
    }

    local on_attach = function(client, bufnr)
        java_keymaps()
        require('jdtls.dap').setup_dap()
        require('jdtls.dap').setup_dap_main_class_configs()
        require 'jdtls.setup'.add_commands()
        vim.lsp.codelens.refresh()
        client.server_capabilities.semanticTokensProvider = nil
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.java" },
            callback = function()
                local _, _ = pcall(vim.lsp.codelens.refresh)
            end
        })
    end

    local config = {
        cmd = cmd,
        root_dir = root_dir,
        settings = settings,
        capabilities = capabilities,
        init_options = init_options,
        on_attach = on_attach
    }

    require('jdtls.setup').start_or_attach(config)
end

return {
    setup_jdtls = setup_jdtls,
}
