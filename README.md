<p align="center">
    <img src="https://raw.githubusercontent.com/openpeep/tim/main/.github/tim.png" width="140px"><br>
    ⚡️ A high-performance compiled template engine inspired by Emmet syntax.<br>
    <strong>Fast</strong> • <strong>Compiled</strong> • Written in Nim language 👑
</p>

_Work in progress_

## 😍 Key Features
- [x] Emmet-syntax 🤓
- [x] Multi-threading | Low memory foot-print 🍃
- [x] Tim as **Nimble library** for Nim programming 👑
- [x] SVG Support
- [ ] Tim as a Native NodeJS addon
- [ ] `layouts`, `views` and `partials` logic
- [ ] Variable Assignment
- [ ] `for` Loops & Iterations
- [ ] `if`, `elif`, `else` Conditional Statements
- [ ] `JSON` AST Generator
- [ ] Just-in-time Computation
- [ ] SEO Optimizer
- [ ] Language Extension `.timl` 😎
- [x] Lexer based on [Toktok library](https://github.com/openpeep/toktok)
- [x] Open Source | `MIT` License

## Installing
```
nimble install tim
```

## Examples
In most examples we'll use Bootstrap.

1. Create a `<head>` with `meta`, `title` and other things.
```tim
html
    head
        meta charset="UTF-8"
        title: "My Awesome App"
        link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/css/bootstrap.min.css"
        link rel="stylesheet" href="/assets/app.css"
```

P.S. There is no need for `<!DOCTYPE html>`, this is auto-inserted by Tim Engine for each `layout` inside `layouts` directory 👍

2. Create a simple hero-like section.
```tim
div.container > div.row.vh-100.align-items-center > div.col-8.mx-auto.text-center
    h1.display-2.fw-bold: "Tim Engine is Awesome"
    p.display-5: "⚡️ A high-performance compiled template engine inspired by Emmet syntax"
```

3. Working with `partials` is easy! This is how you can include `.timl` partials inside your `views`.
_TODO Support named includes for partials_
```tim
div.container > div.row
    @include "../partials/products/topbar"
```

4. SVG is cool, here is how you can create a pulse-like SVG icon for your button.
```tim
a.btn.btn-dark.px-4
    svg viewBox="0 0 24 24" width="24" height="24" stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"
        polyline points="22 12 18 12 15 21 9 3 6 12 2 12"
    span: "Update now"
```

# Code Syntax
<details>
    <summary>Sublime Text 4</summary>

```yaml
%YAML 1.2
---
# See http://www.sublimetext.com/docs/syntax.html
file_extensions:
  - timl
scope: source.timl
variables:
  ident: '[A-Za-z_][A-Za-z_0-9]*'
contexts:
  main:
    # Strings begin and end with quotes, and use backslashes as an escape
    # character
    - match: '"'
      scope: punctuation.definition.string.begin.timl
      push: double_quoted_string

    # Tim Engine allows single-line comments starting with `#` to end of line
    - match: '#'
      scope: punctuation.definition.comment.timl
      push: line_comment

    - match: '\|'
      scope: markup.bold keyword.operator.logical

    - match: '\*'
      scope: entity.name.tag

    - match: '>'
      scope: punctuation

    - match: ':'
      scope: markup.bold variable.language

    - match: '='
      scope: markup.bold keyword.operator.assignment.timl

    - match: '\b(html|head|meta|link|script|main|section|article|aside|div)\b'
      scope: entity.name.tag.timl

    - match: '\b(h1|h2|h3|h4|h5|h6|a|p|em|b|strong|span)\b'
      scope: entity.name.type.timl

    - match: '\b(-)?[0-9.]+\b'
      scope: constant.numeric.timl

    - match: '\b{{ident}}\b'
      scope: punctuation.definition

  double_quoted_string:
    - meta_scope: string.quoted.double.timl
    - match: '\\.'
      scope: constant.character.escape.timl
    - match: '"'
      scope: punctuation.definition.string.end.timl
      pop: true

  line_comment:
    - meta_scope: comment.line.timl
    - match: $
      pop: true
```

</details>

## Roadmap

### `0.1.0`
- [x] Lexer, Parser, AST, Compiler
- [x] Create Sublime Syntax
- [ ] Create VSCode Syntax (yak)
- [ ] Add tests
- [ ] Talk about it on ycombinator / stackoverflow / producthunt

### ❤ Contributions
If you like this project you can contribute to Tim project by opening new issues, fixing bugs, contribute with code, ideas and you can even [donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C) 🥰

### 👑 Discover Nim language
<strong>What's Nim?</strong> Nim is a statically typed compiled systems programming language. It combines successful concepts from mature languages like Python, Ada and Modula. [Find out more about Nim language](https://nim-lang.org/)

<strong>Why Nim?</strong> Performance, fast compilation and C-like freedom. We want to keep code clean, readable, concise, and close to our intention. Also a very good language to learn in 2022.

### 🎩 License
Illustration of Tim Berners-Lee [made by Kagan McLeod](https://www.kaganmcleod.com).<br><br>
This is an Open Source Software released under `MIT` license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2022 OpenPeep & Contributors &mdash; All rights reserved.

<a href="https://hetzner.cloud/?ref=Hm0mYGM9NxZ4"><img src="https://openpeep.ro/banners/openpeep-footer.png" width="100%"></a>
