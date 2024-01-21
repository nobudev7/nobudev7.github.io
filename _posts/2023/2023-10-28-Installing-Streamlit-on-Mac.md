---
categories: python streamlit
---

## Python
``` shell
$ brew install python3
$ python3 --version
Python 3.9.6
$ python3 -m pip install --upgrade pip
$ pip3 -V
pip 23.2.1 from /opt/homebrew/lib/python3.11/site-packages/pip (python 3.11)
```

## Venv

``` shell
$ python3 -m venv venv
$ source venv/bin/activate
(venv) $ pip -V
pip 21.2.4 from /Users/nobu/Playground/st-app/venv/lib/python3.9/site-packages/pip (python 3.9)
(venv) $ python3 -m pip install --upgrade pip
(venv) $ pip -V                              
pip 23.3.1 from /Users/nobu/Playground/st-app/venv/lib/python3.9/site-packages/pip (python 3.9)
(venv) $ deactivate
$  pip -V    
zsh: command not found: pip
$ pip3 -V
pip 23.2.1 from /opt/homebrew/lib/python3.11/site-packages/pip (python 3.11)
```

## Install Streamlit

``` shell
(venv) $ pip install streamlit
```

## App

`app.py`
``` python
import streamlit as st

st.title('Title of the app')
st.header('The App!')
st.subheader('The future of SumpPump')
```

## Run the app
``` shell
(venv) $ streamlit run app.py 
  You can now view your Streamlit app in your browser.

  Local URL: http://localhost:8501
  Network URL: http://192.168.1.169:8501
```

![Streamlit app](/images/2023-10-28/apptitle.png)
