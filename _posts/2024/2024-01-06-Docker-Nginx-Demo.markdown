---
categories: docker nginx
---
## Start Nginx on Docker
To run Nginx on Docker:
```
docker run --name nginx -p 80:80 -d nginx
```

To restart
```
docker start -a nginx &
```

Check if the docker instance working
```
http://localhost/
```


![Nginx on Browser](/images/2024-01-06/nginx.png)

## Hello World
Login to shell
```
docker exec -it nginx /bin/bash 
```
Nginx docker image doesn't include `vi` so I needed to install it (technically, below install `vim`).

```
apt update && apt install -y vim
```

Create index.html
``` html
cd /usr/share/nginx/html
vi index2.html
```
The content of `index2.html` file might be something like this.
```html

<!DOCTYPE html>
<html>
<head>
  <title>Hello World</title>
</head>
<body>
  <h1>Hello World!</h1>
</body>
</html>
```

On the browser, access to `http://localhost/index2.html`.

![Hello World HTML file](/images/2024-01-06/helloworld.png)

## Reverse Proxy
To use Nginx for the development environment for the [Sump Data Project](https://github.com/ntamagawa/sumpdata), Nginx is configured as a reverse proxy server.

/etc/nginx/conf.d/default.conf
```conf
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    # Swagger is accessed via /swagger url. 
    location /swagger {
	proxy_pass http://host.docker.internal:8080/swagger-ui;
	index index.html;
	proxy_redirect off;
    }

    # This is also for Swagger that requires /v3/... url
    location /v3 {
        proxy_pass http://host.docker.internal:8080/v3;
	proxy_redirect off;
    }

    # This is the sump data endpoint.
    location /devices {
        proxy_pass http://host.docker.internal:8080/devices;
	proxy_redirect off;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```

After editing the conf file, to test
``` bash
$ nginx -t
```
To reload the conf file
``` bash
nginx -s reload
```

### Adding Streamlit
[Streamlit](https://streamlit.io) is a frontend web application to visualize data. For my project, I'm using it to draw a chart for the sump water level. 

I originally just set up the same way as sump data API endpoint. Not that the port 8501 is the Streamlit app port (locally, it can be accessed http://localhost:8501).
```
    location / {
        proxy_pass http://host.docker.internal:8501/;
        proxy_redirect off;
    }
```
Unfortunately, this doesn't work. The reason is Streamlit uses WebSocket under `_stcore` folder. To properly configure the reverse proxy, and HTTP Upgrade needs to be set.
```
    location /_stcore {
        proxy_pass http://host.docker.internal:8501/_stcore;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
```

Reference: [NGINX as a WebSocket Proxy](https://www.nginx.com/blog/websocket-nginx/)



