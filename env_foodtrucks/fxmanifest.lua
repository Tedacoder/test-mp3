fx_version 'cerulean'
game 'gta5'

author 'AI Code Agent'
description 'env_foodtrucks rewritten script'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'ox_target'
}