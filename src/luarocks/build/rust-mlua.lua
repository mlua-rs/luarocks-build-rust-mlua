local fs = require("luarocks.fs")
local cfg = require("luarocks.core.cfg")
local dir = require("luarocks.dir")
local path = require("luarocks.path")

local mlua = {}

function mlua.run(rockspec, no_install)
    assert(rockspec:type() == "rockspec")

    if not fs.is_tool_available("cargo", "Cargo") then
        return nil, "'cargo' is not installed.\n" .. "This rock is written in Rust: make sure you have a Rust\n" ..
            "development environment installed and try again."
    end

    local features = {}
    local lua_version = cfg.lua_version
    local variables = rockspec.variables

    -- Activate features depending on Lua version
    if (cfg.cache or {}).luajit_version ~= nil then
        table.insert(features, "luajit")
    elseif lua_version == "5.4" then
        table.insert(features, "lua54")
    elseif lua_version == "5.3" then
        table.insert(features, "lua53")
    elseif lua_version == "5.2" then
        table.insert(features, "lua52")
    elseif lua_version == "5.1" then
        table.insert(features, "lua51")
    else
        return nil, "Lua version " .. lua_version .. " is not supported"
    end

    local cmd, cmd_sep = {}, " "
    local lua_incdir, lua_h = variables.LUA_INCDIR, "lua.h"
    local found_lua_h = fs.exists(dir.path(lua_incdir, lua_h))
    if not cfg.is_platform("windows") then
        -- If lua.h does not exists, add "vendored" feature (probably this is impossible case)
        if found_lua_h then
            table.insert(cmd, "LUA_INC=" .. variables.LUA_INCDIR)
        else
            table.insert(features, "vendored")
        end
    else
        -- For windows we must ensure that lua.h exists
        if not found_lua_h then
            return nil, "Lua header file " .. lua_h .. " not found (looked in " .. lua_incdir .. "). \n" ..
                "You need to install the Lua development package for your system."
        end
        local lualib = variables.LUALIB
        lualib = string.gsub(lualib, "%.lib$", "")
        lualib = string.gsub(lualib, "%.dll$", "")
        table.insert(cmd, "SET LUA_INC=" .. variables.LUA_INCDIR)
        table.insert(cmd, "SET LUA_LIB=" .. variables.LUA_LIBDIR)
        table.insert(cmd, "SET LUA_LIB_NAME=" .. lualib)
        cmd_sep = "&&"
    end

    table.insert(cmd, "cargo build --release --features " .. table.concat(features, ","))
    if not fs.execute(table.concat(cmd, cmd_sep)) then
        return nil, "Failed building."
    end

    if rockspec.build and rockspec.build.modules and not (no_install) then
        local libdir = path.lib_dir(rockspec.name, rockspec.version)

        fs.make_dir(dir.dir_name(libdir))
        for _, mod in ipairs(rockspec.build.modules) do
            local rustlib = "lib" .. mod .. "." .. cfg.external_lib_extension
            if cfg.is_platform("windows") then
                rustlib = mod .. "." .. cfg.external_lib_extension
            end
            local src = dir.path("target", "release", rustlib)
            local dst = dir.path(libdir, mod .. "." .. cfg.lib_extension)

            local ok, err = fs.copy(src, dst, "exec")
            if not ok then
                return nil, "Failed installing " .. src .. " in " .. dst .. ": " .. err
            end
        end
    end

    return true
end

return mlua
