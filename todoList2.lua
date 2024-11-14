shell.run("label set ToDo")
local periList = peripheral.getNames()
local mon = term.native()
local isMonitorAvailable = false

for i = 1, #periList do
    if peripheral.getType(periList[i]) == "monitor" then
        mon = peripheral.wrap(periList[i])
        isMonitorAvailable = true
        print("Monitor wrapped as... " .. periList[i])
    end
end

local currentPage = 1
local width, height = mon.getSize()
local line = height - 5 -- Ajustado para novos botões

function textCol(color)
    if mon.isColor() then
        term.setTextColor(color)
        mon.setTextColor(color)
    end
end

function dualWrite(x, y, text)
    term.setCursorPos(x, y)
    term.write(text)
    mon.setCursorPos(x, y)
    mon.write(text)
end

local todo = {}

function openTODO()
    local file = fs.open("todolist", "r")
    if file ~= nil then
        local data = file.readAll()
        file.close()
        if textutils.unserialize(data) == nil then
            todo[1] = {text = "Make a todo list", status = "Not Completed"}
        else
            todo = textutils.unserialize(data)
            for _, task in pairs(todo) do
                task.status = task.status or "Not Completed"
            end
        end
    else
        todo[1] = {text = "Make a todo list", status = "Not Completed"}
    end
end

function saveTODO()
    local file = fs.open("todolist", "w")
    file.write(textutils.serialize(todo))
    file.close()
end

function displayPage(p)
    textCol(colors.white)
    mon.clear()
    mon.setCursorPos(1, 2)
    term.clear()
    term.setCursorPos(1, 2)
    for i = (1 + (p - 1) * line), (p * line) do
        if todo[i] ~= nil then
            local status = todo[i].status
            local textColor = colors.white
            if status == "Completed" then
                textColor = colors.green
            elseif status == "In Progress" then
                textColor = colors.orange
            end
            textCol(textColor)
            dualWrite(1, i - (p - 1) * line + 1, "[" .. status .. "] " .. todo[i].text)
        end
    end
end

function printButtons()
    local buttonY = height - 1
    local function drawButton(x, text, color)
        textCol(color)
        mon.setCursorPos(x, buttonY)
        mon.write("[" .. text .. "]")
        term.setCursorPos(x, buttonY)
        term.write("[" .. text .. "]")
    end

    drawButton(2, "Add Item", colors.green)
    drawButton(15, "Remove Completed", colors.red)
    drawButton(width - 13, "Cycle Page", colors.yellow)
end

function addItem()
    term.clear()
    mon.clear()
    term.setCursorPos(2, 2)
    mon.setCursorPos(2, 2)
    dualWrite(2, 2, "Please enter a new item:")
    local input = read()
    local newItem = {text = input, status = "Not Completed"}
    table.insert(todo, 1, newItem)
    saveTODO()
    dualWrite(2, 2, "Item added!")
    os.sleep(2)
end

function removeCompletedTasks()
    local newTodo = {}
    for i = 1, #todo do
        if todo[i].status ~= "Completed" then
            table.insert(newTodo, todo[i])
        end
    end
    todo = newTodo
    saveTODO()
end

openTODO()

term.clear()
mon.clear()
printButtons()
displayPage(1)

while true do
    local event, side, x, y
    if isMonitorAvailable then
        event, side, x, y = os.pullEvent("monitor_touch")
    else
        event, button, x, y = os.pullEvent("mouse_click")
    end

    if y == height - 1 then
        if x >= 2 and x <= 11 then
            addItem()
        elseif x >= 15 and x <= 30 then
            removeCompletedTasks()
        elseif x >= width - 13 then
            if currentPage >= #todo / line then
                currentPage = 1
            else
                currentPage = currentPage + 1
            end
        end
    elseif y >= 2 and y <= height - 5 then
        local itm = (currentPage - 1) * line + y - 2
        if todo[itm] ~= nil then
            if todo[itm].status == "Not Completed" then
                todo[itm].status = "In Progress"
            elseif todo[itm].status == "In Progress" then
                todo[itm].status = "Completed"
            else
                todo[itm].status = "Not Completed"
            end
            saveTODO()
        end
    end
    printButtons()
    displayPage(currentPage)
end
