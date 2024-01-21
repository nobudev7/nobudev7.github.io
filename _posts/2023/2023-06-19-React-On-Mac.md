---
title: Set up React on Mac
categories: react
---
## Install Node.js

Check `brew` version.
```console
$ brew -v
Homebrew 4.0.23
```

## Install nodebrew
Following this post, I decided to install nodebrew. I won't be an active frontend developer, but this might help in the future to switch or maintain versions of `npm` as described.
[https://fromscratch-y.work/en/blog/programming/mac-nodejs-install/#sec4-1](https://fromscratch-y.work/en/blog/programming/mac-nodejs-install/#sec4-1)

```console
$ brew install nodebrew
(...snip...)
==> Caveats
You need to manually run setup_dirs to create directories required by nodebrew:
  /opt/homebrew/opt/nodebrew/bin/nodebrew setup_dirs

Add path:
  export PATH=$HOME/.nodebrew/current/bin:$PATH

To use Homebrew's directories rather than ~/.nodebrew add to your profile:
  export NODEBREW_ROOT=/opt/homebrew/var/nodebrew

zsh completions have been installed to:
  /opt/homebrew/share/zsh/site-functions
==> Summary
🍺  /opt/homebrew/Cellar/nodebrew/1.2.0: 8 files, 40.6KB

(...snip...)
```

Not sure what the `setup_dirs` does...

Added the PATH to my `.zshrc`
```console
$ echo 'export PATH=$HOME/.nodebrew/current/bin:$PATH' >> ~/.zshrc 
$ source ~/.zshrc 
```

## Specify the node version
```console
$ nodebrew ls-remote
v0.0.1    v0.0.2    v0.0.3    v0.0.4    v0.0.5    v0.0.6    

v0.1.0    v0.1.1    v0.1.2    v0.1.3    v0.1.4    v0.1.5    v0.1.6    v0.1.7
(...snip...)

v20.0.0   v20.1.0   v20.2.0   v20.3.0   
(...snip...)

io@v3.0.0 io@v3.1.0 io@v3.2.0 io@v3.3.0 io@v3.3.1 
```

Install the stable version
```console
$ nodebrew install stable
$ nodebrew list
v20.3.0
```

Activate the installed version
```console
$ nodebrew use v20.3.0
use v20.3.0
$ node -v
v20.3.0
$ npm -v
9.6.7
```

## Create an app
```console
$ npx create-react-app react-app
```
According to this page https://react.dev/learn/start-a-new-react-project, that creates [Next.js](https://nextjs.org) project.

To run, go down to the created project folder, and start `npm`.
```console
$ cd react-app
$ npm start
```

This automatically opens `http://localhost:3000` with your default browser and show the starter page.

![React Starter Page](/images/2023-06-19/react.png)

Further more, below comment will create a `build` folder for deployment.
```console
$  npm run build
```
Source: [https://create-react-app.dev/docs/deployment/](https://create-react-app.dev/docs/deployment/) 

My plan it to run a server using Spring Boot.


## Why React?
As a Java backend developer, I need to work with frontend developers. Also wanted to set up a simple website based on Java backend, and picked React as the FE framework - simply because it's most trending framework on the FE side. 

