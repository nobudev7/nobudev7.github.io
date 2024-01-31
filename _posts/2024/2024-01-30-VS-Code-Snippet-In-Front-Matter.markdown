---
layout: post
categories: VSCode
---

I just wanted to run a user snippet on VS Code when writing a post (like this one!) in front matter, so that I can insert the current time easily. The goal is something like below.

```yaml
# Type "update" and get the curren time inserted
modified_date: 2024-01-30T21:37:32.000-05:00
```

![frontmattersnippet](/images/2024-01-30/frontmattersnippet.gif)

There are a lot of blog posts and stackoverflow questions (and answers) for how to create a snippet, but no single post explains exactly how - so I'm writing exactly that here.

## 1. Enable "Quick Suggestion" in markdown files.
Many people point out that, somehow, snippet (aka Quick Suggestion) is not enable for markdown by default. For that, you need to add the following section in `settings.json` file.
```json
    "[markdown]": {
        "editor.quickSuggestions": {
          "other": true,
          "comments": true,
          "strings": true
        }
      }
```

## 2. Write user snippet for YAML
 The most common suggestion to create a snippet for **markdown**, but none of such suggestion worked in _front matter_. 

The solution is to create a user snippet for **YAML**, not for markdown. The configuration file is `yaml.json`. After finding this out, it somehow makes sense. Front matter _is_ a YAML formatted section, which happens to reside in a markdown file after all. 

```json
    "currentdate": {
        "prefix": "update",
        "body": [
            "modified_date: $CURRENT_YEAR-$CURRENT_MONTH-${CURRENT_DATE}T$CURRENT_HOUR:$CURRENT_MINUTE:$CURRENT_SECOND.000-05:00"
        ],
        "description": "Add Current date & time"
    }
```

With the above snippet in the correct yaml.json, it works within the front matter.
