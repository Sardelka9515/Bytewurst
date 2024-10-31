using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using CppAst;

namespace HeaderConvert
{
    public partial class Conversion(CppParserOptions options, string pointerAlias, string functionPointerAlias)
    {
        public readonly Dictionary<string, string> TypeMappings = new() { { "int", "int32_t" } };
        public readonly HashSet<string> ReservedWords = ["type", "size", "width", "length", "segment", "cx", "code", "offset"];
        public readonly Dictionary<CppPrimitiveKind, string> PrimitiveTypeMappings = new()
        {
            {CppPrimitiveKind.Void, "void" },
            {CppPrimitiveKind.Bool, "bool" },
            {CppPrimitiveKind.Char, "char" },
            {CppPrimitiveKind.UnsignedChar, "uint8_t" },
            {CppPrimitiveKind.WChar, "wchar_t" },
            {CppPrimitiveKind.Short, "int16_t" },
            {CppPrimitiveKind.UnsignedShort, "uint16_t" },
            {CppPrimitiveKind.Int, "int32_t" },
            {CppPrimitiveKind.UnsignedInt, "uint32_t" },
            {CppPrimitiveKind.Long, "int32_t" },
            {CppPrimitiveKind.UnsignedLong, "uint32_t" },
            {CppPrimitiveKind.LongLong, "int64_t" },
            {CppPrimitiveKind.UnsignedLongLong, "uint64_t" },
            {CppPrimitiveKind.Float, "float" },
            {CppPrimitiveKind.Double, "double" }
        };
        public string Convert(List<string> files)
        {
            Console.WriteLine("Parsing files: " + string.Join(", ", files));
            var compilation = CppParser.ParseFiles(files, options);

            foreach (var message in compilation.Diagnostics.Messages)
                Console.WriteLine(message);

            if (compilation.HasErrors)
            {
                throw new Exception("Compilation failed");
            }

            var resultSb = new StringBuilder();
            if (options.TargetCpu == CppTargetCpu.X86_64)
            {
                resultSb.AppendLine(pointerAlias + " EQU <QWORD>");
                resultSb.AppendLine(functionPointerAlias + " EQU <QWORD>");
            }
            else if (options.TargetCpu == CppTargetCpu.X86)
            {
                resultSb.AppendLine(pointerAlias + " EQU <DWORD>");
                resultSb.AppendLine(functionPointerAlias + " EQU <DWORD>");
            }
            resultSb.AppendLine();

            Console.WriteLine("Converting typedef...");
            resultSb.AppendLine("; Typedefs");
            foreach (var cppTypedef in compilation.Typedefs)
            {
                string? comment = null;
                var line = $"{cppTypedef.Name} EQU <{ResolveTypeName(cppTypedef.ElementType, ref comment)}>";
                if (comment != null)
                {
                    resultSb.AppendLine("; " + comment);
                }
                resultSb.AppendLine(line);
                resultSb.AppendLine();
            }
            resultSb.AppendLine();

            Console.WriteLine("Converting enum...");
            resultSb.AppendLine("; Enums");
            foreach (var e in compilation.Enums)
            {
                TypeMappings.Add(e.Name, "DWORD");
                resultSb.AppendLine($"; {e.Name} ENUM ");
                foreach (var b2enumItem in e.Items)
                    resultSb.AppendLine("\t" + b2enumItem.Name + " EQU " + b2enumItem.Value);
                resultSb.AppendLine($"; {e.Name} ENDE ");
                resultSb.AppendLine();
            }
            resultSb.AppendLine();

            Console.WriteLine("Converting functions...");
            resultSb.AppendLine("; Functions");
            foreach (var function in compilation.Functions)
            {
                if (operatorRegexFunc().IsMatch(function.Name))
                {
                    Console.WriteLine("Skipping operator function: " + function.Name);
                    continue;
                }
                resultSb.AppendLine("; " + string.Join(", ", function.Parameters.Select(p => p.Name + ":" + p.Type.GetDisplayName())));
                resultSb.AppendLine($"{function.Name} PROTO");
                resultSb.AppendLine();
            }
            resultSb.AppendLine();

            Console.WriteLine("Converting structs and unions...");
            resultSb.AppendLine("; Structs");
            var structTypes = compilation.Classes.Where(c => c.TypeKind == CppTypeKind.StructOrClass).Select(c => c.Name).ToHashSet();
            // Print All classes, structs
            foreach (var cppClass in compilation.Classes)
            {
                string kind;
                if (cppClass.ClassKind == CppClassKind.Struct)
                {
                    kind = "STRUCT";
                }
                else if (cppClass.ClassKind == CppClassKind.Union)
                {
                    kind = "UNION";
                }
                else
                {
                    throw new NotImplementedException();
                }
                resultSb.AppendLine($"{cppClass.Name} {kind} 16");
                int unionCount = 0;
                int indentionLevel = 1;
                foreach (var field in cppClass.Fields)
                {
                    resultSb.AppendLine(GetFieldText(field, structTypes, ref unionCount, ref indentionLevel));
                }
                resultSb.AppendLine($"{cppClass.Name} ENDS");
                resultSb.AppendLine();
            }
            resultSb.AppendLine();


            return resultSb.ToString();
        }

