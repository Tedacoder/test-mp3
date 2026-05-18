-- Shared utilities
Utils = {}

function Utils.DumpTable(table)
    return json.encode(table, {indent = true})
end
