CREATE or ALTER VIEW vw_ProveedoresSinVentas AS
SELECT 
    p.ProveedorID,
    p.Nombre,
    p.RTN,
    p.Direccion,
    p.Contacto,
    p.Email
FROM Proveedor p
LEFT JOIN Compra c ON p.ProveedorID = c.ProveedorID
WHERE c.CompraID is NULL