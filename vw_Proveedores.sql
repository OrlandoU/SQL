CREATE OR ALTER VIEW vw_Proveedores AS
SELECT 
    p.ProveedorID, 
    p.Nombre, 
    tp.Nombre AS [Nombre Tipo Prv.], 
    ISNULL(SUM(cd.Cantidad * cd.Precio*(1 - ISNULL(cd.Descuento, 0)) * (1 + cd.Tasa)), 0) AS Saldo,
    Min(c.Fecha) AS [Fecha Primera Compra],
    Max(c.Fecha) AS [Fecha Ultima Compra]
FROM Proveedor p  
JOIN TipoProveedor tp ON p.TipoProveedorID = tp.TipoProveedorID
LEFT JOIN Compra c ON c.ProveedorID = p.ProveedorID
LEFT JOIN CompraDetalle cd ON cd.CompraID = c.CompraID
GROUP BY p.ProveedorID, p.Nombre, tp.Nombre