using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using DotNetEnv;

namespace ToDoApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Load environment variables from .env file
            Env.Load();

            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();

                    // Get backend IP and port from environment variables
                    var backendIp = Environment.GetEnvironmentVariable("BACKEND_IP") ?? "localhost";
                    var backendPort = Environment.GetEnvironmentVariable("BACKEND_PORT") ?? "6003";
                    var additionalIp1 = Environment.GetEnvironmentVariable("ADDITIONAL_IP1") ?? "10.0.3.4";
                    var additionalIp2 = Environment.GetEnvironmentVariable("ADDITIONAL_IP2") ?? "10.1.2.4";

                    webBuilder.UseUrls(
                        $"http://{backendIp}:{backendPort}",
                        $"http://{additionalIp1}:{backendPort}",
                        $"http://{additionalIp2}:{backendPort}"
                    );
                });
    }
}