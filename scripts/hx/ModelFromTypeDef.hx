package ;

import hxp.Script;
import sys.FileSystem;
import sys.io.File;

/**
* Generates Domwires compatible models from typedefs.
* Will search for all typedefs marked with @GenerateModel metatag and generate class, interfaces and enum.
* See unit test typedeftest.ModelFromTypeDefTest.
* Usage: haxelib run hxp ./scripts/hx/ModelFromTypeDef.hx -Din=<path to input folder>
*
* -Din - path to input directory
* -Doverwrite - overwrite existing files (optional)
**/
class ModelFromTypeDef extends Script
{
    private var modelTemplate:String;
    private var iModelTemplate:String;
    private var iModelImmutableTemplate:String;
    private var modelMessageTypeTemplate:String;

    private var getterTemplate:String;
    private var setterTemplate:String;

    private var input:String;
    private var output:String;
    private var overwrite:Bool;

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

        input = workingDirectory + defines.get("in");
        overwrite = defines.exists("overwrite");

        loadTemplate();
        convertDir(input);
    }

    private function loadTemplate():Void
    {
        modelTemplate = File.getContent("./res/ModelTemplate");
        iModelTemplate = File.getContent("./res/IModelTemplate");
        iModelImmutableTemplate = File.getContent("./res/IModelImmutableTemplate");
        modelMessageTypeTemplate = File.getContent("./res/ModelMessageTypeTemplate");
        getterTemplate = File.getContent("./res/GetterTemplate");
        setterTemplate = File.getContent("./res/SetterTemplate");
    }

    private function convertDir(path:String):Void
    {
        output = path;

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
                    if (isTypeDef(fileName))
                    {
                        convertFile(p, fileName);
                    }
                }
            }
        }
    }

    private function convertFile(path:String, fileName:String):Void
    {
        var typedefFile:String = File.getContent(path);

        trace("Generate from typedef: \r\n" + typedefFile);

        save(generate(fileName, typedefFile, iModelImmutableTemplate, false, true));
        save(generate(fileName, typedefFile, iModelTemplate, false));
        save(generate(fileName, typedefFile, modelTemplate, true));
        save(generate(fileName, typedefFile, modelMessageTypeTemplate, false, false, true));
    }

    private function save(result:OutData):Void
    {

        var outputFile:String = output + "/" + result.fileName + ".hx";

        var canSave:Bool = true;

        if (FileSystem.exists(outputFile))
        {
            canSave = overwrite;

            if (!overwrite)
            {
                trace("'" + outputFile + "' already exists. Use -D overwrite to overwrite existing files...");
            }
        }

        if (canSave) File.saveContent(outputFile, result.data);
    }

    private function generate(fileName:String, typedefFile:String, template:String, isClass:Bool,
                              ?isImmutable:Bool, ?isEnum:Bool):OutData
    {
        var outputFileName:String = null;

        var prefix:String = fileName.split("TypeDef.hx")[0];
        var lineList:Array<String> = typedefFile.split("\r\n");

        var baseModel:String = getBaseModel(lineList);

        var package_name:String = lineList[0];

        var model_name:String = prefix + "Model";
        var model_base_name:String = "AbstractModel";
        var model_base_interface:String = "IModel";
        var data:String = prefix.charAt(0).toLowerCase() + prefix.substring(1, prefix.length) + "Data";
        var imports:String = "import com.domwires.core.mvc.model.*;\r\n";
        var over:String = "";
        var sup:String = "";

        if (isEnum)
        {
            outputFileName = model_name + "MessageType";
        }

        if (baseModel != null)
        {
            model_base_name = baseModel;

            var parseNameArr = model_base_name.split(".");
            if (parseNameArr.length > 1)
            {
                parseNameArr[parseNameArr.length - 1] = "I" + parseNameArr[parseNameArr.length - 1];

                model_base_interface = parseNameArr.join(".");
            } else
            {
                model_base_interface = "I" + model_base_name;
            }

            over = "override ";
            sup = "super.init();";
            imports = "";
        }

        imports += package_name.split("package ").join("import ").split(";").join("." + model_name + ";");

        var out:String = package_name + "\r\n\r\n" + template
            .split("${imports}").join(imports)
            .split("${data}").join(data)
            .split("${over}").join(over)
            .split("${sup}").join(sup)
            .split("${model_name}").join(model_name)
            .split("${model_base_name}").join(model_base_name)
            .split("${typedef_name}").join(fileName.split(".hx").join(""))
            .split("${model_base_interface}").join(model_base_interface);

        var content:String = "";
        var assign:String = "";

        for (i in 0...lineList.length)
        {
            var line:String = StringTools.ltrim(lineList[i]);
            var arr = line.split(":");
            if (arr.length > 1)
            {
                if (isImmutable)
                {
                    if (outputFileName == null) outputFileName = "I" + model_name + "Immutable";

                    line = arr.join("(get, never):");
                } else
                if (!isClass)
                {
                    if (outputFileName == null) outputFileName = "I" + model_name;

                    arr = line.split("var ");
                    if (arr.length > 1)
                    {
                        var char:String = line.charAt(4).toUpperCase();
                        line = line.substring(4, 0) + "set" + char + line.substring(5, line.length);

                        var type:String = line.split(":")[1].split(";").join("");

                        line = line.split(":").join("(value:" + type + "):").split("):" + type).join("):I" + model_name);
                        line = line.split("var ").join("function ");
                    }
                } else
                {
                    if (outputFileName == null) outputFileName = model_name;

                    var name:String = line.substring(line.indexOf("var ") + 4, line.indexOf(":"));
                    var u_name:String = name.charAt(0).toUpperCase() + name.substring(1, name.length);
                    var type:String = arr[1].split(";").join("");

                    line = getterTemplate.split("${name}").join(name).split("${type}").join(type) + "\r\n\r\n";
                    line += setterTemplate.split("${name}").join(name).split("${u_name}").join(u_name)
                        .split("${type}").join(type).split("${model_name}").join("I" + model_name) + "\r\n\r\n";

                    assign += "_" + name + " = " + data + "." + name + ";\r\n        ";
                }

                if (content == "") !isClass ? line += "\r\n    " : "";
                content += line;
            }
        }

        out = out.split("${content}").join(content).split("${assign}").join(assign);

        out = removeEmptyLines(out);

       return {fileName: outputFileName, data: out};
    }

    private function removeEmptyLines(text:String):String
    {
        var formattedText:String = "";
        var lineList:Array<String> = text.split("\r\n");

        var prevLine:String = null;
        var add:Bool = true;

        for (line in lineList)
        {
            if (!isEmpty(line))
            {
                add = true;
            } else
            if (prevLine == null)
            {
                add = true;
            } else
            if (isEmpty(prevLine))
            {
                add = false;
            }

            if (add)
            {
                formattedText += line + "\r\n";
            }

            prevLine = line;
        }

        return formattedText;
    }

    private function isEmpty(str:String):Bool
    {
        for (i in 0...str.length)
        {
            if (str.charAt(i) != " ")
            {
                return false;
            }
        }

        return true;
    }

    private function getBaseModel(lineList:Array<String>):String
    {
        var result:String = null;

        for (line in lineList)
        {
            var line:String = StringTools.trim(line);
            var arr = line.split("> ");
            if (arr.length > 1)
            {
                result = arr[1].split(",").join("").split("TypeDef").join("Model");
                trace("Base model: " + result);

                break;
            }
        }

        return result;
    }

    private function isTypeDef(fileName:String):Bool
    {
        return fileName.substr(fileName.length - 10) == "TypeDef.hx";
    }
}

typedef OutData = {
    var fileName:String;
    var data:String;
}