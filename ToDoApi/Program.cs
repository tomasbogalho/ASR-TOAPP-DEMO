using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace ToDoApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                    var backendIp = Environment.GetEnvironmentVariable("BACKEND_IP") ?? "localhost";
                    var backendPort = Environment.GetEnvironmentVariable("BACKEND_PORT") ?? "6002";
                    webBuilder.UseUrls($"http://{backendIp}:{backendPort}");
                });
    }
}