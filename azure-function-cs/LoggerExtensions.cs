using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.ApplicationInsights;
using Paylink.Models.PaylinkInfos;

namespace Microsoft.Extensions.Logging
{
    public static class LoggerExtensions
    {
        public static void TagTelemetry(this TelemetryClient client, string key, string value)
        {
            client.Context.GlobalProperties[key] = value;
        }

        public static void TagTelemetry(this TelemetryClient client, object tags)
        {
            client.Context.GlobalProperties.AddRange(tags.AsDictionary());
        }

        public static IDisposable BeginScopeTagged(this ILogger logger, object scope)
            => logger.BeginScope(scope.AsDictionary());

        public static Dictionary<string, string> AsDictionary(this object tags)
            => tags.GetType().GetProperties().ToDictionary(p => p.Name, p => p.GetValue(tags)?.ToString());

        public static void AddRange(this IDictionary<string, string> dict, IEnumerable<KeyValuePair<string, string>> other)
        {
            foreach (var kvp in other)
            {
                dict[kvp.Key] = kvp.Value;
            }
        }
    }
}