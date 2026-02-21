CREATE or ALTER VIEW vw_Articulos AS
SELECT 
    a.ArticuloID, 
    a.Nombre, 
    a.Precio, 
    t.Nombre AS NombreTipo, 
    i.Valor AS ISV 
FROM Articulo a 
INNER JOIN Tipo t ON a.TipoID = t.TipoID 
INNER JOIN Impuesto i ON t.ImpuestoID = i.ImpuestoID