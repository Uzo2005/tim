import std/[os, strutils]
import pkg/kapsis/[cli, runtime] 
import ../engine/parser
import ../engine/logging
import ../engine/compilers/[html, nimc]

proc cCommand*(v: Values) = 
  ## Transpiles a `.timl` file to a target source
  let fpath = v.get("timl").getPath.path
  let ext = v.get("ext").getStr
  let pretty = v.has("pretty")
  let p = parseSnippet(fpath, readFile(getCurrentDir() / fpath))
  if likely(not p.hasErrors):
    if ext == "html":
      let c = newCompiler(parser.getAst(p), pretty == false)
      if likely(not c.hasErrors):
        display c.getHtml().strip
      else:
        for err in c.logger.errors:
          display err
        displayInfo c.logger.filePath
        quit(1)
    elif ext == "nim":
      let c = nimc.newCompiler(parser.getAst(p))
      display c.exportCode()
    else:
      displayError("Unknown target `" & ext & "`")
      quit(1)
  else:
    for err in p.logger.errors:
      display(err)
    displayInfo p.logger.filePath
    quit(1)
