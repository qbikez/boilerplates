using Microsoft.Azure.Cosmos.Table;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

using Paylink.Models.Events;
using Paylink.Repositories;

using ReservationHandler.Infrastructure;
using ReservationHandler.Mappers;
using ReservationHandler.Processing;

using System;

[assembly: FunctionsStartup(typeof(ReservationHandler.Startup))]

namespace ReservationHandler
{
    public class Startup : FunctionsStartup
    {
        // configuring dependency injection. see: https://docs.microsoft.com/en-us/azure/azure-functions/functions-dotnet-dependency-injection
        public override void Configure(IFunctionsHostBuilder builder)
        {
            // builder.Services.AddScoped<MyService>();
        }
    }
}