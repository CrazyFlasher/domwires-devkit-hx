package utils;

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