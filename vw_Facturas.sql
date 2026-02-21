CREATE or ALTER VIEW vw_Facturas AS
SELECT 
    f.FacturaID,
    f.ClienteID,
    c.Nombre,
    CASE 
        WHEN f.Tipo = 'C' THEN 'Caso'
        WHEN f.Tipo = 'R' THEN 'Credito'
    END AS Tipo,
    f.Fecha,
    SUM(a.Precio * fd.Cantidad) as SubTotal,
    SUM(a.Precio * fd.Cantidad * ISNULL(fd.Descuento, 0)) as Descuento,
    SUM((a.Precio * fd.Cantidad * (1-ISNULL(fd.Descuento, 0))) * ISNULL(i.Valor,0)) as Impuesto,
    Sum((a.Precio * fd.Cantidad * (1-ISNULL(fd.Descuento, 0)) * (1 + ISNULL(i.Valor, 0)))) as Total
FROM Factura f
JOIN Cliente c ON f.ClienteID = c.ClienteID
JOIN FacturaDetalle fd ON f.FacturaID = fd.FacturaID
JOIN Articulo a ON fd.ArticuloID = a.ArticuloID
JOIN Tipo t ON a.TipoID = t.TipoID
JOIN Impuesto i ON t.ImpuestoID = i.ImpuestoID
GROUP BY f.FacturaID, f.ClienteID, c.Nombre,f.Tipo, f.fecha