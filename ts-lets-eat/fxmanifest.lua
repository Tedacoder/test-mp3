fx_version 'cerulean'
game 'gta5'

description 'Advanced Food Preparation & Cooking System'
version '1.0.0'

shared_script '@ox_lib/init.lua'

shared_scripts {
    'shared/config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/nightclub.css'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'
