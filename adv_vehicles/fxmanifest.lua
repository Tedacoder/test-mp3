fx_version 'cerulean'
game 'gta5'

description 'Advanced Vehicles & Dealership System'
version '1.0.0'
author 'Jules'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/operation.lua',
    'client/framework.lua',
    'client/parking.lua',
    'client/keys.lua',
    'client/hotwire.lua',
    'client/garage.lua',
    'client/dealership.lua',
    'client/repo.lua',
    'client/admin.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/parking.lua',
    'server/keys.lua',
    'server/garage.lua',
    'server/impound.lua',
    'server/dealership.lua',
    'server/repo.lua',
    'server/admin.lua'
}

ui_page 'html/hotwire.html'

files {
    'html/hotwire.html',
    'html/hotwire.css',
    'html/hotwire.js',
    'html/garage.html',
    'html/garage.css',
    'html/garage.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'oxmysql'
}
