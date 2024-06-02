---
layout: post
categories: nginx
---
## Restricting Access with HTTP Basic Authentication

Project: [Sump Data](https://github.com/nobudev7/sumpdata)

While I was on vacation, I noticed that [the sump chart](https://sumpdata.nobudev7.com) suddenly stopped updating. Since I didn't have my laptop with me, I couldn't check much from my iPhone.

The reason why was because the IP address of my home route changed. I knew it would happen, but didn't think too much. Now I need to update [the Nginx config I set up](http://www.nobudev7.com/github/2024/01/16/AWS-Lightsail.html#12-configure-nginx-to-access-applications) to use different access restriction other than IP address.

Following up on [this Nginx page](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/), I set up exactly the page instruct for my AWS Linux.

### Installing httpd-tools
Since AWS Linux doesn't have `htpasswd` by default, installed `httpd-tools` first.

```bash
sudo yum update
sudo yum install httpd-tools
```

### Creating a Password File
Then, created a password file. The folder I used is different from what the Nginx page tells, and I specify the absolute path to the password file later in the config.

```bash
cd /etc/nginx/conf.d
sudo htpasswd -c htpasswd apiuser
vi sumpdata.conf # This is my conf file for the Nginx server
```

Nginx config file look like this.
```conf
    location /api {
        proxy_pass http://localhost:8080/api;
        proxy_redirect off;
        #allow 123.xx.xx.xx; # Old ip based restriction

        auth_basic "API access required";
        auth_basic_user_file /etc/nginx/conf.d/htpasswd;

    }
```

Test the conf and reload.
```
nginx -t
nginx -s reload
```

Now, to upload the data from Sump Pump, I updated the `curl` command with the user and password. You'd put user/pass to environment variable, perhaps.

```bash
curl -u 'apiuser:password' -s -X POST -H 'Content-Type: text/plain' "https://sumpdata.nobudev7.com/apiendpoint/device/number/entries?params..."
```


