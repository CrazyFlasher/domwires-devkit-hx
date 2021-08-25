package ;

import utils.FileUtils;
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
* -Dverbose - extended logs (optional)
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
    private var verbose:Bool;

    private var enumValueList:Array<String>;

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
        verbose = defines.exists("overwrite");

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

        if (verbose)
        {
            traceTemplate("ModelTemplate", modelTemplate);
            traceTemplate("IModelTemplate", iModelTemplate);
            traceTemplate("IModelImmutableTemplate", iModelImmutableTemplate);
            traceTemplate("ModelMessageTypeTemplate", modelMessageTypeTemplate);
            traceTemplate("GetterTemplate", getterTemplate);
            traceTemplate("SetterTemplate", setterTemplate);
        }
    }

    private function traceTemplate(name:String, content:String):Void
    {
        trace(sep() + "-------------- " + name + "--------------");
        trace(sep() + content);
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

        trace("Generate model from typedef: " + fileName);

        if (verbose)
        {
            trace(sep() + typedefFile);
        }

        enumValueList = [];

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

        if (canSave)
        {
            File.saveContent(outputFile, result.data);

            if (verbose)
            {
                trace("File created: " + outputFile);
                trace(sep() + result.data);
            }
        }
    }

    private function generate(fileName:String, typedefFile:String, template:String, isClass:Bool,
                              ?isImmutable:Bool, ?isEnum:Bool):OutData
    {
        var outputFileName:String = null;

        var prefix:String = fileName.split("TypeDef.hx")[0];
        var lineList:Array<String> = typedefFile.split(sep());

        var baseModel:String = getBaseModel(lineList);

        var package_name:String = lineList[0];

        var model_name:String = prefix + "Model";
        var model_base_name:String = "AbstractModel";
        var model_base_interface:String = "IModel";
        var data:String = prefix.charAt(0).toLowerCase() + prefix.substring(1, prefix.length) + "Data";
        var imports:String = "import com.domwires.core.mvc.model.*;" + sep();
        var over:String = "";
        var sup:String = "";

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

        var out:String = package_name + sep() + FileUtils.lineSeparator() + template
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

        if (isEnum)
        {
            outputFileName = model_name + "MessageType";

            for (value in enumValueList)
            {
                content += value + sep() + "    ";
            }
        }

        for (i in 0...lineList.length)
        {
            var line:String = StringTools.ltrim(lineList[i]);
            var arr = line.split(":");
            if (arr.length > 1)
            {
                if (isImmutable)
                {
                    if (outputFileName == null) outputFileName = "I" + model_name + "Immutable";

                    line = arr.join("(get, never):").split("final").join("var");
                } else
                if (!isClass && !isEnum)
                {
                    if (outputFileName == null) outputFileName = "I" + model_name;

                    arr = line.split("var ");

                    if (arr.length > 1)
                    {
                        trace("Please, use final instead of var in typeDef to keep immutability!");
                        Sys.exit(1);
                    }

                    arr = line.split("final ");

                    if (arr.length > 1)
                    {
                        var char:String = line.charAt(6).toUpperCase();
                        var methodNameWithType:String = char + line.substring(7, line.length);
                        line = line.substring(6, 0) + "set" + methodNameWithType;

                        var type:String = line.split(":")[1].split(";").join("");
                        var messageType:String = methodNameWithType.split(":")[0];
                        enumValueList.push("OnSet" + messageType + ";");

                        line = line.split(":").join("(value:" + type + "):").split("):" + type).join("):I" + model_name);
                        line = line.split("final ").join("function ");
                    }
                } else
                if (!isEnum)
                {
                    if (outputFileName == null) outputFileName = model_name;

                    var name:String = line.substring(line.indexOf("final ") + 6, line.indexOf(":"));
                    var u_name:String = name.charAt(0).toUpperCase() + name.substring(1, name.length);
                    var type:String = arr[1].split(";").join("");
                    var messageType:String = "OnSet" + u_name;

                    line = getterTemplate.split("${name}").join(name).split("${type}").join(type) + sep(2);
                    line += setterTemplate.split("${name}").join(name).split("${u_name}").join(u_name)
                        .split("${type}").join(type).split("${model_name}").join(model_name)
                        .split("${message_type}").join(messageType) + sep(2);

                    assign += "_" + name + " = " + data + "." + name + ";" + sep() + "        ";
                }

                if (!isEnum)
                {
                    if (content == "") !isClass ? line += sep() + "    " : "";
                    content += line;
                }
            }
        }

        out = out.split("${content}").join(content).split("${assign}").join(assign);

        out = removeEmptyLines(out);

       return {fileName: outputFileName, data: out};
    }

    private function removeEmptyLines(text:String):String
    {
        var formattedText:String = "";
        var lineList:Array<String> = text.split(sep());

        var prevLine:String = null;
        var add:Bool = true;

        for (i in 0...lineList.length)
        {
            var line:String = lineList[i];
            var nextLine:String = i < lineList.length - 1 ? lineList[i + 1] : null;

            if (!isEmpty(line))
            {
                add = true;
            } else
            if (prevLine == null)
            {
                add = true;
            } else
            if (isEmpty(prevLine) || (nextLine.split("}").length == 2))
            {
                add = false;
            }

            if (add)
            {
                formattedText += line + sep();
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
            var arr = line.split("> ");
            if (arr.length > 1)
            {
                result = arr[1].split(",").join("").split("TypeDef").join("Model");

                if (verbose) trace("Base model: " + result);

                break;
            }
        }

        return result;
    }

    private function isTypeDef(fileName:String):Bool
    {
        return fileName.substr(fileName.length - 10) == "TypeDef.hx";
    }

    private function sep(x:Int = 1):String
    {
        var out:String = "";

        for (i in 0...x)
        {
            out += FileUtils.lineSeparator();
        }

        return out;
    }
}

typedef OutData = {
    var fileName:String;
    var data:String;
}