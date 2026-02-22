local blocks = {"  ", "░░", "▒▒", "▓▓", "██"}
local max_alpha = 255
local esc_string = "\x1B"
local reset_ansi = esc_string .. "[0m"

function getBlock(pixel, color)
    local index = math.tointeger(color.alpha * (#blocks - 1) / max_alpha)
    return blocks[index + 1]
end

function convertColorTo8BitCode(r, g, b) 
    local red = (r ~= 0) and math.tointeger((r - 55) / 40) or 0
    local green = (g ~= 0) and math.tointeger((g - 55) / 40) or 0
    local blue = (b ~= 0) and math.tointeger((b - 55) / 40) or 0
    return 16 + (red * 36) + (green * 6) + blue
end

local last_code = -1

function getAnsiPixel(pixel, color)
    local block = getBlock(pixel, color)
    if color.alpha == 0 then
        if last_code == -1 then return block end
        last_code = -1
        return reset_ansi .. block
    end
    local code = convertColorTo8BitCode(color.red, color.green, color.blue)

    if last_code == code then
        return block
    end
    
    last_code = code
    return reset_ansi .. esc_string .. string.format("[38;5;%dm", code) .. block
end

function exportAnsi(filename)
    local image = app.image
    if not image then return end

    local rectangle = image.bounds
    if not rectangle then return end
    local output_string = ""

    for it in image:pixels() do
        local pixelValue = image:getPixel(it.x, it.y)
        local c = Color(pixelValue)
        output_string = output_string .. getAnsiPixel(it, c)
        if it.x == rectangle.w - 1 then
            output_string = output_string .. "\n"
        end
    end

    local f = assert(io.open(filename, "w")) 
    f:write(output_string) 
    f:close()
end

function init(plugin)
    plugin:newCommand{
        id="FileExportAnsi",
        title="Export Ansi",
        group="file_export_1",
        onclick=function()
            local sprite = app.sprite
            if not sprite then return end

            local dlg = Dialog("Export ANSI")

            dlg:file{
                id = "filename",
                label = "Save as:",
                save = true,
                filename = sprite.filename:gsub("%.%w+$", "") .. ".ans",
                filetypes = { "ans" }
            }

            dlg:button{
                text = "Export",
                onclick = function()
                    local data = dlg.data
                    if not data.filename then
                        dlg:close()
                        return
                    end

                    exportAnsi(data.filename)
                    dlg:close()
                end
            }

            dlg:button{ text = "Cancel" }

            dlg:show{ wait = true }
        end
    }
end