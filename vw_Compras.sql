CREATE or ALTER VIEW vw_Compras AS
SELECT 
    c.CompraID, 
    c.ProveedorID, 
    p.Nombre AS [Nombre Prov.], 
    c.Fecha,
    SUM(cd.Cantidad * cd.Precio) AS SubTotal,
    SUM(cd.Cantidad * cd.Precio * ISNULL(cd.Descuento, 0)) AS Descuento,
    SUM((cd.Cantidad * cd.Precio * (1 - ISNULL(cd.Descuento, 0))) * cd.Tasa) AS Impuesto,
    SUM((cd.Cantidad * cd.Precio * (1 - ISNULL(cd.Descuento, 0))) * (1 + cd.Tasa)) AS Total
FROM Compra c
JOIN Proveedor p ON c.ProveedorID = p.ProveedorID
JOIN CompraDetalle cd ON c.CompraID = cd.CompraID
GROUP BY c.CompraID, c.ProveedorID, p.Nombre, c.Fecha;