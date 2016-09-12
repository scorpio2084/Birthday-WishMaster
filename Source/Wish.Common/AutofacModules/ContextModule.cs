
using Autofac;
using Wish.Common.Infrastructure;

namespace Wish.Common.AutofacModules
{
    internal class ContextModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<DefaultContext>()
                .AsSelf()
                .InstancePerLifetimeScope();
        }
    }
}
