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

    -- Activate features depending on Lua version
    if lua_version == "5.4" then
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

    local cmd = {"cargo build --release"}
    -- Check if default features not required
    if rockspec.build and rockspec.build.default_features == false then
        table.insert(cmd, "--no-default-features")
    end
    -- Add additional features
    if rockspec.build and type(rockspec.build.features) == "table" then
        for _, feature in ipairs(rockspec.build.features) do
            table.insert(features, feature)
        end
    end
    table.insert(cmd, "--features")
    table.insert(cmd, table.concat(features, ","))

    if not fs.execute(table.concat(cmd, " ")) then
        return nil, "Failed building."
    end

    if rockspec.build and rockspec.build.modules and not (no_install) then
        local libdir = path.lib_dir(rockspec.name, rockspec.version)

        fs.make_dir(dir.dir_name(libdir))
        for mod, rustlib_name in pairs(rockspec.build.modules) do
            -- If `mod` is a number, then it's an array entry
            if type(mod) == "number" then
                mod = rustlib_name
            end

            local rustlib = "lib" .. rustlib_name .. "." .. cfg.external_lib_extension
            if cfg.is_platform("windows") then
                rustlib = mod .. "." .. cfg.external_lib_extension
            end
            local target_path = rockspec.build.target_path or "target"
            local src = dir.path(target_path, "release", rustlib)
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
