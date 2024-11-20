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

                    // Validate IP address
                    if (!IsValidIp(backendIp))
                    {
                        throw new InvalidOperationException("Invalid IP address specified in environment variables.");
                    }

                    webBuilder.UseUrls($"http://{backendIp}:{backendPort}");
                });

        private static bool IsValidIp(string ip)
        {
            return System.Net.IPAddress.TryParse(ip, out _);
        }
    }
}