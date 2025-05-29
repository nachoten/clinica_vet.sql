USE clinica_veter;

-- Vista 1: Información completa de citas
CREATE OR REPLACE VIEW vista_citas_completas AS
SELECT 
    c.id AS cita_id,
    c.fecha,
    c.hora,
    c.motivo,
    m.nombre AS nombre_mascota,
    m.tipo_animal,
    m.raza,
    d.nombre AS nombre_dueño,
    d.telefono AS telefono_dueño,
    v.nombre AS nombre_veterinario,
    v.especialidad
FROM 
    citas c
JOIN 
    mascotas m ON c.mascota_id = m.id
JOIN 
    dueños d ON m.dueño_id = d.id
JOIN 
    veterinarios v ON c.veterinario_id = v.id;

-- Vista 2: Mascotas con sus dueños
CREATE OR REPLACE VIEW vista_mascotas_por_dueño AS
SELECT 
    d.id AS dueño_id,
    d.nombre AS nombre_dueño,
    d.telefono,
    d.email,
    m.id AS mascota_id,
    m.nombre AS nombre_mascota,
    m.tipo_animal,
    m.raza
FROM 
    mascotas m
JOIN 
    dueños d ON m.dueño_id = d.id
ORDER BY 
    d.nombre, m.nombre;

-- Vista 3: Citas próximas (7 días)
CREATE OR REPLACE VIEW vista_citas_proximas AS
SELECT 
    c.id AS cita_id,
    c.fecha,
    c.hora,
    c.motivo,
    m.nombre AS nombre_mascota,
    v.nombre AS nombre_veterinario
FROM 
    citas c
JOIN 
    mascotas m ON c.mascota_id = m.id
JOIN 
    veterinarios v ON c.veterinario_id = v.id
WHERE 
    c.fecha BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY 
    c.fecha, c.hora;


-- Función 1: Contar mascotas por dueño
DELIMITER //
CREATE FUNCTION contar_mascotas_por_dueño(p_dueño_id INT) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_mascotas INT;
    
    SELECT COUNT(*) INTO total_mascotas
    FROM mascotas
    WHERE dueño_id = p_dueño_id;
    
    RETURN total_mascotas;
END //
DELIMITER ;

-- Función 2: Verificar disponibilidad de veterinario
DELIMITER //
CREATE FUNCTION verificar_disponibilidad_veterinario(
    p_veterinario_id INT, 
    p_fecha DATE, 
    p_hora TIME
) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE disponible BOOLEAN;
    
    SELECT COUNT(*) = 0 INTO disponible
    FROM citas
    WHERE veterinario_id = p_veterinario_id
    AND fecha = p_fecha
    AND hora = p_hora;
    
    RETURN disponible;
END //
DELIMITER ;

