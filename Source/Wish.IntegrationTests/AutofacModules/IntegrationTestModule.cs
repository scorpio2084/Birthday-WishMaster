using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Reflection;
using Autofac;
using Wish.IntegrationTests.Infrastructure;
using Module = Autofac.Module;

namespace Wish.IntegrationTests.AutofacModules
{
    internal class IntegrationTestModule : Module
    {
        private readonly ModuleRegistry _registry;

        public IntegrationTestModule()
        {
            _registry = new ModuleRegistry();
        }

        protected override void Load(ContainerBuilder builder)
        {
            RegisterModules(builder);

            builder.Register(c =>
            {
                var connection = ConfigurationManager.ConnectionStrings["DefaultConnection"]?.ConnectionString;

                if (string.IsNullOrEmpty(connection))
                {
                    throw new NullReferenceException("Integration test connection string is not defined.");
                }

                var result = new IntegrationDatabaseConfiguration(connection);

                return result;
            })
            .SingleInstance();

        }

        private static string GetModulePath()
        {
            var pluginPath = Path.Combine(GetAppPath());

            return pluginPath;
        }

        private static string GetAppPath()
        {
            return string.IsNullOrEmpty(AppDomain.CurrentDomain.RelativeSearchPath)
                ? AppDomain.CurrentDomain.BaseDirectory
                : AppDomain.CurrentDomain.RelativeSearchPath;
        }

        private void RegisterModules(ContainerBuilder builder)
        {
            var directories = new List<DirectoryInfo>
            {
                new DirectoryInfo(GetAppPath())
            };

            var modules = new DirectoryInfo(GetModulePath());

            if (modules.Exists)
            {
                directories.Add(modules);
            }

            RegisterModulesInDirectories(directories, builder);
        }

        private void RegisterModulesInDirectories(
            IEnumerable<DirectoryInfo> directories,
            ContainerBuilder builder)
        {
            foreach (var directory in directories)
            {
                RegisterModulesInDirectory(directory, builder);
            }
        }

        private void RegisterModulesInDirectory(
            DirectoryInfo directory,
            ContainerBuilder builder)
        {
            foreach (var assembly in directory.GetFiles("*.dll"))
            {
                RegisterModulesInAssembly(assembly, builder);
            }
        }

        private void RegisterModulesInAssembly(
            FileSystemInfo file,
            ContainerBuilder builder)
        {
            try
            {
                if (!file.Name.Contains("Wish") ||
                    file.Name.Contains("Wish.Web") ||
                    file.Name.Contains("IntegrationTests.dll"))
                {
                    return;
                }

                if (_registry.IsRegistered(file.FullName))
                {
                    return;
                }

                var assembly = Assembly.Load(AssemblyName.GetAssemblyName(file.FullName));

                builder.RegisterAssemblyModules(assembly);

                _registry.Register(file.FullName);
            }
            catch (Exception)
            {
                // ignored
            }
        }

        internal class ModuleRegistry
        {
            private readonly IDictionary<string, bool> _registry;

            public ModuleRegistry()
            {
                _registry = new Dictionary<string, bool>();
            }

            public void Register(string module)
            {
                _registry.Add(module, true);
            }

            public bool IsRegistered(string module)
            {
                bool found;

                return _registry.TryGetValue(module, out found);
            }
        }
    }
}
