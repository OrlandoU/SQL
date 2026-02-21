CREATE or ALTER VIEW vw_Ciudades AS
SELECT 
    ISNULL(c.Direccion, p.Direccion) as Ciudad,
    Count(Distinct c.ClienteID) as CantidadClientes,
    COUNT(Distinct p.ProveedorID) as CantidadProveedores
FROM Proveedor p 
FULL OUTER JOIN Cliente c ON p.Direccion = c.Direccion
WHERE p.Direccion is not null or c.Direccion is not null
GROUP BY ISNULL(c.Direccion, p.Direccion)
