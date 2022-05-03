# 
# High-performance, compiled template engine inspired by Emmet syntax.
# 
# Tim Engine can be used as a Nim library via Nimble,
# or as a binary application for integrating Tim Engine with
# other apps and programming languages.
# 
# MIT License
# Copyright (c) 2022 George Lemon from OpenPeep
# https://github.com/openpeep/tim

import std/[json, jsonutils, tables, with]
import ./tokens, ./lexer, ./ast, ./interpreter

from ./meta import TimEngine, TimlTemplate, getContents, getFileData

import ../utils
import ./utils/parseutils

from std/strutils import `%`, isDigit, join

type
    Parser* = object
        lexer: Lexer
        prev, current, next: TokenTuple
        error: string
        statements: seq[Node]
        prevln, currln, nextln: int
        prevlnEndWithContent: bool
        parentNode, prevParentNode, prevNode, subNode: HtmlNode
        interpreter*: Interpreter
        enableJit: bool

proc setError[T: Parser](p: var T, msg: string) =
    p.error = "Error ($2:$3): $1" % [msg, $p.current.line, $p.current.col]

proc hasError*[T: Parser](p: var T): bool =
    result = p.error.len != 0 or p.lexer.error.len != 0

proc getError*[T: Parser](p: var T): string = 
    if p.error.len != 0:
        result = p.error
    elif p.lexer.error.len != 0:
        result = p.lexer.error

proc hasJIT*[T: Parser](p: var T): bool {.inline.} =
    ## Determine if current timl template requires a JIT compilation
    result = p.enableJit == true

proc jump[T: Parser](p: var T, offset = 1) =
    var i = 0
    while offset > i: 
        p.prev = p.current
        p.current = p.next
        p.next = p.lexer.getToken()
        inc i

proc isElement(): bool =
    ## Determine if current token is a HTML Element
    ## TODO
    discard

proc isAttributeOrText(token: TokenTuple): bool =
    ## Determine if current token is an attribute name based on its siblings.
    result = token.kind in {TK_ATTR_CLASS, TK_ATTR_ID, TK_IDENTIFIER, TK_COLON}

proc isInline[T: TokenTuple](token: T): bool =
    ## Determine if current token is an inliner HTML Node
    ## such as TK_SPAN, TK_EM, TK_I, TK_STRONG TK_LINK and so on.
    ## TODO
    discard

proc hasID[T: HtmlNode](node: T): bool {.inline.} =
    ## Determine if current HtmlNode has an ID attribute
    result = node.id != nil

proc getID[T: HtmlNode](node: T): string {.inline.} =
    ## Retrieve the HTML ID attribute, if any
    result = if node.id != nil: node.id.value else: ""

proc toJsonStr*(nodes: HtmlNode) =
    ## Print a stringified representation of the current Abstract Syntax Tree
    echo pretty(toJson(nodes))

proc nindent(depth: int = 0): int {.inline.} =
    ## Sets indentation based on depth of nodes when minifier is turned off.
    ## TODO Support for base indent number: 2, 3, or 4 spaces (default 2)
    result = if depth == 0: 0 else: 2 * depth

proc isNestable*[T: TokenTuple](token: T): bool =
    ## Determine if current token can contain more nodes
    ## TODO filter only nestable tokens
    result = token.kind notin {
        TK_IDENTIFIER, TK_ATTR, TK_ATTR_CLASS, TK_ATTR_ID, TK_ASSIGN, TK_COLON,
        TK_INTEGER, TK_STRING, TK_NEST_OP, TK_INVALID, TK_EOF, TK_NONE
    }

proc isConditional*[T: TokenTuple](token: T): bool =
    ## Determine if current token is part of Conditional Tokens
    ## as TK_IF, TK_ELIF, TK_ELSE
    result = token.kind in {TK_IF, TK_ELIF, TK_ELSE}

proc isIdent[T: TokenTuple](token: T): bool =
    result = token.kind == TK_IDENTIFIER

proc hasPrev[T: Parser](p: T, h: OrderedTable[int, TokenTuple]): bool =
    let prevln = if p.current.line == 1: 0 else: p.current.line - 1
    result = h.hasKey(prevln)

proc getPrev[T: Parser](p: var T, h: OrderedTable[int, TokenTuple]): TokenTuple = 
    ## Retrieve previous line from headliners
    let prevln = if p.current.line == 1: 0 else: p.current.line - 1
    result = h[prevln]

proc isChild[T: Parser](p: var T, h: OrderedTable[int, TokenTuple]): bool =
    result = p.hasPrev(h)
    if result and p.prevlnEndWithContent == false:
        result = p.getPrev(h).col < p.current.col;
    # result = childNode.col > parentNode.col
    # if result == true:
    #     result = (childNode.col and 1) != 1 and (parentNode.col and 1) != 1
    #     if result == false:
    #         p.setError("Bad indentation. Use 2 or 4 spaces to indent your code")

