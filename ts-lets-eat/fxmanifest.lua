fx_version 'cerulean'
game 'gta5'

description 'Advanced Food Preparation & Cooking System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'
