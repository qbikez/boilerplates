using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver;

namespace My.Namespace.Db
{
    public class MongoContext : IDisposable
    {
        private readonly string _dbName;
        private MongoClient _client;

        public MongoContext(string connectionString, string dbName = null, int timeout = 3000)
        {
            MongoUrl url = new MongoUrl(connectionString);
            _dbName = dbName ?? url.DatabaseName;

            var settings = MongoClientSettings.FromUrl(url);
            settings.ConnectTimeout = TimeSpan.FromMilliseconds(timeout);
            
            _client = new MongoClient(settings);            
        }

        public IMongoDatabase Database => _client.GetDatabase(_dbName);
        //public IMongoCollection<MyPOCO> SomeCollection => Database.GetCollection<MyPOCO>("some_collection");
        
        public void Dispose()
        {
            _client = null;            
        }

        public override string ToString()
        {
            return $"{_client.Settings.Server.ToString()}/{_dbName}";
        }
    }

    public interface IHasId {
        Guid Id {get;set;}
    }
    public static class MongoCollectionExtensions {
        public static async Task StoreAsync<TObj>(this IMongoCollection<TObj> collection, TObj obj)
            where TObj : IHasId
        {
            await collection.ReplaceOneAsync(c => c.Id == obj.Id, obj, new UpdateOptions()
            {
                IsUpsert = true
            });
        }
    }
}
