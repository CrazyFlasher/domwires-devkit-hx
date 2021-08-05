package utils;

import sys.FileSystem;

class FileUtils
{
    public static function deleteWithFiles(path:String):Void
    {
        if (FileSystem.exists(path) && FileSystem.isDirectory(path))
        {
            for (filePath in FileSystem.readDirectory(path))
            {
                if (FileSystem.isDirectory(path + "/" + filePath))
                {
                    deleteWithFiles(path + "/" + filePath);
                } else
                {
                    trace("Delete file: " + filePath);

                    FileSystem.deleteFile(path + "/" + filePath);
                }
            }

            trace("Delete dir: " + path);
            FileSystem.deleteDirectory(path);
        }
    }
}