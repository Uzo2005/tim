# A super fast template engine for cool kids
#
# (c) 2024 George Lemon | LGPL License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/tim

import ../meta, ../ast, ../logging
export meta, ast, logging

type
  TimCompiler* = object of RootObj
    ast*: Ast
    tpl*: TimTemplate
    engine*: TimEngine
    nl*: string = "\n"
    output*, jsOutput*, jsonOutput*,
      yamlOutput*, cssOutput*: string
    start*, isClientSide*: bool
    case tplType*: TimTemplateType
    of ttLayout:
      head*: string
    else: discard
    logger*: Logger
    indent*: int = 2
    partialIndent* : int = 0
    minify*, hasErrors*: bool
    stickytail*: bool
      # when `false` inserts a `\n` char
      # before closing the HTML element tag.
      # Does not apply to `textarea`, `button` and other
      # self closing tags (such as `submit`, `img` and so on)