proc isBadNest[T: Parser](p: var T, h: OrderedTable[int, TokenTuple]): bool =
    ## Determine if current headline has a bad nest. This applies
    ## only if previous line ends with a string content
    if p.prevlnEndWithContent == true:
        let prev = p.getPrev(h)
        result = prev.col < p.current.col

proc isEOF[T: TokenTuple](token: T): bool {.inline.} =
    ## Determine if given token kind is TK_EOF
    result = token.kind == TK_EOF

template setHTMLAttributes[T: Parser](p: var T, htmlNode: var HtmlNode): untyped =
    ## Set HTML attributes for current HtmlNode, this template covers
    ## all kind of attributes, including `id`, and `class` or custom.
    var id: IDAttribute
    var hasAttributes: bool
    var attributes: Table[string, seq[string]]
    while true:
        if p.current.kind == TK_ATTR_CLASS and p.next.kind == TK_IDENTIFIER:
            # TODO check for wsno for `.` token and prevent mess
            hasAttributes = true
            if attributes.hasKey("class"):
                attributes["class"].add(p.next.value)
            else:
                attributes["class"] = @[p.next.value]
            jump p, 2
        elif p.current.kind == TK_ATTR_ID and p.next.kind == TK_IDENTIFIER:
            # TODO check for wsno for `#` token
            if htmlNode.hasID():
                p.setError("Elements can hold a single ID attribute.")
            id = IDAttribute(value: p.next.value)
            if id != nil: htmlNode.id = id
            jump p, 2
        elif p.current.kind == TK_IDENTIFIER and p.next.kind == TK_ASSIGN:
            # TODO check for wsno for other `attr` token
            let attrName = p.current.value
            jump p
            if p.next.kind != TK_STRING:
                p.setError("Missing value for \"$1\" attribute" % [attrName])
                break
            if attributes.hasKey(attrName):
                p.setError("Duplicate attribute name for \"$1\" identifier" % [attrName])
            else:
                attributes[attrName] = @[p.next.value]
                hasAttributes = true
            jump p, 2
        elif p.current.kind == TK_COLON:
            if p.next.kind != TK_STRING:
                # Handle string content assignment or enter in a multi dimensional nest
                if p.next.line > p.current.line == false:
                    p.setError("Missing string content for \"$1\" node" % [p.prev.value])
                    break
            else:
                jump p
                if (p.current.line == p.next.line) and not p.next.isEOF:
                    p.setError("Bad indentation after enclosed string")      # TODO a better error message?
                    break
                let htmlTextNode = HtmlNode(
                    nodeType: HtmlText,
                    nodeName: getSymbolName(HtmlText),
                    text: p.current.value,
                    meta: (column: p.current.col, indent: p.current.wsno, line: p.current.line)
                )
                htmlNode.nodes.add(htmlTextNode)
                p.prevlnEndWithContent = true
            break
        else:
            break
    if hasAttributes:
        for attrName, attrValues in attributes.pairs:
            htmlNode.attributes.add(HtmlAttribute(name: attrName, value: attrValues.join(" ")))
        hasAttributes = false
    clear(attributes)

proc parseVariable[T: Parser](p: var T, tokenVar: TokenTuple): VariableNode =
    ## Parse and validate given VariableNode
    var varNode: VariableNode
    let varName: string = tokenVar.value
    if not p.interpreter.hasVar(varName):
        p.setError("Undeclared variable for \"$1\" identifier" % [varName])
        return nil
    result = newVariableNode(varName, p.interpreter.getVar(varName))

template parseCondition[T: Parser](p: var T, conditionNode: ConditionalNode): untyped =
    ## Parse and validate given ConditionalNode 
    let currln: int = p.current.line
    var compToken: TokenTuple
    var varNode1, varNode2: VariableNode
    var comparatorNode: ComparatorNode
    while true:
        if p.current.kind == TK_IF and p.next.kind != TK_VARIABLE:
            p.setError("Missing variable identifier for conditional statement")
            break
        jump p
        varNode1 = p.parseVariable(p.current)
        jump p
        if varNode1 == nil: break    # and prompt "Undeclared identifier" error
        elif p.current.kind in {TK_EQ, TK_NEQ}:
            compToken = p.current
            if p.next.kind == TK_VARIABLE:
                jump p
                varNode2 = p.parseVariable(p.current)
            comparatorNode = newComparatorNode(compToken, @[varNode1, varNode2])
            conditionNode.comparatorNode = comparatorNode
        elif p.next.kind != TK_STRING:
            p.setError("Invalid conditional. Missing comparison value")
            break
        break

template `!>`[T: Parser](p: var T): untyped =
    ## Ensure nest token `>` exists for inline statements
    if p.current.isNestable() and p.next.isNestable():
        if p.current.line == p.next.line:
            p.setError("Missing `>` token for single line nest")
            break

