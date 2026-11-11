---
title: "Journal Memo: Streamlit Prototyping on macOS and the Homebrew Python Gotcha"
categories: python streamlit
tags: [python, streamlit, mac]
---

A quick development journal memo capturing my setup steps for prototyping an early Sump Pump telemetry dashboard using [Streamlit](https://streamlit.io/), along with a subtle macOS Python environment gotcha worth remembering.

## Python Setup and the macOS PATH Gotcha

On macOS Apple Silicon, installing Python via Homebrew puts the binary in `/opt/homebrew/bin/python3`. However, if your shell `$PATH` has `/usr/bin` evaluated first or lacks the Homebrew prefix, running `python3` defaults to Apple's Xcode Command Line Tools version rather than Homebrew.

Here is what happened during my initial setup:

```shell
$ brew install python3
$ python3 --version
Python 3.9.6
$ pip3 -V
pip 23.2.1 from /opt/homebrew/lib/python3.11/site-packages/pip (python 3.11)
```

Notice the discrepancy: `python3` pointed to the macOS system Python (`3.9.6`), while `pip3` pointed to Homebrew's Python (`3.11`).

## Virtual Environment (venv)

When creating the virtual environment with `python3 -m venv venv`, it inherited the `3.9` runtime from the system binary:

```shell
$ python3 -m venv venv
$ source venv/bin/activate
(venv) $ pip -V
pip 21.2.4 from /Users/nobu/Playground/st-app/venv/lib/python3.9/site-packages/pip (python 3.9)
(venv) $ python3 -m pip install --upgrade pip
(venv) $ pip -V
pip 23.3.1 from /Users/nobu/Playground/st-app/venv/lib/python3.9/site-packages/pip (python 3.9)
```

> **Takeaway:** Ensure `/opt/homebrew/bin` precedes `/usr/bin` in `~/.zshrc` when intending to use the Homebrew Python runtime for new virtual environments.

## Installing Streamlit

Inside the activated virtual environment:

```shell
(venv) $ pip install streamlit
```

## Prototyping the App

To test Streamlit's reactive rendering for future Sump Pump metrics, I created a minimal test script `app.py`:

```python
import streamlit as st

st.title('Title of the app')
st.header('The App!')
st.subheader('The future of SumpPump')
```

## Running the App

```shell
(venv) $ streamlit run app.py
  You can now view your Streamlit app in your browser.

  Local URL: http://localhost:8501
  Network URL: http://192.168.1.169:8501
```

Streamlit spun up the local server immediately on port 8501:

![Streamlit app](/images/2023-10-28/apptitle.png)

This quick test confirmed that Streamlit is a fast and lightweight candidate for building internal telemetry dashboards without the overhead of a dedicated frontend framework.
