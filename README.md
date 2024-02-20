<p align="center">
  <img src="https://raw.githubusercontent.com/openpeeps/tim/main/.github/timengine.png" alt="Tim - Template Engine" width="200px" height="200px"><br>
  ⚡️ A high-performance template engine & markup language<br>
  <strong>Fast</strong> • <strong>Compiled</strong> • Written in Nim language 👑
</p>

<p align="center">
  <code>nimble install tim</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/tim/">API reference</a><br><br>
  <img src="https://github.com/openpeeps/tim/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeeps/tim/workflows/docs/badge.svg" alt="Github Actions">
</p>


## 😍 Key Features
or more like a _todo list_
- Fast & easy to code!
- Cross-platform and multi-threaded
- Caching and Pre-compilation
- JIT Rendering 
- Output Minifier
- Transpiles to **JavaScript** for **Client-Side Rendering**
- Supports embeddable code `json`, `js`, `yaml`, `css`
- Available as a **Nimble library** for **Nim development**
- Built-in **Browser Sync & Reload**
- Built-in real-time Server-Side Rendering `SSR` via `ZeroMQ`
- Source-to-Source translator (transpiles to `JavaScript`, `Ruby`, `Python` and more)
- Written in Nim language 👑

## Quick Example
```timl
div.container > div.row > div.col-lg-7.mx-auto
  h1.display-3.fw-bold: "Tim is Awesome"
  a href="https://github.com/openpeeps/tim" title="This is hot!": "Check Tim on GitHub"
```

## Tim in action
Check [/example](https://github.com/openpeeps/tim/tree/main/example) folder to better understand Tim's structure. [Also check the generated HTML file](https://htmlpreview.github.io/?https://raw.githubusercontent.com/openpeeps/tim/main/example/preview.html) 

### Client-Side Rendering
Tim Engine seamlessly shifts rendering to the client side for dynamic interactions, using the intuitive `@client` block statement.

```timl
body
  section#contact > div.container
    div.row > div.col-12 > h3.fw-bold: "Leave a message"
    div#commentForm

@client target="#commentForm"
  form method="POST" action="/submitComment"
    div.form-floating
      input.form-control type="text" name="username"
        placeholder="Your name" autocomplete="off" required=""
      label: "Your name"

    div.form-floating.my-3
      textarea.form-control name="message" style="height: 140px" required="": "Your message"
      label: "Your message"
    div.text-center > button.btn.btn-dark.px-4.rounded-pill type="submit": "Submit your message"
@end
```

## Browser Sync & Reload
Compile your project with `-d:timHotCode` flag, then connect to Tim's WebSocket server to auto reload the page when there's changes on disk
Note that this feature is not available when compiling with `-d:release`.
```js
  {
    const watchout = new WebSocket('ws://127.0.0.1:6502/ws');
    watchout.addEventListener('message', () => location.reload());
  }
```

### Data
Tim provides 3 types of data storages. **Global** and **Local** as JsonNode objects for handling immutable data from the app to your `timl` templates,
and **Template** based data at template level using Tim's built-in AST-based interpreter.

Global data can be passed at precompile-time and is made available globally for all layouts, views and partials. 
```nim
timl.precompile(
  global = %*{
    "year": parseInt(now().format("yyyy"))
  }
)
```

Accessing global data can be done using the `$app` constant:
```timl
footer > div.container > div.row > div.col-12
  small: "&copy; " & $app.year & " &mdash; Made by Humans from OpenPeeps"
```

Local data can be passed to a template from using the route callback (controller).
`$this` constant can be used to access data from local storage.

```nim
timl.render("index", local = %*{
  isLoggedin: true,
  username: "Johnny Boy"
})
```

```timl
if $this.isLoggeding:
  h1.fw-bold: "Hello, " & $this.username
  a href="/logout": "Log out"
else:
  h1: "Hello!"
  a href="/login": "Please login to view this page"
```

Template variables can be declared inside templates using `var` or `const`. The only difference
between these two is that constants are immutable and requires initialization.

The scope of a declared variable is limited to the branch in which it was declared.

```timl
var a = 1       // a global variable
if $a == 1:
  var b = 2     // a block-scoped variable
  echo $a + b   // prints 3
echo $b         // error, undeclared variable
```

#### Debug
For debug reasons you can use `echo` to print data
```
echo "Hello, World!"
```

#### Data types
Supported datatypes: `string`, `int`, `float`, `bool`, `array`, `object`

```
var a = "Hello"
var b = 10
var c = 10.5 
var d = true    // false

var e = []      // init an empty array
var f = {}      // init an empty object
```

#### Function
_todo_

#### Conditionals
_todo_

#### For loop
```timl
var boxes = [
  {
    title: "Chimney Sweep"
    description: "Once feared for the soot they carried,
      these skilled climbers cleaned fireplaces to prevent
      fires and improve indoor air quality" 
  }
  {
    title: "Town Crier",
    description: "With booming voices and ringing bells,
      they delivered news and announcements in the days
      before mass media"
  }
  {
    title: "Ratcatcher",
    description: "These pest controllers faced smelly
      challenges, but their work helped prevent the
      spread of diseases like the plague"
  }
]

div.container > div.row.mb-3
  div > col-12 > h3.fw-bold: "Forgotten Professions"
  for $box in $boxes:
    div.col-lg-4 > div.card > div.card-body
      div.card-title.fw-bold.h4: $box.title
      p.card-text: $box.description
```

### Escaping
_todo_

## Embed Code
Tim integrates a variety of embeddable code formats, including: **JavaScript**, **YAML**/**JSON** and **CSS**

### JavaScript block

```timl
@js
  document.addEventListener('DOMContentLoaded', function() {
    console.log("Hello, hello, hello!")
  });
@end
```

### JSON block
_todo_

### YAML block
_todo_

#### CSS
_todo_



### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/tim/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/tim/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)
- 🥰 [Donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
Tim Engine | `LGPLv3` license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; 2024 OpenPeeps & Contributors &mdash; All rights reserved.