template jit[T: Parser](p: var T): untyped =
    ## Enable jit flag When current document contains
    ## either conditionals, or variable assignments
    if p.enableJit == false: p.enableJit = true

proc rezolveInlineNest(lazySeq: var seq[HtmlNode]): HtmlNode =
    ## Rezolve lazy sequence of nodes collected from last inline nest
    # starting from tail, each node will be assigned to its sibling node
    # until we reach the begining of the sequence
    var i = 0
    var maxlen = (lazySeq.len - 1)
    while true:
        if i == maxlen: break
        lazySeq[(maxlen - (i + 1))].nodes.add(lazySeq[^1])
        lazySeq.delete( (maxlen - i) )
        inc i
    result = lazySeq[0]

template parseNewNode(p: var Parser, ndepth: var int, childNodes: var seq[HtmlNode], isInlineNest = false) =
    let htmlNodeType = getHtmlNodeType(p.current)
    var htmlNode = new HtmlNode
    with htmlNode:
        nodeType = htmlNodeType
        nodeName = htmlNodeType.getSymbolName
        meta = (column: p.current.col, indent: nindent(ndepth), line: p.current.line)
    
    if p.next.kind == TK_NEST_OP:
        jump p
        inc ndepth
    
    if p.next.isAttributeOrText():
        # parse html attributes, `id`, `class`, or any other custom attributes
        jump p
        inc ndepth
        p.setHTMLAttributes(htmlNode)
    
    if isInlineNest:
        childNodes.add htmlNode

proc walk(p: var Parser) =
    var 
        ndepth = 0
        node: Node
        htmlNode: HtmlNode
        conditionNode: ConditionalNode
        heads: OrderedTable[int, TokenTuple]
    while p.hasError() == false and p.current.kind != TK_EOF:
        var origin: TokenTuple = p.current
        while p.current.isNestable() and heads.hasKey(p.current.line) == false:
            # Handle current line headliner
            !> p # Ensure a good nest
            p.currln = p.current.line
            let htmlNodeType = getHtmlNodeType(p.current)
            heads[p.current.line] = p.current   # add current HTML element to heads table
            htmlNode = new HtmlNode
            with htmlNode:
                nodeType = htmlNodeType
                nodeName = getSymbolName(htmlNodeType)
                meta = (column: p.current.col, indent: nindent(ndepth), line: p.current.line)
            
            if p.next.isAttributeOrText():
                jump p
                p.setHTMLAttributes(htmlNode)     # set available html attributes
            
            p.parentNode = htmlNode
            if p.next.kind == TK_NEST_OP:
                # set as current ``htmlNode`` as ``parentNode`` in case current
                # node has opened an inline nestable elements with `>`
                jump p, 2
                inc ndepth
                break
            jump p

        var childNodes: HtmlNode
        var deferChildSeq: seq[HtmlNode]
        while p.current.line == p.currln and p.current.isEOF == false:
            # Walk along the line and collect single-line nests
            if p.current.isNestable():
                p.parseNewNode(ndepth, deferChildSeq, true)
            jump p

        if htmlNode != nil:
            if deferChildSeq.len != 0:
                childNodes = rezolveInlineNest(deferChildSeq)
            if childNodes != nil:
                p.parentNode.nodes.add(childNodes)

            # Create a new AST node for current HtmlNode and its child elements
            node = new Node
            with node:
                nodeName = getSymbolName(HtmlElement)
                nodeType = HtmlElement
                htmlNode = if p.parentNode != nil: p.parentNode else: htmlNode
            p.statements.add(node)  # add current node to statements
            # reset to default state
            p.parentNode = nil
            htmlNode = nil
            ndepth = 0

proc getStatements*[T: Parser](p: T, asNodes = true): seq[Node] =
    ## Return all HtmlNodes available in current document
    result = p.statements

proc getStatements*[T: Parser](p: T, asJsonNode = true): JsonNode =
    ## Return all HtmlNodes available in current document as JsonNode
    result = toJson(p.statements)

proc getStatementsStr*[T: Parser](p: T, prettyString = false): string = 
    ## Retrieve all HtmlNodes available in current document as stringified JSON
    if prettyString: 
        result = pretty(p.getStatements(asJsonNode = true))
    else:
        result = $(toJson(p.statements))

proc parse*[T: TimEngine](engine: T, templateObject: TimlTemplate, data: JsonNode = %*{}): Parser {.thread.} =
    var p: Parser = Parser(lexer: Lexer.init(templateObject.getSourceCode))
    p.interpreter = Interpreter.init(data = data)

    p.current = p.lexer.getToken()
    p.next    = p.lexer.getToken()
    p.currln  = p.current.line

    p.walk()
    result = p
