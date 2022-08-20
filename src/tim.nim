# High-performance, compiled template engine inspired by Emmet syntax.
#
# (c) 2022 Tim Engine is released under MIT License
#          Made by Humans from OpenPeep
#          https://github.com/openpeep/tim

import pkginfo, jsony
import tim/engine/[ast, parser, compiler, meta]
import std/[tables, json]
from std/strutils import `%`

when requires "watchout":
    import watchout
    from std/times import cpuTime

when requires "emitter":
    import emitter

export parser, compiler
export meta except TimEngine

const DockType = "<!DOCTYPE html>"

var Tim* {.global.}: TimEngine

proc jitHtml(engine: TimEngine, view, layout: TimlTemplate, data: JsonNode) =
    echo "jit compilation"
    # var jitProgram = fromJson(engine.readBson(view), Program)
    echo engine.readBson(view)
    let c = Compiler.init(
        astProgram = fromJson(engine.readBson(view), Program),
        minified = engine.shouldMinify(),
        templateType = view.getType(),
        baseIndent = engine.getIndent(),
        data = data
    )
    echo c.getHtml()
    # echo jitProgram.nodes.len

proc staticHtml(engine: TimEngine, view, layout: TimlTemplate): string =
    result = DockType
    result.add layout.getHtmlCode()
    result.add view.getHtmlCode()
    when requires "supranim":
        when not defined release:
            proc httpReloader(): string =
                result = """
<script type="text/javascript">
document.addEventListener("DOMContentLoaded", function() {
    var prevTime = localStorage.getItem("watchout") || 0
    function liveChanges() {
        fetch('/watchout')
            .then(res => res.json())
            .then(body => {
                if(body.state == 0) return
                if(body.state > prevTime) {
                    localStorage.setItem("watchout", body.state)
                    location.reload()
                }
            }).catch(function() {});
        setTimeout(liveChanges, 500)
    }
    liveChanges();
});
</script>
"""
            proc wsReloader(): string =
                # Reload Supranim application using
                # a WebSocket Connection 
                # TODO
                result = ""
            case engine.getReloadType():
            of HttpReloader:
                result.add httpReloader()
            of WSReloader:
                result.add wsReloader()
            else: discard
    result.add layout.getHtmlTailsCode()

proc render*(engine: TimEngine, key: string, layoutKey = "base", data: JsonNode = %*{}): string =
    ## Renders a template view by name. Use dot-annotations
    ## for rendering views in nested directories.
    if engine.hasView(key):
        # TODO handle templates marked with JIT
        var view: TimlTemplate = engine.getView(key)
        if not engine.hasLayout(layoutKey):
            raise newException(TimDefect, "Could not find \"" & layoutKey & "\" layout.")
        var layout: TimlTemplate = engine.getLayout(layoutKey)
        if view.isJitEnabled():
            engine.jitHtml(view, layout, data)
        else:
            result = engine.staticHtml(view, layout)

proc preCompileTemplate(engine: TimEngine, temp: var TimlTemplate) =
    let tpType = temp.getType()
    var p: Parser = engine.parse(temp.getSourceCode(), temp.getFilePath(), templateType = tpType)
    if p.hasError():
        raise newException(TimSyntaxError, "\n"&p.getError())
    if p.hasJIT():
        temp.enableJIT()
        engine.writeBson(temp, p.getStatementsStr(), engine.getIndent())
    else:
        let c = Compiler.init(
            p.getStatements(),
            minified = engine.shouldMinify(),
            templateType = tpType,
            baseIndent = engine.getIndent()
        )
        if tpType == Layout:
            # Save layout tails in a separate .html file, suffixed with `_`
            engine.writeHtml(temp, c.getHtmlTails(), isTail = true)
        engine.writeHtml(temp, c.getHtml())

proc precompile*(engine: var TimEngine, callback: proc() {.gcsafe, nimcall.} = nil,
                debug = false): seq[string] {.discardable.} =
    ## Pre-compile ``views`` and ``layouts``
    ## from ``.timl`` to HTML or BSON.
    ##
    ## Note that ``partials`` contents are collected on
    ## compile-time and merged within the view.
    if Tim.hasAnySources:
        when not defined release:
            # Enable auto precompile when in development mode
            when requires "watchout":
                # Will use `watchout` to watch for changes in `/templates` dir
                proc watchoutCallback(file: watchout.File) {.closure.} =
                    let initTime = cpuTime()
                    echo "\n✨ Watchout resolve changes"
                    echo file.getName()
                    var timlTemplate = getTemplateByPath(Tim, file.getPath())
                    if timlTemplate.isPartial:
                        for dependentView in timlTemplate.getDependentViews():
                            Tim.preCompileTemplate(
                                getTemplateByPath(Tim, dependentView)
                            )
                    else:
                        Tim.preCompileTemplate(timlTemplate)
                    echo "Done in " & $(cpuTime() - initTime)
                    if callback != nil:
                        callback()
                var watchFiles: seq[string]
                when compileOption("threads"):
                    for id, view in Tim.getViews().mpairs():
                        Tim.preCompileTemplate(view)
                        watchFiles.add view.getFilePath()
                        result.add view.getName()
                    
                    for id, partial in Tim.getPartials().pairs():
                        # Watch for changes in `partials` directory.
                        watchFiles.add partial.getFilePath()

                    for id, layout in Tim.getLayouts().mpairs():
                        Tim.preCompileTemplate(layout)
                        watchFiles.add layout.getFilePath()
                        result.add layout.getName()

                    # Start a new Thread with Watchout watching for live changes
                    startThread(watchoutCallback, watchFiles, 550)
                    return

        for id, view in Tim.getViews().mpairs():
            Tim.preCompileTemplate(view)
            result.add view.getName()

        for id, layout in Tim.getLayouts().mpairs():
            Tim.preCompileTemplate(layout)
            result.add layout.getName()

when isMainModule:
    Tim.init(
        source = "../examples/templates",
        output = "../examples/storage",
        indent = 2,
        minified = false
    )
    let timTemplates = Tim.precompile()
    echo Tim.render("index", data = %*{
        "name": "George Lemon"
    })