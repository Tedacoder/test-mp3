fx_version 'cerulean'
game 'gta5'

author 'Jules'
description 'Vehicle Inspection System integrating Mechanics and Police.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/items.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/items.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
}

files {
    'locales/*.json'
}
