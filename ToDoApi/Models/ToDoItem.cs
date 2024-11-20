// Models/ToDoItem.cs
namespace ToDoApi.Models
{
    public class ToDoItem
    {
        public int Id { get; set; }
        public string? Description { get; set; } // Make Description nullable
        public bool IsCompleted { get; set; }
    }
}