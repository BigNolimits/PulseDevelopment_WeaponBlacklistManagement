fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'SecretEnemy'
description 'Blacklist management for weapons'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Required for MySQL functions
    'server.lua'
}
