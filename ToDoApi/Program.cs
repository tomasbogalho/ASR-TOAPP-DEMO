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
                    webBuilder.UseUrls("http://localhost:6002","http://10.0.3.4:6002"); // Change the port to avoid conflict
                });
    }
}