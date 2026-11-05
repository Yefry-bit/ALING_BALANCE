namespace AlingBalance.Api.Validation;

/// <summary>Acumula los errores de validación por campo.</summary>
public sealed class ErrorBag
{
    private readonly Dictionary<string, List<string>> _errors = new();

    public bool HasErrors => _errors.Count > 0;

    public bool Has(string field) => _errors.ContainsKey(field);

    /// <summary>Agrega un mensaje; si es null (dato válido) no hace nada.</summary>
    public void Add(string field, string? message)
    {
        if (message is null)
        {
            return;
        }

        if (!_errors.TryGetValue(field, out var list))
        {
            list = new List<string>();
            _errors[field] = list;
        }

        list.Add(message);
    }

    public Dictionary<string, string[]> ToDictionary()
    {
        return _errors.ToDictionary(pair => pair.Key, pair => pair.Value.ToArray());
    }
}
