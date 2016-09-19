using System;
using System.Linq;

namespace MyTestApp
{
    public class Program
    {
        public static string ExecutableName = $"{typeof(Program).Namespace}.exe";
        public static int Main(string[] args)
        {
            if (args.Contains("--debug")) {
                System.Diagnostics.Debugger.Launch();
                args = args.Where(a => a != "--debug").ToArray();                
            }
            Console.WriteLine("starting Xunit tests");
            if (args.Count(a => !a.StartsWith("-")) == 0) {
                var l = args.ToList();
                
                l.Add(ExecutableName);
                args = l.ToArray();

            }
            using (var program = new  Xunit.Runner.DotNet.Program()) {
                return program.Run(args);
            }
        }
    }
}
