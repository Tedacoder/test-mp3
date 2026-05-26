fx_version 'cerulean'
game 'gta5'

description 'Advanced Admin Panel'
version '1.0.0'

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

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'oxmysql',
    'ox_lib'
}
