---
categories: java
---

Various findings that would help me later.
## java: cannot find symbol error
For example `List#getFirst` method is a default method of the interface that is implemented since version 21. This doesn't compile well in IntelliJ with default settings.

To make the project allow compiling in Java 21, uncheck the `--release` option, as the binary won't be compatible with older Java.

![Uncheck release option](/images/2023-10-31/intellij.png)
