CREATE DATABASE clinica_veter;
USE clinica_veter;
CREATE TABLE dueños (    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(50));
CREATE TABLE veterinarios (    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    especialidad VARCHAR(30));
CREATE TABLE mascotas (    id INT AUTO_INCREMENT PRIMARY KEY,
    dueño_id INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    tipo_animal VARCHAR(20) NOT NULL,
    raza VARCHAR(30),
    FOREIGN KEY (dueño_id) REFERENCES dueños(id));
    CREATE TABLE citas (    id INT AUTO_INCREMENT PRIMARY KEY,
    mascota_id INT NOT NULL,
    veterinario_id INT NOT NULL,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    motivo VARCHAR(100),
    FOREIGN KEY (mascota_id) REFERENCES mascotas(id),
    FOREIGN KEY (veterinario_id) REFERENCES veterinarios(id));
    INSERT INTO dueños (nombre, telefono, email) VALUES 
('María González', '11-1234567', 'maria@gmail.com'),
('Carlos Pérez', '11-7654321', 'carlos@hotmail.com');
INSERT INTO mascotas (dueño_id, nombre, tipo_animal, raza) VALUES
(1, 'Firulais', 'Perro', 'Labrador'),
(2, 'Michi', 'Gato', 'Siamés');
INSERT INTO citas (mascota_id, veterinario_id, fecha, hora, motivo) VALUES
(1, 1, '2024-05-15', '10:30:00', 'Vacunación anual'),
(2, 2, '2024-05-16', '16:00:00', 'Revisión postoperatoria');
SELECT * FROM dueños;
SELECT m.nombre AS mascota, d.nombre AS dueño
FROM mascotas m
JOIN dueños d ON m.dueño_id = d.id;
SELECT 
    c.fecha,
    c.hora,
    m.nombre AS mascota,
    v.nombre AS veterinario,
    c.motivo
FROM citas c
JOIN mascotas m ON c.mascota_id = m.id
JOIN veterinarios v ON c.veterinario_id = v.id;