fx_version 'cerulean'
game 'gta5'

lua54 'yes'

client_scripts {
    'config.lua',
    'client/*.lua',

}

server_scripts {
    'config.lua',
    'server/*.lua',
}


ui_page {'html/index.html'}
files {
    "html/index.html",
    "html/listener.js",
    "html/style/*.css",

    "html/sounds/alerted.mp3",
    "html/healthbar.png",
}



escrow_ignore {
    'client/utils.lua',
    'server/routing.lua',
    'server/main.lua',
    'config.lua',

  }