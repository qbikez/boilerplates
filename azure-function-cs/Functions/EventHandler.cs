// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using Paylink.Models.Events;
using Paylink.Models.Events.PayEvents;
using Newtonsoft.Json;
using Paylink.Models;
using Paylink.Models.PaylinkInfos;
using Paylink.Repositories;
using System.Collections.Generic;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights;

namespace ReservationHandler
{
    public class EventHandler
    {
        private readonly ILogger logger;
        private readonly TelemetryClient telemetryClient;

        public EventHandler(IPaylinkRepository paylinkRepository, ILoggerFactory loggerFactory, TelemetryConfiguration telemetryConfiguration)
        {
            this.paylinkRepository = paylinkRepository;
            // Use the same category as function-injected logger uses. see: https://github.com/Azure/azure-functions-host/issues/4689
            this.logger = loggerFactory.CreateLogger(Microsoft.Azure.WebJobs.Logging.LogCategories.CreateFunctionUserCategory("PaymentHandler"));
            // for logging event telemetry. see: https://docs.microsoft.com/en-us/azure/azure-functions/functions-dotnet-class-library?tabs=v2%2Ccmd#log-custom-telemetry-in-c-functions
            this.telemetryClient = new TelemetryClient(telemetryConfiguration);
        }

        [FunctionName("EventHandler")]
        public async Task Run([EventGridTrigger] EventGridEvent eventGridEvent)
        {
            await ProcessEvent(eventGridEvent);
        }

        private async Task ProcessEvent(EventGridEvent paymentEvent)
        {
            var envelope = JsonConvert.DeserializeAnonymousType(paymentEvent.Data.ToString(), new { message = "", tag = "tag" });

            using var scope = logger.BeginScopeTagged(new {
                scopeTag = envelope.tag
            });

            logger.LogInformation("processing event");
            telemetryClient.TrackEvent("processed", new {
                scopeTag = envelope.tag
            }.AsDictionary());            
        }
    }
}
