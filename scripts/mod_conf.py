with open('/etc/shiny-server/shiny-server.conf','r') as shiny_conf:
    lines = shiny_conf.readlines()
with open('/etc/shiny-server/shiny-server.conf','w') as shiny_conf:
    for line in lines:
        if 'location /' in line:
            shiny_conf.write('location / {\napp_init_timeout 250;\n')
        else:
            shiny_conf.write(line)
            
            
