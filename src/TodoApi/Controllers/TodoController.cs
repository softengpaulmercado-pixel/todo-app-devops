using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TodoApi.Data;
using TodoApi.Models;

namespace TodoApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TodoController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<TodoController> _logger;

    public TodoController(AppDbContext db, ILogger<TodoController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Todo>>> GetAll()
    {
        _logger.LogInformation("Fetching all todos");
        var todos = await _db.Todos.ToListAsync();
        return Ok(todos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Todo>> GetById(int id)
    {
        var todo = await _db.Todos.FindAsync(id);
        if (todo == null)
        {
            _logger.LogWarning("Todo {id} not found", id);
            return NotFound();
        }
        return Ok(todo);
    }

    [HttpPost]
    public async Task<ActionResult<Todo>> Create([FromBody] CreateTodoDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            return BadRequest("Title is required");

        var todo = new Todo { Title = dto.Title, Completed = false };
        _db.Todos.Add(todo);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Created todo {id}", todo.Id);
        return CreatedAtAction(nameof(GetById), new { id = todo.Id }, todo);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTodoDto dto)
    {
        var todo = await _db.Todos.FindAsync(id);
        if (todo == null)
            return NotFound();

        todo.Title = dto.Title ?? todo.Title;
        todo.Completed = dto.Completed ?? todo.Completed;

        _db.Todos.Update(todo);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Updated todo {id}", id);
        return Ok(todo);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var todo = await _db.Todos.FindAsync(id);
        if (todo == null)
            return NotFound();

        _db.Todos.Remove(todo);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Deleted todo {id}", id);
        return NoContent();
    }
}

public record CreateTodoDto(string Title);
public record UpdateTodoDto(string? Title, bool? Completed);
