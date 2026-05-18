fx_version 'cerulean'
game 'gta5'

author 'Jules'
description 'Tha Crack Era - Advanced Telecommunications System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'bridge/framework/*.lua',
    'bridge/inventory/*.lua',
    'bridge/target/*.lua'
}

client_scripts {
    'client/core.lua',
    'client/hardware.lua',
    'client/camera.lua',
    'client/target.lua',
    'client/infrastructure.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/db.lua',
    'server/items.lua',
    'server/billing.lua',
    'server/apps/*.lua',
    'server/infrastructure.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/js/**/*.js',
    'html/assets/**/*',
    'shared/locales.json'
}
