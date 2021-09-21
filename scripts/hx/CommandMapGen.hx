import haxe.Json;
import hxp.Script;
import sys.FileSystem;
import sys.io.File;
import utils.FileUtils;
import utils.StringUtils;

class CommandMapGen extends Script
{
    private var resultJson:Dynamic = {};

    public function new()
    {
        super();

        Sys.setCwd(workingDirectory);

        if (!defines.exists("in"))
        {
            trace("Path to input directory is not specified!");
            trace("Define it as flag -Din=path_to_dir...");
            Sys.exit(1);
        }
        if (!defines.exists("out"))
        {
            trace("Path to out directory is not specified!");
            trace("Define it as flag -Dout=path_to_dir...");
            Sys.exit(1);
        }

        convertDir(defines.get("in"));

        final out:String = defines.get("out");
        FileSystem.createDirectory(out);
        File.saveContent(out + "/command_map.json", Json.stringify(resultJson));
    }

    private function convertDir(path:String):Void
    {
        if (FileSystem.exists(path) && FileSystem.isDirectory(path))
        {
            for (fileName in FileSystem.readDirectory(path))
            {
                var p:String = path + "/" + fileName;
                if (FileSystem.isDirectory(p))
                {
                    convertDir(p);
                } else
                {
                    if (fileName.substr(fileName.length - 3) == ".hx")
                    {
                        convertFile(p, fileName);
                    }
                }
            }
        }
    }

    private function convertFile(path:String, fileName:String):Void
    {
        var fileContent:String = File.getContent(path);

        if (fileContent.split("@CommandAlias(").length == 2)
        {
            final cmdAlias:String = "@CommandAlias(\"";
            final cmdDesc:String = "@CommandDesc(\"";

            var lineList:Array<String> = fileContent.split(FileUtils.lineSeparator());
            var packageName:String = null;
            var className:String = null;

            var startIndex:Int = fileContent.indexOf(cmdAlias) + cmdAlias.length;
            var alias:String = fileContent.substring(startIndex, fileContent.indexOf("\"", startIndex));

            startIndex = fileContent.indexOf(cmdDesc) + cmdDesc.length;
            var desc:String = fileContent.substring(startIndex, fileContent.indexOf("\"", startIndex));

            for (line in lineList)
            {
                if (packageName == null)
                {
                    if (line.indexOf("package") != -1)
                    {
                        line = StringUtils.removeAllEmptySpace(line);
                        if (line == "package ;")
                        {
                            packageName = "";
                        } else
                        {
                            packageName = line.substring(line.indexOf("package ") + 8, line.indexOf(";"));
                        }
                    }
                } else
                if (className == null)
                {
                    if (line.indexOf("class ") != -1)
                    {
                        line = line.split(" extends ")[0];
                        line = StringUtils.removeAllEmptySpace(line).split("class").join("class ");
                        className = line.substring(line.indexOf(" ") + 1, line.length);
                    }
                } else
                {
                    break;
                }
            }

            if (className == null || packageName == null) return;

            var classNameWithPackage:String = packageName + "." + className;

            trace("alias: " + alias);
            trace("desc: " + desc);
            trace("className: " + classNameWithPackage);
            trace("-------------------");

            Reflect.setField(resultJson, alias, {desc: desc, className: classNameWithPackage});
        }
    }
}
