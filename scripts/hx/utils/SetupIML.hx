package utils;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import hxp.Script;

/**
* Dependencies source processor
* Script is adding dependencies to all installed libraries,
* stores them in a project .iml file among with making its backup
* Adobe AIR runtime is required:
* https://get.adobe.com/air/
* Usage: haxelib run hxp SetupIML.hx [-Ddir=<path to prject>]
*
* -Ddir - Path to project directory. Current directory if omitted.
**/
class SetupIML extends Script
{
    private function isMac():Bool
    {
        return Sys.systemName().toLowerCase().indexOf("mac") != -1;
    }

    public function new()
    {
        super();

        // --- PROCESSING REGEXP
        var r = ~/\//g;
        var tr = ~/\r/g;
        var te = ~/      \r\n/g;

        var projectDir:String = Path.normalize(workingDirectory);
        if (defines.exists("dir"))
        {
            projectDir = Path.normalize(defines.get("dir"));
        }
        var projectPath:Array<String> = (r.replace(projectDir,"\\")).split('\\');
        Sys.setCwd(projectDir);

        var projectName:String = projectPath[projectPath.length - 1];
        var projectIML:String = projectDir + "/" + projectName + ".iml";
        var projectIMLBackup:String = projectDir + "/" + projectName + ".bak";

        trace("Project name: " + projectName + " @ " + projectDir);

        if (!FileSystem.exists(projectIML))
        {
            trace("No " + projectIML + " file detected.");
            Sys.exit(0);
        }

        var imlInitialContent:String = File.getContent(projectIML);
        if (FileSystem.exists(projectIMLBackup))
        {
            FileSystem.deleteFile(projectIMLBackup);
        }
        File.saveContent(projectIMLBackup, imlInitialContent);

        var xmlModule:Xml = Xml.parse(imlInitialContent).firstElement();
        for (cmp in xmlModule.elementsNamed("component"))
        {
            var xmlIterator:Iterator<Xml> = cmp.elementsNamed("content");
            for (nds in xmlIterator)
            {
                trace("Cleaning nodes...");
                for (ets in nds.elements())
                {
                    nds.removeChild(ets);
                }

                // --- ADD BASE
                //      <sourceFolder url="file://$MODULE_DIR$/src" isTestSource="false" />
                //      <excludeFolder url="file://$MODULE_DIR$/.haxelib" />
                //      <excludeFolder url="file://$MODULE_DIR$/.idea" />
                //      <excludeFolder url="file://$MODULE_DIR$/export" />
                var child:Xml = Xml.createElement('sourceFolder');
                child.set("url", "file://$MODULE_DIR$/src");
                child.set("isTestSource", "false");
                nds.addChild(child);

                child = Xml.createElement('excludeFolder');
                child.set("url", "file://$MODULE_DIR$/.haxelib");
                nds.addChild(child);

                child = Xml.createElement('excludeFolder');
                child.set("url", "file://$MODULE_DIR$/.idea");
                nds.addChild(child);

                child = Xml.createElement('excludeFolder');
                child.set("url", "file://$MODULE_DIR$/export");
                nds.addChild(child);

                // --- ADD LIBS
                var libsLog:String = projectDir + "/libs.log";
                Sys.command("haxelib list >" + libsLog);
                if (!FileSystem.exists(libsLog))
                {
                    trace("No " + libsLog + " file detected.");
                    Sys.exit(0);
                }
                var libsLogContentLines:Array<String> = File.getContent(libsLog).split("\n");
                for(line in libsLogContentLines)
                {
                    var libTitle:String = line.split(":")[0];
                    if (libTitle.length == 0)
                    {
                        continue;
                    }

                    var lineLibLog:String = projectDir + "/" + libTitle + ".log";
                    Sys.command("haxelib path " + libTitle + " >" + lineLibLog);
                    if (!FileSystem.exists(lineLibLog))
                    {
                        trace("No " + lineLibLog + " file detected.");
                        Sys.exit(0);
                    }

                    var lineLibLogContent:Array<String> = File.getContent(lineLibLog).split("\n");
                    var moduleDir:String = "file://$MODULE_DIR$/";
                    var lineLibPath:String = "";
                    for(line in lineLibLogContent)
                    {
                        if (r.replace(line,"\\").substr(0, projectDir.length) == r.replace(projectDir,"\\"))
                        {
                            lineLibPath = tr.replace(moduleDir + line.substring(projectDir.length + 1), "");

                            trace("Add: " + libTitle + " @ " + tr.replace(line.substring(projectDir.length + 1), ""));

                            child = Xml.createElement('sourceFolder');
                            child.set("url", lineLibPath);
                            child.set("isTestSource", "false");
                            nds.addChild(child);

                            break;
                        }
                    }
                    FileSystem.deleteFile(lineLibLog);
                }
                FileSystem.deleteFile(libsLog);
                break;
            }
        }

        File.saveContent(projectIML, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + te.replace(xmlModule.toString(), ""));
        trace("=================================");
        trace("Saved. All Dependencies been set.");
        trace("=================================");
    }
}