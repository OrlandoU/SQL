CREATE or ALTER VIEW vw_ArticulosCompras AS
SELECT 
    a.ArticuloID,
    a.Nombre,
    ISNULL(SUM(cd.Cantidad * cd.Precio), 0) as TotalCompras,
    ISNULL(SUM(fd.Cantidad * a.Precio), 0) as TotalVentas,
    a.Existencia as Actual 
FROM Articulo a
LEFT JOIN CompraDetalle cd ON cd.ArticuloID = a.ArticuloID
LEFT JOIN FacturaDetalle fd ON fd.ArticuloID = a.ArticuloID
GROUP BY a.ArticuloID, a.Nombre, a.Existencia