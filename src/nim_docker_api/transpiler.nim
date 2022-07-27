import strutils
import regex
import tables
import sequtils
import os

var exportsTable = initTable[string, seq[string]]()
var filesTable = initTable[string, string]()
proc translateFile(path: string) =
    let fileName = extractFilename(path)
    var data = path.readFile()

    data.add("""


    """)
    data = data.replace("##", "//")
    data = data.replace("#", "//")
    data = data.replace("*:", ":")
    data = data.replace("type", "")
    data = data.replace("seq", "")
    data = data.replace("{.pure.}", "")
    data = data.replace("import tables", "")
    data = data.replace("import times", "")
    data = data.replace("import jsony", "")
    data = data.replace("import options", "")

    data = data.replace("DateTime", "Date")
    let number_replace = @[ "uint64", "uint32","uint", "uint8","int64", "int32", "int8","int", "float64", "float32", "float"]
    for val in number_replace:
        data = data.replace(re(val&"(\\n|\\s+)?"), "Number$1")

    data = data.replace("bool", "Boolean")

    let interfaceMatch = re"((\n?\s\s?type)?|(^\s+)?)(\w+)\*?( ?= ?object)((.|\n)*?)(\n\n)"
    let interfaceReplace = """

    export interface $4 {
    $6
    }

    """
    data = data.replace(interfaceMatch, interfaceReplace)


    let tableMatch = re"(?m)Table\[(\w+), (\w+)\]"
    let tableReplace = """{[key:$1]: $2}"""
    data = data.replace(tableMatch, tableReplace)

    let enumMatch = re"(\n\s+?type\s+|\n\s+)(\w+).+= enum((.|\n)*?)(\n\n)"
    let enumReplace = """


    export enum $2 {
        $3
    }


    """
    data = data.replace(enumMatch, enumReplace)


    let optionFieldMatch = re"""(\n?\s+)(\w+)\*?: Option\[(.+)\]"""
    let optionFieldReplace = """$1$2?: $3"""

    data = data.replace(optionFieldMatch, optionFieldReplace)
    echo data

    var exports: seq[string]
    for m in data.findAll(re"export \w+ (\w+)"):
        exports.add(m.group(0, data)[0])

    exportsTable[path] = exports
    filesTable[fileName] = data

proc translateImports(text: string) =
    var tempFile = text

    var importFiles: seq[string]
    for m in tempFile.findAll(re"import (\w+)"):
        importFiles.add(m.group(0, tempFile)[0])

    for importFile in  importFiles:
        if exportsTable.hasKey(importFile):
            let importString = "import {" & exportsTable[importFile].foldl(a & ", " & b & "} from" & importFile & ";\n")
            tempFile = importString & tempFile

    echo tempFile


translateFile("src/nim_docker_api/openapiclient/models/model_container_stats.nim")
translateImports("src/nim_docker_api/openapiclient/models/model_container_stats.nim")