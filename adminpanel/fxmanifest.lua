fx_version 'cerulean'
game 'gta5'

description 'Advanced Admin Panel'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'sh_garage_bridge.lua',
    'sh_medical_bridge.lua',
    'sh_spectate.lua'
}

client_scripts {
    'client.lua',
    'cl_avatars.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/backdrop.jpg'
}

dependencies {
    'ox_inventory',
    'oxmysql',
    'ox_lib'
}
