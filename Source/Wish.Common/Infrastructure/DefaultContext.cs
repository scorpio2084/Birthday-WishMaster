using Microsoft.EntityFrameworkCore;

namespace Wish.Common.Infrastructure
{
    public class DefaultContext : DbContext
    {
        private readonly IDatabaseConfiguration _configuration;

        public DefaultContext(IDatabaseConfiguration configuration)
        {
            _configuration = configuration;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseSqlServer(_configuration.Connection);
        }
    }
}
