local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local buffer = import("micro/buffer")

function init()
    config.RegisterCommonOption("goimports", false)
    config.RegisterCommonOption("gofmt", true)

    config.MakeCommand("goimports", "go.goimports", config.NoComplete)
    config.MakeCommand("gofmt", "go.gofmt", config.NoComplete)
    config.MakeCommand("gorename", "go.gorename", config.NoComplete)

    config.AddRuntimeFile("go", config.RTHelp, "help/go-plugin.md")
    config.TryBindKey("F6", "command-edit:gorename ", false)
    config.MakeCommand("gorename", "go.gorenameCmd", config.NoComplete)
end

function onSave(bp)
    if bp.Buf:FileType() == "go" then
        if bp.Buf.Settings["goimports"] then
            goimports(bp)
        elseif bp.Buf.Settings["gofmt"] then
            gofmt(bp)
        end
    end
    return false
end

function gofmt(bp)
    bp:Save()
    local _, err = shell.RunCommand("gofmt -w " .. bp.Buf.Path)
    if err ~= nil then
        micro.InfoBar():Error(err)
        return
    end

    bp.Buf:ReOpen()
end

function gorenameCmd(bp, args)
    micro.Log(args)
    if #args == 0 then
        micro.InfoBar():Message("Not enough arguments")
    else
        bp:Save()
        local buf = bp.Buf
        if #args == 1 then
            local c = bp.Cursor
            local loc = buffer.Loc(c.X, c.Y)
            local offset = buffer.ByteOffset(loc, buf)
            local cmdargs = {"--offset", buf.Path .. ":#" .. tostring(offset), "--to", args[1]}
            shell.JobSpawn("gorename", cmdargs, "", "go.renameStderr", "go.renameExit", bp)
        else
            local cmdargs = {"--from", args[1], "--to", args[2]}
            shell.JobSpawn("gorename", cmdargs, "", "go.renameStderr", "go.renameExit", bp)
        end
        micro.InfoBar():Message("Renaming...")
    end
end

function renameStderr(err)
    micro.Log(err)
    micro.InfoBar():Message(err)
end

function renameExit(output, args)
    local bp = args[1]
    bp.Buf:ReOpen()
end

function goimports(bp)
    bp:Save()
    local _, err = shell.RunCommand("goimports -w " .. bp.Buf.Path)
    if err ~= nil then
        micro.InfoBar():Error(err)
        return
    end

    bp.Buf:ReOpen()
end
