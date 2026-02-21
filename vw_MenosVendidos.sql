CREATE OR ALTER VIEW vw_MenosVendidos AS
SELECT TOP 5
    a.ArticuloID, 
    a.Nombre, 
    SUM(ISNULL(fd.Cantidad, 0)) AS Cantidad,
    SUM(ISNULL(fd.Cantidad, 0) * a.Precio) AS SubTotal,
    SUM(ISNULL(fd.Cantidad, 0) * a.Precio * ISNULL(fd.Descuento, 0)) AS Descuento,
    SUM((ISNULL(fd.Cantidad, 0) * a.Precio * (1 - ISNULL(fd.Descuento, 0))) * ISNULL(fd.Impuesto, 0)) AS Impuesto,
    SUM((ISNULL(fd.Cantidad, 0) * a.Precio * (1 - ISNULL(fd.Descuento, 0))) * (1 + ISNULL(fd.Impuesto, 0))) AS Total
FROM Articulo a
LEFT JOIN FacturaDetalle fd ON a.ArticuloID = fd.ArticuloID
GROUP BY a.ArticuloID, a.Nombre
ORDER BY Cantidad ASC;