-- SP 1: Agendar cita
DELIMITER //
CREATE PROCEDURE sp_agendar_cita(
    IN p_mascota_id INT,
    IN p_veterinario_id INT,
    IN p_fecha DATE,
    IN p_hora TIME,
    IN p_motivo VARCHAR(255),
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE veterinario_disponible BOOLEAN;
    
    -- Verificar disponibilidad
    SET veterinario_disponible = verificar_disponibilidad_veterinario(p_veterinario_id, p_fecha, p_hora);
    
    IF veterinario_disponible THEN
        INSERT INTO citas (mascota_id, veterinario_id, fecha, hora, motivo)
        VALUES (p_mascota_id, p_veterinario_id, p_fecha, p_hora, p_motivo);
        
        SET p_resultado = 'Cita agendada exitosamente';
    ELSE
        SET p_resultado = 'El veterinario no está disponible en ese horario';
    END IF;
END //
DELIMITER ;

-- SP 2: Actualizar datos de dueño
DELIMITER //
CREATE PROCEDURE sp_actualizar_datos_dueño(
    IN p_dueño_id INT,
    IN p_nuevo_telefono VARCHAR(20),
    IN p_nuevo_email VARCHAR(100)
)
BEGIN
    UPDATE dueños
    SET 
        telefono = p_nuevo_telefono,
        email = p_nuevo_email
    WHERE 
        id = p_dueño_id;
END //
DELIMITER ;

-- Trigger 1: Validar horario de cita
DELIMITER //
CREATE TRIGGER tr_validar_hora_cita
BEFORE INSERT ON citas
FOR EACH ROW
BEGIN
    DECLARE hora_inicio TIME DEFAULT '08:00:00';
    DECLARE hora_fin TIME DEFAULT '18:00:00';
    
    IF NEW.hora < hora_inicio OR NEW.hora > hora_fin THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las citas solo pueden agendarse entre 8:00 y 18:00 horas';
    END IF;
END //
DELIMITER ;

-- Trigger 2: Registrar cambio de dueño (necesita tabla historial_mascotas)
DELIMITER //
CREATE TRIGGER tr_registrar_cambio_dueño
AFTER UPDATE ON mascotas
FOR EACH ROW
BEGIN
    IF OLD.dueño_id != NEW.dueño_id THEN
        INSERT INTO historial_mascotas (mascota_id, antiguo_dueño_id, nuevo_dueño_id, fecha_cambio)
        VALUES (NEW.id, OLD.dueño_id, NEW.dueño_id, NOW());
    END IF;
END //
DELIMITER ;
USE clinica_veter;
-- Insercion de datos sql
INSERT INTO dueños (nombre, telefono, email) VALUES
('Juan Pérez', '555-1234', 'juan.perez@email.com'),
('María García', '555-5678', 'maria.garcia@email.com'),
('Carlos López', '555-9012', 'carlos.lopez@email.com'),
('Ana Martínez', '555-3456', 'ana.martinez@email.com'),
('Luis Rodríguez', '555-7890', 'luis.rodriguez@email.com');


INSERT INTO veterinarios (nombre, especialidad, telefono, email) VALUES
('Dr. Roberto Sánchez', 'Cirugía', '555-1111', 'roberto.sanchez@vet.com'),
('Dra. Laura Fernández', 'Dermatología', '555-2222', 'laura.fernandez@vet.com'),
('Dr. Jorge Ramírez', 'Cardiología', '555-3333', 'jorge.ramirez@vet.com'),
('Dra. Sofía Castro', 'Oftalmología', '555-4444', 'sofia.castro@vet.com');


INSERT INTO mascotas (dueño_id, nombre, tipo_animal, raza, fecha_nacimiento) VALUES
(1, 'Max', 'Perro', 'Labrador', '2018-05-15'),
(1, 'Luna', 'Gato', 'Siamés', '2019-11-20'),
(2, 'Rocky', 'Perro', 'Bulldog', '2020-03-10'),
(3, 'Milo', 'Gato', 'Persa', '2017-07-22'),
(4, 'Bella', 'Perro', 'Golden Retriever', '2019-01-30'),
(5, 'Simba', 'Gato', 'Mestizo', '2021-02-14');

----------------------
-- Citas pasadas
INSERT INTO citas (mascota_id, veterinario_id, fecha, hora, motivo) VALUES
(1, 1, '2023-10-01', '10:00:00', 'Consulta rutinaria'),
(2, 2, '2023-10-02', '11:30:00', 'Problemas de piel'),
(3, 3, '2023-10-03', '09:00:00', 'Chequeo cardíaco'),
(4, 4, '2023-10-04', '15:00:00', 'Problemas oculares');

-- Citas futuras (próximos 7 días)
INSERT INTO citas (mascota_id, veterinario_id, fecha, hora, motivo) VALUES
(5, 1, CURDATE() + INTERVAL 1 DAY, '10:30:00', 'Vacunación anual'),
(6, 2, CURDATE() + INTERVAL 2 DAY, '14:00:00', 'Dermatitis'),
(1, 3, CURDATE() + INTERVAL 3 DAY, '16:30:00', 'Seguimiento'),
(3, 4, CURDATE() + INTERVAL 5 DAY, '11:00:00', 'Control postoperatorio');



INSERT INTO historial_mascotas (mascota_id, antiguo_dueño_id, nuevo_dueño_id, fecha_cambio) VALUES
(2, 1, 2, '2023-09-15 14:30:00');
-- Tabla para el historial de cambios
CREATE TABLE IF NOT EXISTS historial_mascotas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mascota_id INT NOT NULL,
    antiguo_dueño_id INT NOT NULL,
    nuevo_dueño_id INT NOT NULL,
    fecha_cambio DATETIME NOT NULL,
    FOREIGN KEY (mascota_id) REFERENCES mascotas(id),
    FOREIGN KEY (antiguo_dueño_id) REFERENCES dueños(id),
    FOREIGN KEY (nuevo_dueño_id) REFERENCES dueños(id)
);

-- Agregar campo faltante a veterinarios
ALTER TABLE veterinarios
ADD COLUMN nombre VARCHAR(100) NOT NULL AFTER id,
ADD COLUMN especialidad VARCHAR(100),
ADD COLUMN telefono VARCHAR(20),
ADD COLUMN email VARCHAR(100);

-- Agregar fecha de nacimiento a mascotas
ALTER TABLE mascotas
ADD COLUMN fecha_nacimiento DATE;
