fx_version 'cerulean'
game 'gta5'

author 'Jules'
description 'Vehicle Inspection System integrating Mechanics and Police.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.json'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@ox_mysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_mysql',
    'ox_target'
}
