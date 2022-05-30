# High-performance, compiled template engine inspired by Emmet syntax.
#
# (c) 2022 Tim Engine is released under MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/tim

template setHTMLAttributes[T: Parser](p: var T, htmlNode: var HtmlNode, nodeIndent = 0 ): untyped =
    ## Set HTML attributes for current HtmlNode, this template covers
    ## all kind of attributes, including `id`, and `class` or custom.
    var id: IDAttribute
    var hasAttributes: bool
    var attributes: Table[string, seq[string]]
    while true:
        if p.current.kind == TK_ATTR_CLASS:
            # if p.next.kind != TK_IDENTIFIER:
            #     p.setError("Invalid class name \"$1\"" % [p.next.value])
            #     break
            hasAttributes = true
            if attributes.hasKey("class"):
                if p.next.value in attributes["class"]:
                    p.setError("Duplicate class entry found for \"$1\"" % [p.next.value])
                else: attributes["class"].add(p.next.value)
            else:
                attributes["class"] = @[p.next.value]
            jump p, 2
        elif p.current.kind == TK_ATTR_ID and p.next.kind == TK_IDENTIFIER:
            # TODO check for wsno for `#` token
            if htmlNode.hasID():
                p.setError("Elements can hold a single ID attribute.")
                break
            id = IDAttribute(value: p.next.value)
            if id != nil: htmlNode.id = id
            jump p, 2
        elif p.current.kind in {TK_IDENTIFIER, TK_STYLE} and p.next.kind == TK_ASSIGN:
            # TODO check for wsno for other `attr` token
            p.current.kind = TK_IDENTIFIER
            let attrName = p.current.value
            jump p
            if p.next.kind != TK_STRING:
                p.setError("Missing value for \"$1\" attribute" % [attrName])
                break
            if attributes.hasKey(attrName):
                p.setError("Duplicate attribute name \"$1\"" % [attrName])
            else:
                attributes[attrName] = @[p.next.value]
                hasAttributes = true
            jump p, 2
        elif p.current.kind == TK_COLON:
            if p.next.kind != TK_STRING:
                # Handle string content assignment or enter in a multi dimensional nest
                p.setError("Expecting string content for \"$1\" node" % [htmlNode.nodeName])
                break
            else:
                jump p
                p.current.col = htmlNode.meta.column # get base column from ``htmlMeta`` node
                if (p.current.line == p.next.line) and not p.next.isEOF and p.next.kind != TK_AND:
                    p.setError("Bad indentation after enclosed string")
                    break
                elif (p.next.line > p.current.line) and (p.next.col > p.current.col):
                    p.setError("Bad indentation after enclosed string")
                    break

                let col = p.current.col
                let line = p.current.line
                if p.next.kind == TK_AND:
                    # If provided, Tim can handle string concatenations like
                    # a: "Click here" & span: "to buy" which output to
                    # <a>Click here <span>to buy</span</a>
                    if p.next.line == p.current.line:
                        # handle inline string concatenations using `&` separator
                        jump p
                        while true:
                            if p.current.line != line: break
                            # echo p.current
                            jump p
                    else:
                        p.setError("Invalid string concatenation")
                        break

                let htmlTextNode = HtmlNode(
                    nodeType: HtmlText,
                    nodeName: getSymbolName(HtmlText),
                    text: p.current.value,
                    meta: (column: col, indent: nodeIndent, line: line, childOf: 0, depth: 0)
                )
                htmlNode.nodes.add(htmlTextNode)
            break
        else: break

    if hasAttributes:
        for attrName, attrValues in attributes.pairs:
            htmlNode.attributes.add(HtmlAttribute(name: attrName, value: attrValues.join(" ")))
        hasAttributes = false
    clear(attributes)

proc parseVariable[T: Parser](p: var T, tokenVar: TokenTuple): VariableNode =
    ## Parse and validate given VariableNode
    # var varNode: VariableNode
    let varName: string = tokenVar.value
    if not p.data.hasVar(varName):
        p.setError "Undeclared variable \"$1\"" % [varName]
        return nil
    result = newVariableNode(varName, p.data.getVar(varName))
    jit p

template parseIteration[P: Parser](p: var P, interationNode: IterationNode): untyped =
    if p.next.kind != TK_VARIABLE:
        p.setError("Invalid iteration missing variable identifier")
        break
    jump p
    let varItemName = p.current.value
    if p.next.kind != TK_IN:
        p.setError("Invalid iteration missing")
        break
    jump p
    if p.next.kind != TK_VARIABLE:
        p.setError("Invalid iteration missing variable identifier")
        break
    iterationNode.varItemName = varItemName
    iterationNode.varItemsName = p.next.value
    jump p, 2
    jit p  # enable JIT compilation flag

template parseCondition[T: Parser](p: var T, conditionNode: ConditionalNode): untyped =
    ## Parse and validate given ConditionalNode 
    var compToken: TokenTuple
    var varNode1, varNode2: VariableNode
    var comparatorNode: ComparatorNode
    while true:
        if p.current.kind == TK_IF and p.next.kind != TK_VARIABLE:
            p.setError("Invalid conditional statement missing var identifier")
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
    jit p