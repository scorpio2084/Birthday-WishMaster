using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Autofac;
using Autofac.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyModel;
using Microsoft.Extensions.Logging;
using Wish.Web.Infrastructure;

namespace Wish.Web
{
    public class Startup
    {
        public Startup(IHostingEnvironment env)
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(env.ContentRootPath)
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true)
                .AddEnvironmentVariables();
            Configuration = builder.Build();
        }

        public IConfigurationRoot Configuration { get; }

        public IContainer ApplicationContainer { get; set; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public IServiceProvider ConfigureServices(IServiceCollection services)
        {
            // Add framework services.
            services.AddMvc();

            ApplicationContainer = CreateApplicationContainer(services);

            return new AutofacServiceProvider(ApplicationContainer);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(
            IApplicationBuilder app, 
            IHostingEnvironment env, 
            ILoggerFactory loggerFactory,
            IApplicationLifetime appLifetime)
        {
            loggerFactory.AddConsole(Configuration.GetSection("Logging"));
            loggerFactory.AddDebug();

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
            }

            app.UseStaticFiles();

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Home}/{action=Index}/{id?}");
            });

            appLifetime.ApplicationStopped.Register(() => ApplicationContainer.Dispose());
        }

        private IContainer CreateApplicationContainer(IServiceCollection services)
        {
            var builder = new ContainerBuilder();

            RegisterReferencedAssemblies(builder);

            builder.Register(c => new WebDatabaseConfiguration(Configuration.GetConnectionString("DefaultConnection")));

            builder.Populate(services);

            return builder.Build();
        }

        private static void RegisterReferencedAssemblies(ContainerBuilder builder)
        {
            var assemblies = GetReferencedAssemblies();

            builder.RegisterAssemblyModules(assemblies.ToArray());
        }

        private static IEnumerable<Assembly> GetReferencedAssemblies()
        {
            return DependencyContext.Default.CompileLibraries
                .Where(x => x.Name.Contains("Wish"))
                .Select(x => Assembly.Load(new AssemblyName(x.Name)));
        }
    }
}
