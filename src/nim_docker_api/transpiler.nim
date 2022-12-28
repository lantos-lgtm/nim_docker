import strutils
import regex
import tables
import sequtils
import os


var exportsTable = initTable[string, seq[string]]()
var filesTable = initTable[string, string]()
var filesFinalTable = initTable[string, string]()

proc translateFile(filename, path: string) =
    var data = path.readFile()

    # add some white space to the end of the file
    data.add("""


    """)
    data = data.replace("##", "//")
    data = data.replace("#", "//")
    data = data.replace("*:", ":")
    data = data.replace("type ", " ")
    data = data.replace("seq", "")
    data = data.replace("{.pure.} ", "")
    data = data.replace("import tables", "")
    data = data.replace("import times", "")
    data = data.replace("import jsony", "")
    data = data.replace("`", "")
    data = data.replace("import options", "")

    # map DateTime
    data = data.replace("DateTime", "Date")

    # map numbers order matters
    let number_replace = @[
        "uint64",
        "uint32",
        "uint8",
        "uint",
        "int64",
        "int32",
        "int8",
        "int",
        "float64",
        "float32",
        "float"]
        
    for val in number_replace:
        data = data.replace(re("\\s" & val & "(\\n|\\s+)?"), "Number$1")

    # map boolean
    data = data.replace("bool", "Boolean")

    # map types
    let interfaceMatch = re"((\n?\s\s?type)?|(^\s+)?)(\w+)\*?( ?= ?object)((.|\n)*?)(\n\n)"
    let interfaceReplace = "\nexport interface $4 {\n$6\n}\n"
    data = data.replace(interfaceMatch, interfaceReplace)

    # map tables
    let tableMatch = re"(?m)Table\[(\w+), (\w+)\]"
    let tableReplace = """{[key:$1]: $2}"""
    data = data.replace(tableMatch, tableReplace)

    # map enums
    let enumMatch = re"(?m)^\s+(\w+)\* ?= ?enum((.|\n)*?)(^\n)"
    let enumReplace = "\n\nexport enum $1 {\n$2\n}\n"
    data = data.replace(enumMatch, enumReplace)

    # fix enums not having commas
    let enumsFixMatch = re"""(\w+) = "(\w+)""""
    discard """""""
    let enumsFixReplace = """$1 = "$2","""
    data = data.replace(enumsFixMatch, enumsFixReplace)

    # remove x: Option[T] -> x?: T
    let optionFieldMatch = re"""(\n?\s+)(\w+)\*?: Option\[(.+)\]"""
    let optionFieldReplace = """$1$2?: $3"""
    data = data.replace(optionFieldMatch, optionFieldReplace)

    # fix no mapping for Tables options
    data = data.replace("Table[string, Option[{[key:string]: string}]]", "{[key:string]: {[key:string]: string}}")
    var exports: seq[string]
    for m in data.findAll(re"export \w+ (\w+)"):
        exports.add(m.group(0, data)[0])


    exportsTable[filename] = exports
    filesTable[filename] = data

# dirty import mapper
proc translateImports(filename: string, text: string) =
    var tempFile = text

    # find all imports
    var importFiles: seq[string]
    for m in tempFile.findAll(re"import (\w+)"):
        importFiles.add(m.group(0, tempFile)[0])

    let importMatch = re"import (\w+)"
    let importReplace = ""
    tempFile = tempFile.replace(importMatch, importReplace)

    # if had mapping pull it in
    for importFile in importFiles:
        if exportsTable.hasKey(importFile & ".nim"):
            # create import { name } from "./file.nim"
            let importStringsSaved = exportsTable[importFile & ".nim"]
            let importString = "import {" & importStringsSaved.foldl(a & ", " &
                    b) & "} from \"./" & importFile & ".nim\";\n"

            tempFile = importString & tempFile

    filesFinalTable[filename] = tempFile


for file in walkDir("src/nim_docker_api/openapiclient/models/"):
    translateFile(file.path.extractFilename, file.path)

for filename, text in filesTable.pairs():
    translateImports(filename, text)

createDir("./typescript/")
for (filename, text) in filesFinalTable.pairs():
    writeFile("./typescript/" & filename & ".ts", text)
