using Wish.Common.Infrastructure;

namespace Wish.Web.Infrastructure
{
    internal class WebDatabaseConfiguration : IDatabaseConfiguration
    {
        public WebDatabaseConfiguration(string connection)
        {
            Connection = connection;
        }

        public string Connection { get; }
    }
}
