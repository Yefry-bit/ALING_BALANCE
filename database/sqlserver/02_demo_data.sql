-- =====================================================================
-- AlingBalance - Datos de ejemplo (SQL Server). Ejecutar DESPUÉS de 01_schema.sql
-- Agrega: 1 usuario empleado (maria / clave123), 3 empleados y 6 servicios.
-- =====================================================================
USE AlingBalance;
GO

INSERT INTO dbo.Users ([Name], Username, PasswordHash, [Role], Active, CreatedAt)
VALUES (N'María Gómez', N'maria', N'210000.z13ebFmT1keEG98WGJdOHQ==.saxIyqJqdPVGGDMxUs7HDCVLdP36OTV+mB1T/eVkA/4=', N'empleado', 1, SYSUTCDATETIME());

INSERT INTO dbo.Employees ([Name], Document, Phone, Active, CreatedAt) VALUES (N'Carlos Pérez', N'1001234567', N'3001234567', 1, SYSUTCDATETIME());
INSERT INTO dbo.Employees ([Name], Document, Phone, Active, CreatedAt) VALUES (N'Luis Martínez', N'1007654321', N'3109876543', 1, SYSUTCDATETIME());
INSERT INTO dbo.Employees ([Name], Document, Phone, Active, CreatedAt) VALUES (N'Andrés Gómez', N'1012345678', N'', 0, SYSUTCDATETIME());

INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'ABC-123', N'Chevrolet Spark', N'Particular', N'Alineación sencilla', N'Terminado', 20000, '2026-10-20 14:10:00', N'Administrador', 1, N'Carlos Pérez');
INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'DEF-456', N'Toyota Hilux', N'Camioneta', N'Balanceo', N'En proceso', 50000, '2026-10-21 09:30:00', N'María Gómez', 2, N'Luis Martínez');
INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'GHI-789', N'Renault Logan', N'Taxi', N'Montaje de llantas', N'Terminado', 15000, '2026-10-21 11:45:00', N'María Gómez', 1, N'Carlos Pérez');
INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'JKL-321', N'Mazda CX-5', N'Camioneta', N'Alineación doble', N'Terminado', 50000, '2026-10-22 16:00:00', N'Administrador', 2, N'Luis Martínez');
INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'MNO-654', N'Kia Picanto', N'Taxi', N'Nitrógeno', N'En proceso', 20000, '2026-10-23 08:15:00', N'María Gómez', 1, N'Carlos Pérez');
INSERT INTO dbo.Services (Plate, Vehicle, VehicleType, ServiceType, [Status], Price, [Date], RegisteredBy, EmployeeId, EmployeeName) VALUES (N'PQR-987', N'Hyundai Accent', N'Particular', N'Rines', N'Terminado', 50000, '2026-10-23 10:20:00', N'Administrador', 2, N'Luis Martínez');
GO
