shell.run("label set ToDo")
local periList = peripheral.getNames()
local mon = term.native()
for i = 1, #periList do
    if peripheral.getType(periList[i]) == "monitor" then
        mon = peripheral.wrap(periList[i])
        print("Monitor wrapped as... " .. periList[i])
    end
end

term.redirect(mon)

local currentPage = 1
local width, height = mon.getSize()
local line = height - 3

function textCol(color)
    if mon.isColor() then
        term.setTextColor(color)
    end
end

function openTODO()
    local file = fs.open("todolist", "r")
    if file ~= nil then
        local data = file.readAll()
        file.close()
        if textutils.unserialize(data) == nil then
            todo[1] = {text = "Make a todo list", completed = false, inProgress = false}
        else
            todo = textutils.unserialize(data)
        end
    else
        todo[1] = {text = "Make a todo list", completed = false, inProgress = false}
    end
end

function saveTODO()
    local file = fs.open("todolist", "w")
    file.write(textutils.serialize(todo))
    file.close()
end

function displayPage(p)
    textCol(colors.white)
    term.setCursorPos(1, 2)
    for i = (1 + (p - 1) * line), (p * line) do
        if todo[i] ~= nil then
            local status = "Not Completed"
            if todo[i].completed then
                status = "Completed"
            end
            if todo[i].inProgress then
                status = "In Progress"
            end
            textCol(colors.white)
            term.write("[" .. status .. "] ")
            textCol(colors.gray)
            print(" " .. todo[i].text)
        end
    end
end

function printButtons()
    local buttonY = height - 1

    -- Add Item Button
    term.setCursorPos(2, buttonY)
    textCol(colors.green)
    term.write("Add Item")

    -- Remove Completed Button
    term.setCursorPos(15, buttonY)
    textCol(colors.red)
    term.write("Remove Completed")

    -- Cycle Page Button
    term.setCursorPos(width - 11, buttonY)
    textCol(colors.yellow)
    term.write("Cycle Page")
end

function addItem()
    term.clear()
    term.setCursorPos(2, 2)
    print("Please enter a new item:")
    local input = read()
    local newItem = {text = input, completed = false, inProgress = false}

    table.insert(todo, 1, newItem)
    saveTODO()

    term.clear()
    term.setCursorPos(2, 2)
    textCol(colors.white)
    print("Thanks! Item added.")
    os.sleep(2)
end

function removeCompletedTasks()
    local i = 1
    while i <= #todo do
        if todo[i].completed then
            table.remove(todo, i)
        else
            i = i + 1
        end
    end
    saveTODO()
end

-- Initialize todo list
local todo = {}
openTODO()

-- Initial printing
term.clear()
printButtons()
displayPage(1)

while true do
    local event, but, x, y

    if mon == term.native() then
        event, but, x, y = os.pullEvent("mouse_click")
    else
        event, _, x, y = os.pullEvent("monitor_touch")
    end

    if y == height - 1 then
        if x <= 13 then
            addItem()
        elseif x >= 15 and x <= 30 then
            removeCompletedTasks()
        elseif x >= width - 11 then
            if currentPage >= #todo / line then
                currentPage = 1
            else
                currentPage = currentPage + 1
            end
        end
    elseif y >= 2 and y <= height - 3 then
        local itm = (currentPage - 1) * line + y - 1
        if todo[itm] ~= nil then
            todo[itm].completed = not todo[itm].completed
            todo[itm].inProgress = false
            saveTODO()
        end
    end

    term.clear()
    printButtons()
    term.setCursorPos(1, 1)
    displayPage(currentPage)
end
