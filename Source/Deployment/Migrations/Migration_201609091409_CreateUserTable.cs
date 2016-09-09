using FluentMigrator;

namespace Wish.Deployment.Migrations
{
    // by: Timothy Simmons 
    [Migration(201609091409)]
    // ReSharper disable once InconsistentNaming
    // TODO: let resharper rename the file to match the class name. Also delete this comment.
    public class Migration_201609091409_CreateUserTable : Migration
    {
        public override void Up()
        {
            Create.Table("User")
                .WithColumn("Id").AsGuid().PrimaryKey()
                .WithColumn("Username").AsString(200);
        }

        public override void Down()
        {
            Delete.Table("User");
        }
    }
}