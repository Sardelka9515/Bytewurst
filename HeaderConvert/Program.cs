using CppAst;

namespace HeaderConvert
{
    internal static class Program
    {
        static void Main(string[] args)
        {
            var options = new CppParserOptions()
            {
                ParseComments = true,
                TargetCpu = CppTargetCpu.X86_64,
                TargetSystem = "windows"
            };

            options.IncludeFolders.Add("../box2d/include".ResolvePath());
            var conversion = new Conversion(options, "b2Ptr", "b2Func", "__BOX2D_INC__");
            var dir = "../box2d/include/box2d".ResolvePath();
            var files = Directory.GetFiles(dir).Select(p => p.ResolvePath()).ToList();
            File.WriteAllText("../inc/box2d.inc", conversion.Convert(files));

            conversion = new Conversion(options, "sfPtr", "sfFunc", "__CSFML_INC__");
            options.IncludeFolders.Add("../CSFML/include".ResolvePath());
            files = Directory.GetFiles("../CSFML/include".ResolvePath(), "*.h", SearchOption.AllDirectories).Select(p => p.ResolvePath()).ToList();
            File.WriteAllText("../inc/csfml.inc", conversion.Convert(files));

            conversion = new Conversion(options, "bwPtr", "bwFunc", "__HELPER_INC__");
            options.IncludeFolders.Add("../Bytewurst.Helper".ResolvePath());
            files = Directory.GetFiles("../Bytewurst.Helper".ResolvePath(), "*.h", SearchOption.AllDirectories).Select(p => p.ResolvePath()).ToList();
            files.ForEach(p => p.Replace('\\', '/'));
            File.WriteAllText("../inc/helper.inc", conversion.Convert(files));
        }
        public static string ResolvePath(this string path)
        {
            return Path.GetFullPath(path).Replace('\\', '/');
        }
    }
}
