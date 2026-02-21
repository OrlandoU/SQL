CREATE OR ALTER VIEW vw_ResumenDiario AS
SELECT 
    Fecha,
    COUNT(FacturaID) AS Facturas,
    SUM(SubTotal) AS SubTotal,
    SUM(Descuento) AS Descuento,
    SUM(Impuesto) AS Impuesto,
    SUM(Total) AS Total
FROM Factura
GROUP BY Fecha;