---
layout: post
title:  "Set up Jekyll Locally on Mac"
date:   2024-01-20 21:35:35 -0500
categories: github
---
As I leave DEV.to due to its bug, I decided to move to GitHub Pages with Jekyll. There are a few pages that explains how to do it, however, all of them fall short for me. On this post, I'll show what I have done for local Mac installation.

## Installing Jekyll
For the most part, following the official installation steps worked.
[Jekyll MacOS Installation](https://jekyllrb.com/docs/installation/macos/)

```bash
brew install chruby ruby-install xz
ruby-install ruby 3.1.3
ruby -v
gem install jekyll
```

Now, as the official site suggest, edit `.zshrc` and add the following section.
```bash
# For Jekyll
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.1.3
```
Now, here's the important step. Instaed of doing `source ~/.zshrc`, do open a new terminal window. I assumed `source` would do the job, but it didn't.

After opening a new terminal, continue the following.
```bash
jekyll new --skip-bundle .
```
However, in my case, because I already had a `README.md` file, `--force` was needed.
```bash
jekyll new --skip-bundle --force .
```

That create the initial, scaffolding files. Following the GitHub instruction, update the `Gemfile`. However, I needed add a few lines for remote theme, and also running the local server.
```conf
# "jekyll", "~> 4.3.3" # Comment out this line
(...)
gem "github-pages", "~> 228", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
  gem "jekyll-remote-theme" # This is necessary for changing theme to remote theme
end

gem "webrick", "~> 1.8" # This is required to run Jekyll locally.

```

After updating the gem file, run this.
```bash
bundle install
```
This should install all the gems needed.

To run the server locally,
```bash
bundle exec jekyll serve
```

Access the site at `http://127.0.0.1:4000`

## Configuring Jekyll
Contrary to my expectation, Jekyll is not a simple web page template which the theme can be changed without affecting content. Rather, it's a framework that you need to adjust content, "front matter" in particular, according to the theme.

The default theme _minima_ would work fine with the sample post created in above steps. However, as soon as I changed the theme, the whole site stopped working. Below is my memo in each step to solve the issue (not comprehensive).

#### Layout
Each post likely has a section called "Front Matter", which is a meta data for the post. One important value is the `layout`. The sample post specifies it as a `post`, like below.
```yml
---
layout: post
title:  "Welcome to Jekyll!"
date:   2024-01-20 17:35:35 -0500
categories: jekyll update
---
```
This implicitly references `_layouts/post.html` as a template, however, the file doesn't exist, and I suppose that's somehow referenced by the framework and its theme `minima` by default. 
Now, I changed the theme to `cayman` which is a GitHub supported _remote_ theme. As soon as I did, the whole site stopped working. In fact, there are 3 layout files missing.

The reason can be revealed by starting the server with `--verbose` option.
```bash
$ bundle exec jekyll serve --verbose
(...)
  Rendering Layout: _posts/2024-01-20-welcome-to-jekyll.markdown
     Build Warning: Layout 'post' requested in _posts/2024-01-20-welcome-to-jekyll.markdown does not exist.
(...)
     Build Warning: Layout 'page' requested in about.markdown does not exist.
(...)
     Build Warning: Layout 'home' requested in index.markdown does not exist.
```
The solution is to place those files under `_layouts` folder, _or_ change the `layout` in the post itself to something that exist. A simple way I took was to copy those files from the theme's repo.

[Cayman theme default.html](https://github.com/pages-themes/cayman/blob/master/_layouts/default.html) 
[Minima Theme Layouts](https://github.com/jekyll/minima/tree/master/_layouts)

What I see a problem of Jekyll is that, because the content file specifies the layout template, and each theme name layout file differently, it is harder to maintain the integrity, and quite frankly, it failed to be a good web framework as the markdown, or its front matter, is not portable between themes. However, Jekyll is the default action for GitHub Pages, and I'll adapt to it.

#### References
[Jekyll remote theme doesn't work locally](https://stackoverflow.com/questions/48728510/jekyll-remote-theme-doesnt-work-locally)
[Using Jekyll for Website without Blog](https://stackoverflow.com/questions/30837079/using-jekyll-for-website-without-blog)
[GitHub Pages](https://www.markdownguide.org/tools/github-pages/) List of Markdown element support
