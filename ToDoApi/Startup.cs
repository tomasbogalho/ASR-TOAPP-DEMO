using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using System;
using Microsoft.Data.SqlClient; // Use Microsoft.Data.SqlClient
using ToDoApi.Models; // Add this for ToDoContext
using Microsoft.Extensions.Logging; // Add this for logging

namespace ToDoApi
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddDbContext<ToDoContext>(options =>
                options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));
            services.AddControllers();
            services.AddCors(options =>
            {
                options.AddPolicy("AllowAllOrigins",
                    builder => builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
            });

            // Add logging services
            services.AddLogging();

            // Test the database connection
            var connectionString = Configuration.GetConnectionString("DefaultConnection");
            if (!string.IsNullOrEmpty(connectionString))
            {
                TestDatabaseConnection(connectionString);
            }
            else
            {
                Console.WriteLine("Connection string is null or empty.");
            }
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseCors("AllowAllOrigins");

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }

        private void TestDatabaseConnection(string connectionString)
        {
            try
            {
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    Console.WriteLine("Database connection successful!");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Database connection failed: {ex.Message}");
            }
        }
    }
}