-- =====================================================================
-- AlingBalance - Datos de ejemplo (SQLite). Ejecutar DESPUÉS de schema.sql
-- Uso:  sqlite3 alingbalance.db < demo_data.sql
-- Agrega: 1 usuario empleado (maria / clave123), 3 empleados y 6 servicios.
-- =====================================================================
PRAGMA foreign_keys = ON;

INSERT INTO "Users" ("Name","Username","PasswordHash","Role","Active","CreatedAt")
VALUES ('María Gómez','maria','210000.z13ebFmT1keEG98WGJdOHQ==.saxIyqJqdPVGGDMxUs7HDCVLdP36OTV+mB1T/eVkA/4=','empleado',1,datetime('now'));

INSERT INTO "Employees" ("Name","Document","Phone","Active","CreatedAt") VALUES ('Carlos Pérez','1001234567','3001234567',1,datetime('now'));
INSERT INTO "Employees" ("Name","Document","Phone","Active","CreatedAt") VALUES ('Luis Martínez','1007654321','3109876543',1,datetime('now'));
INSERT INTO "Employees" ("Name","Document","Phone","Active","CreatedAt") VALUES ('Andrés Gómez','1012345678','',0,datetime('now'));

INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('ABC-123','Chevrolet Spark','Particular','Alineación sencilla','Terminado',20000,'2026-10-20 14:10:00','Administrador',1,'Carlos Pérez');
INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('DEF-456','Toyota Hilux','Camioneta','Balanceo','En proceso',50000,'2026-10-21 09:30:00','María Gómez',2,'Luis Martínez');
INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('GHI-789','Renault Logan','Taxi','Montaje de llantas','Terminado',15000,'2026-10-21 11:45:00','María Gómez',1,'Carlos Pérez');
INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('JKL-321','Mazda CX-5','Camioneta','Alineación doble','Terminado',50000,'2026-10-22 16:00:00','Administrador',2,'Luis Martínez');
INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('MNO-654','Kia Picanto','Taxi','Nitrógeno','En proceso',20000,'2026-10-23 08:15:00','María Gómez',1,'Carlos Pérez');
INSERT INTO "Services" ("Plate","Vehicle","VehicleType","ServiceType","Status","Price","Date","RegisteredBy","EmployeeId","EmployeeName") VALUES ('PQR-987','Hyundai Accent','Particular','Rines','Terminado',50000,'2026-10-23 10:20:00','Administrador',2,'Luis Martínez');