        string GetFieldText(CppField field, HashSet<string> structTypes, ref int unionCount, ref int indentionLevel)
        {
            string? comment = null;
            var typeName = field.Type.GetDisplayName();
            var fieldName = field.Name;

            if (ReservedWords.Contains(fieldName.ToLower()))
            {
                fieldName = "_" + fieldName;
            }

            string? line = null;
            if (field.Type.TypeKind == CppTypeKind.Array)
            {
                CppArrayType arrayType = (CppArrayType)field.Type;
                typeName = arrayType.ElementType.GetDisplayName();
                var size = arrayType.Size;
                typeName = ResolveTypeName(arrayType.ElementType, ref comment);
                var valueInitializer = structTypes.Contains(typeName) ? "<>" : "?";
                line = new string('\t', indentionLevel) + $"{fieldName} {typeName} {size} DUP({valueInitializer})";
            }
            else
            {
                string valueInitializer = "?";
                if (field.Type.TypeKind == CppTypeKind.StructOrClass)
                {
                    valueInitializer = "<>";
                    var classType = (CppClass)field.Type;
                    if (classType.ClassKind == CppClassKind.Class)
                    {
                        throw new NotImplementedException();
                    }
                    if (classType.ClassKind == CppClassKind.Union)
                    {
                        var unionSb = new StringBuilder();

                        for (int i = 0; i < indentionLevel; i++)
                        {
                            unionSb.Append('\t');
                        }
                        unionSb.AppendLine($"UNION union_{unionCount++}");

                        indentionLevel++;
                        foreach (var unionField in classType.Fields)
                        {
                            unionSb.AppendLine(GetFieldText(unionField, structTypes, ref unionCount, ref indentionLevel));
                        }
                        indentionLevel--;

                        for (int i = 0; i < indentionLevel; i++)
                        {
                            unionSb.Append('\t');
                        }
                        unionSb.AppendLine("ENDS");

                        line = unionSb.ToString();
                    }
                }
                else
                {
                    typeName = ResolveTypeName(field.Type, ref comment);
                }
                line ??= new string('\t', indentionLevel) + $"{fieldName} {typeName} {valueInitializer}";
            }

            if (comment != null)
            {
                line += "\t; " + comment;
            }
            return line;
        }

        string ResolveTypeName(CppType type, ref string? comment)
        {
            var typeName = type.GetDisplayName();
            if (type.TypeKind == CppTypeKind.Pointer)
            {
                comment += typeName;
                typeName = pointerAlias;
            }
            else if (type.TypeKind == CppTypeKind.Function)
            {
                comment += typeName;
                typeName = functionPointerAlias;
            }
            else if (type.TypeKind == CppTypeKind.Primitive)
            {
                var primitiveType = (CppPrimitiveType)type;
                if (PrimitiveTypeMappings.TryGetValue(primitiveType.Kind, out var newType))
                {
                    typeName = newType;
                }
                else
                {
                    throw new NotImplementedException("No mapping found for primitive type: " + primitiveType.Kind.ToString());
                }
            }
            else if (TypeMappings.TryGetValue(typeName, out var newType))
            {
                comment += typeName;
                typeName = newType;
            }
            return typeName;
        }

        [GeneratedRegex(@"operator\W+")]
        private static partial Regex operatorRegexFunc();
    }
}
