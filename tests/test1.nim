import std/[unittest, json], tim
from std/os import getCurrentDir

Tim.init(
    source = getCurrentDir() & "/examples/templates",
    output = getCurrentDir() & "/examples/storage/templates",
    minified = false,
    indent = 4
)

Tim.setData(%*{
    "appName": "My application",
    "production": false,
    "keywords": ["template-engine", "html", "tim", "compiled", "templating"]
})

test "can init":
    assert Tim.hasAnySources == true
    assert Tim.getIndent == 4
    assert Tim.shouldMinify == false

test "can precompile":
    let timlFiles = Tim.precompile()
    assert timlFiles.len != 0

test "can render":
    echo Tim.render("index")
