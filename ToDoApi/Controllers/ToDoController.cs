using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;
using ToDoApi.Models;

namespace ToDoApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ToDoController : ControllerBase
    {
        private readonly ToDoContext _context;

        public ToDoController(ToDoContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ToDoItem>>> GetToDoItems()
        {
            return await _context.ToDoItems.ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<ToDoItem>> PostToDoItem(ToDoItem item)
        {
            _context.ToDoItems.Add(item);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetToDoItems), new { id = item.Id }, item);
        }
    }
}