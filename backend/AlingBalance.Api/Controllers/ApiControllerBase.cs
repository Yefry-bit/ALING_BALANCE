using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Mvc;

namespace AlingBalance.Api.Controllers;

/// <summary>Base de los controladores con respuestas de error uniformes.</summary>
public abstract class ApiControllerBase : ControllerBase
{
    /// <summary>400 con la lista de errores por campo.</summary>
    protected IActionResult Invalid(ErrorBag errors)
    {
        return ValidationProblem(new ValidationProblemDetails(errors.ToDictionary())
        {
            Status = StatusCodes.Status400BadRequest,
        });
    }

    /// <summary>Error con un mensaje claro en el campo "detail".</summary>
    protected IActionResult Fail(int statusCode, string detail)
    {
        return Problem(detail: detail, statusCode: statusCode);
    }
}
