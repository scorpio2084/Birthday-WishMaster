using Wish.Common.Infrastructure;

namespace Wish.IntegrationTests.Infrastructure
{
    internal class IntegrationDatabaseConfiguration : IDatabaseConfiguration
    {
        public IntegrationDatabaseConfiguration(string connection)
        {
            Connection = connection;
        }

        public string Connection { get; }
    }
}

