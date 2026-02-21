CREATE OR ALTER VIEW vw_Proveedores AS
SELECT 
    p.ProveedorID, 
    p.Nombre, 
    tp.Nombre AS [Nombre Tipo Prv.], 
    SUM(cd.Cantidad * cd.Precio*(1 - ISNULL(cd.Descuento, 0)) * (1 + cd.Tasa)) AS Saldo
FROM Proveedor p  
JOIN TipoProveedor tp ON p.TipoProveedorID = tp.TipoProveedorID
LEFT JOIN Compra c ON c.ProveedorID = p.ProveedorID
LEFT JOIN CompraDetalle cd ON cd.CompraID = c.CompraID