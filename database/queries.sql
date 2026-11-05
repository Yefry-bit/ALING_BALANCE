-- =====================================================================
-- AlingBalance - Consultas útiles (funcionan en SQLite y SQL Server)
-- =====================================================================

-- 1) Todos los servicios, del más reciente al más antiguo
SELECT s.Operation, s.Plate, s.Vehicle, s.ServiceType, s.Status, s.Price,
       s.EmployeeName, s.RegisteredBy
FROM Services s
ORDER BY s.Operation DESC;

-- 2) Servicios en proceso
SELECT Operation, Plate, ServiceType, EmployeeName
FROM Services
WHERE Status = 'En proceso';

-- 3) Comisión por empleado: 30 % del precio de los servicios TERMINADOS
SELECT e.Name                                    AS Empleado,
       COUNT(s.Operation)                        AS ServiciosTerminados,
       SUM(s.Price)                              AS ValorTrabajado,
       ROUND(SUM(s.Price) * 0.30, 0)             AS Comision
FROM Employees e
JOIN Services s ON s.EmployeeId = e.Id AND s.Status = 'Terminado'
GROUP BY e.Id, e.Name
ORDER BY Comision DESC;

-- 4) Total de dinero por tipo de servicio
SELECT ServiceType, COUNT(*) AS Cantidad, SUM(Price) AS Total
FROM Services
GROUP BY ServiceType
ORDER BY Total DESC;

-- 5) Servicios sin empleado asignado (no generan comisión)
SELECT Operation, Plate, ServiceType, Price
FROM Services
WHERE EmployeeId IS NULL;

-- 6) Usuarios y su rol
SELECT Name, Username, Role, Active FROM Users ORDER BY Name;
