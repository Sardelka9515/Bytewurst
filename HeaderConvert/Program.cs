﻿using CppAst;

namespace HeaderConvert
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var options = new CppParserOptions()
            {
                ParseComments = true,
                TargetCpu = CppTargetCpu.X86_64,
                TargetSystem = "windows"
            };

            var conversion = new Conversion(options, "b2ptr", "func");


            var dir = Path.GetFullPath("../box2d/include/box2d");
            var files = Directory.GetFiles(dir).ToList();
            File.WriteAllText("../box2d.inc", conversion.Convert(files));

            options.IncludeFolders.Add(Path.GetFullPath("../include"));
            files = Directory.GetFiles(Path.GetFullPath("../include/SFML"), "*.h", SearchOption.AllDirectories).ToList();
            File.WriteAllText("../csfml.inc", conversion.Convert(files));
        }
    }
}