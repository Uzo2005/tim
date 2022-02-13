# ⚡️ High-performance compiled
# template engine inspired by Emmet syntax.
# 
# MIT License
# Copyright (c) 2022 George Lemon from OpenPeep
# https://github.com/openpeep/tim

import tim/[parser, compiler]
from std/times import cpuTime

export parser, compiler

when isMainModule:
    let time = cpuTime()
    var p: Parser = parse(readFile("sample.timl"))
    if p.hasError():
        # Catch errors collected while parsing
        echo p.getError()
    else:
        # Returns the a stringified JSON representing the
        # Abstract Syntax Tree of the current timl document
        echo p.getStatements()

        # Otherwise compile timl document to html
        Compiler.init(parser = p)

        echo "✨ Done in " & $(cpuTime() - time)