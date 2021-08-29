package ;

import hxp.Script;
import sys.FileSystem;
import sys.io.File;
import utils.FileUtils;

/**
* Generates Domwires compatible models from typedefs.
* Will search for all typedefs marked with @Model metatag and generate class, interfaces and enum.
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

    private var modelName:String;

    private var input:String;
    private var templatesPath:String;
    private var output:String;
    private var overwrite:Bool;
    private var verbose:Bool;

    private var enumValueList:Array<String>;
    private var typedefFile:String;
    private var typeDefFileName:String;
    private var hasErrors:Bool = false;

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
        if (!defines.exists("templatesPath"))
        {
            trace("Path to templates directory is not specified!");
            trace("Define it as flag -DtemplatesPath=path_to_templates...");
            Sys.exit(1);
        }

        templatesPath = workingDirectory + defines.get("templatesPath");
        input = workingDirectory + defines.get("in");
        overwrite = defines.exists("overwrite");
        verbose = defines.exists("verbose");

        loadTemplate();
        convertDir(input);
    }

    private function loadTemplate():Void
    {
        modelTemplate = File.getContent(templatesPath + "/ModelTemplate");
        iModelTemplate = File.getContent(templatesPath + "/IModelTemplate");
        iModelImmutableTemplate = File.getContent(templatesPath + "/IModelImmutableTemplate");
        modelMessageTypeTemplate = File.getContent(templatesPath + "/ModelMessageTypeTemplate");
        getterTemplate = File.getContent(templatesPath + "/GetterTemplate");
        setterTemplate = File.getContent(templatesPath + "/SetterTemplate");

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
        typedefFile = File.getContent(path);

        this.typeDefFileName = fileName;

        typedefFile = StringUtils.removeAllEmptySpace(typedefFile);

        if (typedefFile.split(" @Model typedef ").length == 2)
        {
            output = path.split(fileName)[0];

            trace("Generate model from typedef: " + fileName);

            if (verbose)
            {
                trace(sep() + typedefFile);
            }

            enumValueList = [];

            create(true);
            create(false);
        }
    }

    private function create(isBase:Bool):Void
    {
        save(generate(ObjectType.Immutable, isBase), isBase);
        save(generate(ObjectType.Mutable, isBase), isBase);
        save(generate(ObjectType.Class, isBase), isBase);
        if (!isBase) save(generate(ObjectType.Enum, isBase), isBase, true);
    }

    private function save(result:OutData, isBase:Bool = false, isEnum:Bool = false):Void
    {
        var overwrite:Bool = this.overwrite || isBase;

        if (hasErrors)
        {
            Sys.exit(1);
        }

        var dirName:String = output + getNewPackageName(typeDefFileName, false);
        if (isBase) dirName += "/gen";

        var outputFile:String = dirName + "/" + result.fileName + ".hx";

        FileSystem.createDirectory(dirName);
        if (!isBase)
        {
            File.saveContent(dirName + "/.gitignore", "gen");
        }

        var canSave:Bool = true;

        if (FileSystem.exists(outputFile))
        {
            canSave = overwrite;

            if (!overwrite)
            {
                if (isEnum)
                {
                    canSave = true;

                    var body:String = File.getContent(outputFile);
                    body = StringUtils.removeAllEmptySpace(body);

                    var content:String = body.substring(body.indexOf("{") + 1, body.indexOf("}"));
                    var valueList:Array<String> = content.split(";");
                    if (valueList.length > 0) valueList.pop();
                    valueList = removeDuplicates(valueList.concat(enumValueList));

                    content = "";

                    for (value in valueList)
                    {
                        content += (valueList.indexOf(value) != 0 ? tab() : "") + value + ";" + sep();
                    }

                    result.data = removeEmptyLines(modelMessageTypeTemplate
                    .split("${model_name}").join(modelName)
                    .split("${content}").join(content));

                    if (verbose)
                    {
                        trace("Existing enum values: " + content);
                    }
                } else
                {
                    trace("'" + outputFile + "' already exists. Use -D overwrite to overwrite existing files...");
                }
            }
        }

        if (canSave)
        {
            File.saveContent(outputFile, result.data);

            if (verbose)
            {
                trace("Output file: " + outputFile);
                trace(sep() + result.data);
            }
        }
    }

    private function generate(type:EnumValue, isBase:Bool = false):OutData
    {
        var template:String = null;

        if (type == ObjectType.Enum)
        {
            template = modelMessageTypeTemplate;
        } else
        if (type == ObjectType.Class)
        {
            template = modelTemplate;
        } else
        if (type == ObjectType.Mutable)
        {
            template = iModelTemplate;
        } else
        if (type == ObjectType.Immutable)
        {
            template = iModelImmutableTemplate;
        }

        var outputFileName:String = null;

        var importSprit:Array<String> = typedefFile.split("import ");
        var semicolonSplit:Array<String> = typedefFile.split(";");
        var equalSplit:Array<String> = typedefFile.split("=");
        var packageSplit:Array<String> = semicolonSplit[0].split("package ");
        var typeDefSplit:Array<String> = semicolonSplit[1].split("typedef ");
        var arrowSplit:Array<String> = typedefFile.split(">");

        if (arrowSplit.length > 2)
        {
            trace("Error: only single inheritance in supported: " + typeDefFileName);
            hasErrors = true;
        }
        if (importSprit.length > 1 && importSprit[0].indexOf("import ") == 0)
        {
            trace("Error: imports are not supported. Use full package path: " + typeDefFileName);
            hasErrors = true;
        }
        if (packageSplit.length != 2)
        {
            trace("Error: package is missing in: " + typeDefFileName);
            hasErrors = true;
        }
        if (typeDefSplit.length != 2)
        {
            trace("Error: typdef is missing in: " + typeDefFileName);
            hasErrors = true;
        }

        var packageValue:String = semicolonSplit[0] + "." + getNewPackageName(typeDefFileName, isBase);
        var packageName:String = packageValue.split("package ")[1];
        var typeDefName:String = typeDefSplit[1].split("=")[0];

        var baseModelName:String = null;
        if (isBase)
        {
            if (arrowSplit.length > 1)
            {

                var baseTypeDefWithPackage:String = arrowSplit[1].substring(0, arrowSplit[1].indexOf(","));
                var baseTypeDefWithPackageSplit:Array<String> = baseTypeDefWithPackage.split(".");
                var baseTypeDef:String = baseTypeDefWithPackageSplit[baseTypeDefWithPackageSplit.length - 1];
                var baseTypeDefPackage:String = baseTypeDefWithPackageSplit[0];
                baseTypeDefWithPackage = baseTypeDefPackage + "." + baseTypeDef.charAt(0).toLowerCase() +
                baseTypeDef.substring(1, baseTypeDef.length) + "." + baseTypeDef;
                baseModelName = baseTypeDefWithPackage + "Model";

                trace("Base model: " + baseModelName);
            }
        } else
        {
            baseModelName = packageName + ".gen.ModelGen";
        }

        var modelPrefix:String = typeDefName;
        modelName = isBase ? "ModelGen" : modelPrefix + "Model";
        var enumName:String = modelPrefix + "Model";
        var modelBaseName:String = "AbstractModel";
        var modelBaseInterface:String = "IModel";
        var data:String = modelPrefix.charAt(0).toLowerCase() + modelPrefix.substring(1, modelPrefix.length) + "Data";
        var imports:String = "import com.domwires.core.mvc.model.*;" + sep();
        var _override:String = "";
        var _super:String = "";

        if (baseModelName != null || !isBase)
        {
            modelBaseName = baseModelName;

            var modelBaseNameSplit:Array<String> = modelBaseName.split(".");
            if (modelBaseNameSplit.length > 1)
            {
                modelBaseNameSplit[modelBaseNameSplit.length - 1] = "I" + modelBaseNameSplit[modelBaseNameSplit.length - 1];

                modelBaseInterface = modelBaseNameSplit.join(".");
            } else
            {
                modelBaseInterface = "I" + modelBaseName;
            }

            _override = "override ";
            _super = "super.init();";
            imports = "";
        }

        if (type == ObjectType.Mutable)
        {
            imports += "import " + packageName + "." + modelName + ";";
        }

        var out:String = packageValue + ";" + sep(2) + template;

        if (isBase)
        {
            out = out.split("${data}").join(data);
        } else
        {
            out = out.split(tab() + "@Inject" + sep() + tab() + "private var ${data}:${typedef_name};").join("");
        }

        out = out
            .split("${imports}").join(imports)
            .split("${_override}").join(_override)
            .split("${_super}").join(_super)
            .split("${model_name}").join(modelName)
            .split("${model_base_name}").join(modelBaseName)
            .split("${typedef_name}").join(typeDefName)
            .split("${model_base_interface}").join(modelBaseInterface);

        var content:String = "";
        var assign:String = "";

        if (type == ObjectType.Enum)
        {
            outputFileName = modelName + "MessageType";

            for (value in enumValueList)
            {
                content += value + ";" + sep() + tab();
            }
        }

        if (!isBase)
        {
            if (type == ObjectType.Immutable)
            {
                outputFileName = "I" + modelName + "Immutable";
            } else
            if (type == ObjectType.Mutable)
            {
                outputFileName = "I" + modelName;
            } else
            if (type == ObjectType.Class)
            {
                outputFileName = modelName;
            }
        } else
        {
            var paramList:Array<String> = arrowSplit.length > 1
            ? equalSplit[1].split(",")[1].split(";")
            : equalSplit[1].substring(1, equalSplit[1].lastIndexOf("}")).split(";");

            paramList.pop();

            for (param in paramList)
            {
                if (param.split("final ").length != 2)
                {
                    trace("Error: use 'final' to keep immutability: " + param);
                    hasErrors = true;
                }
            }

            for (i in 0...paramList.length)
            {
                var line:String = "";

                var param:String = paramList[i];
                var paramTypeSplit:Array<String> = param.split(":");
                var paramFinalSplit:Array<String> = param.split("final ");

                if (paramTypeSplit.length != 2)
                {
                    trace("Error: cannot parse type from param: " + param);
                    hasErrors = true;
                }

                if (type == ObjectType.Immutable)
                {
                    if (outputFileName == null) outputFileName = "I" + modelName + "Immutable";

                    line = paramTypeSplit.join("(get, never):").split("final ").join("var ") + ";";
                } else
                if (type == ObjectType.Mutable)
                {
                    if (outputFileName == null) outputFileName = "I" + modelName;

                    var char:String = paramFinalSplit[1].charAt(0).toUpperCase();
                    var methodNameWithType:String = char + paramFinalSplit[1].substring(1, paramFinalSplit[1].length);
                    line = param.substring(6, 0) + "set" + methodNameWithType;

                    var type:String = line.split(":")[1].split(";").join("");
                    var messageType:String = methodNameWithType.split(":")[0];
                    enumValueList.push("OnSet" + messageType);

                    line = line.split(":").join("(value:" + type + "):").split("):" + type).join("):I" + modelName);
                    line = line.split("final ").join("function ") + ";";
                } else
                if (type == ObjectType.Class)
                {
                    if (outputFileName == null) outputFileName = modelName;

                    var name:String = paramFinalSplit[1].substring(0, paramFinalSplit[1].indexOf(":"));
                    var u_name:String = name.charAt(0).toUpperCase() + name.substring(1, name.length);
                    var type:String = paramFinalSplit[1].split(":")[1].split(";").join("");
                    var messageType:String = "OnSet" + u_name;

                    line = getterTemplate.split("${name}").join(name).split("${type}").join(type) + sep(2);
                    line += setterTemplate.split("${name}").join(name).split("${u_name}").join(u_name)
                    .split("${type}").join(type).split("${model_name}").join(modelName)
                    .split("${enum_name}").join(enumName)
                    .split("${message_type}").join(messageType) + sep(2);

                    assign += "_" + name + " = " + data + "." + name + ";" + sep() + tab(2);
                }

                if (type != ObjectType.Enum)
                {
                    if (content == "") type != ObjectType.Class ? line += sep() + tab() : "";
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

            if (!StringUtils.isEmpty(line))
            {
                add = true;
            } else
            if (prevLine == null)
            {
                add = true;
            } else
            if (StringUtils.isEmpty(prevLine) || (nextLine.split("}").length == 2) || (prevLine.split("{").length == 2))
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

    private function getNewPackageName(typeDefFileName:String, isBase:Bool):String
    {
        return typeDefFileName.charAt(0).toLowerCase() +
            typeDefFileName.substring(1, typeDefFileName.length).split(".hx")[0] + (isBase ? ".gen" : "");
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

    private function tab(x:Int = 1):String
    {
        var out:String = "";

        for (i in 0...x)
        {
            out += "    ";
        }

        return out;
    }

    private function removeDuplicates(arr:Array<String>):Array<String>
    {
        var newArr:Array<String> = [];

        for (value in arr)
        {
            if (newArr.indexOf(value) == -1)
            {
                newArr.push(value);
            }
        }

        return newArr;
    }
}

typedef OutData = {
    var fileName:String;
    var data:String;
}

enum ObjectType
{
    Immutable;
    Mutable;
    Class;
    Enum;
}

class StringUtils
{
    public static function isEmpty(input:String):Bool
    {
        for (i in 0...input.length)
        {
            if (input.charAt(i) != " ")
            {
                return false;
            }
        }

        return true;
    }

    public static function removeAllEmptySpace(input:String):String
    {
        return input
        .split("          ").join("")
        .split("        ").join("")
        .split("    ").join("")
        .split("  ").join("")
        .split(" ").join("")
        .split(FileUtils.lineSeparator()).join("")
        .split("final").join("final ")
        .split("var").join("var ")
        .split("typedef").join("typedef ")
        .split("package").join("package ")
        .split("import").join("import ")
        .split("@Model").join(" @Model ");
    }
}