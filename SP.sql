-- 1. Hacer un procedimiento almacenado que reciba como para el numero de arƟculo y actualice la
--    existencia de dicho arơculo en base a las unidades compradas y vendidas. 
CREATE OR ALTER PROCEDURE spActualizarExistenciaArticulo
    @ArticuloID int
AS
    DECLARE @entradas int
    DECLARE @salidas int
    DECLARE @existencia int

    SELECT @entradas = isnull(sum(Cantidad),0)
    FROM CompraDetalle
    WHERE ArticuloID = @ArticuloID

    SELECT @salidas = isnull(sum(Cantidad),0)
    FROM FacturaDetalle
    WHERE ArticuloID = @ArticuloID

    SELECT @existencia = @entradas - @salidas

    update Articulo
    set Existencia = @existencia
    WHERE ArticuloID = @ArticuloID
go

-- 2. Hacer un procedimiento almacenado que reciba como para parámetro un numero de tipo y que utilizando 
--    tablas temporales muestre el siguiente resultado
--    ArticuloID Nombre Barra Nom.Tipo Compras Ventas Existencia
CREATE OR ALTER PROCEDURE spArticulosPorTipo
    @TipoID int
AS

    SELECT *
    into #art
    FROM Articulo
    WHERE TipoID = @TipoID

    SELECT 
        a.ArticuloID,
        a.Nombre,
        a.Barra,
        t.Nombre as NomTipo,
        isnull((SELECT sum(Cantidad) FROM CompraDetalle WHERE ArticuloID = a.ArticuloID),0) as Compras,
        isnull((SELECT sum(Cantidad) FROM FacturaDetalle WHERE ArticuloID = a.ArticuloID),0) as Ventas,
        a.Existencia
    FROM #art a
    inner join Tipo t on a.TipoID = t.TipoID
go

-- 3. Agregue a la tabla Factura una columna de valor descuento y haga un procedimiento almacenado que reciba como 
--    parámetro un numero de factura y actualice las columnas de subtotal, valordescuento, impuesto y total.
CREATE OR ALTER PROCEDURE spActualizarTotalesFactura
    @FacturaID int
AS
    DECLARE @subtotal decimal(18,2)
    DECLARE @impuesto decimal(18,2)
    DECLARE @descuento decimal(18,2)
    DECLARE @total decimal(18,2)

    SELECT @subtotal = sum(Cantidad * Precio)
    FROM FacturaDetalle
    WHERE FacturaID = @FacturaID

    SELECT @impuesto = sum(Cantidad * Precio * Impuesto)
    FROM FacturaDetalle
    WHERE FacturaID = @FacturaID

    SELECT @descuento = isnull(ValorDescuento,0)
    FROM Factura
    WHERE FacturaID = @FacturaID

    SELECT @total = @subtotal + @impuesto - @descuento

    update Factura
    set SubTotal = @subtotal,
        Impuesto = @impuesto,
        Total = @total
    WHERE FacturaID = @FacturaID
go

-- 4. Hacer un procedimiento almacenado para INSERT un registro en la tabla FacturaDetalle y que actualice los totales 
--    en la tabla factura y si la factura es de crédito que actualice el saldo del cliente, utilizar manejo transaccional. 
CREATE OR ALTER PROCEDURE spInsertFacturaDetalle
    @FacturaID INT, @ArticuloID INT, @Cantidad INT, @Precio DECIMAL(18,2), @Impuesto DECIMAL(5,2)
AS
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        INSERT INTO FacturaDetalle (FacturaID, ArticuloID, Cantidad, Precio, Impuesto)
        VALUES (@FacturaID, @ArticuloID, @Cantidad, @Precio, @Impuesto)

        EXEC spActualizarTotalesFactura @FacturaID

        IF (SELECT Tipo FROM Factura WHERE FacturaID = @FacturaID) = 'R' -- R de Crédito/Recibo
        BEGIN
            DECLARE @ClienteID INT = (SELECT ClienteID FROM Factura WHERE FacturaID = @FacturaID)
            DECLARE @TotalFactura DECIMAL(18,2) = (SELECT Total FROM Factura WHERE FacturaID = @FacturaID)
            UPDATE Cliente SET Saldo = Saldo + @TotalFactura WHERE ClienteID = @ClienteID
        END
        COMMIT
    END TRY
    BEGIN CATCH
        ROLLBACK
    END CATCH
END
GO

-- 5. Hacer un procedimiento almacenado que sirva para actualizar el saldo de todos los clientes en base a
--    las facturas al crédito que estos tengan. 
CREATE OR ALTER PROCEDURE spSincronizarSaldosClientes
AS
BEGIN
    UPDATE Cliente SET Saldo = 0
    UPDATE Cliente
    SET Saldo = ISNULL((SELECT SUM(Total) FROM Factura 
                        WHERE ClienteID = Cliente.ClientID AND Tipo = 'R' AND [Factura Estado] != 'N'), 0)
END
GO

-- 6. Hacer un procedimiento almacenado para INSERT un registro en la tabla compra pero que solo reciba 3 parámetros 
--    ProveedorID, Documento, Tipo. CompraID debe ser autonumérico, Fecha la fecha del día que se graba, Estado = G. Exento, Gravado e Impuesto = 0 
CREATE OR ALTER PROCEDURE spInsertCompraSimple
    @ProveedorID INT, @Documento VARCHAR(50), @Tipo CHAR(1)
AS
BEGIN
    INSERT INTO Compra (ProveedorID, Documento, Tipo, Fecha, Estado, Excento, Gravado, Impuesto)
    VALUES (@ProveedorID, @Documento, @Tipo, GETDATE(), 'G', 0, 0, 0)
END
GO

-- 7. Hacer un procedimiento almacenado para anular una factura que reciba como parámetro el numero de factura y coloque 
--    el estado en N y actualice la existencia de los articulos de dicha factura y lossaldos de los clientes.
CREATE OR ALTER PROCEDURE spAnularFactura
    @FacturaID INT
AS
BEGIN
    BEGIN TRANSACTION
    UPDATE Factura SET [Factura Estado] = 'N' WHERE FacturaID = @FacturaID
    
    -- Devolver existencias
    DECLARE @ArticuloID INT
    DECLARE cur CURSOR FOR SELECT ArticuloID FROM FacturaDetalle WHERE FacturaID = @FacturaID
    OPEN cur
    FETCH NEXT FROM cur INTO @ArticuloID
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC spActualizarExistenciaArticulo @ArticuloID
        FETCH NEXT FROM cur INTO @ArticuloID
    END
    CLOSE cur DEALLOCATE cur

    -- Actualizar saldo cliente si era crédito
    EXEC spSincronizarSaldosClientes
    COMMIT
END
GO

-- 8. Hacer procedimiento almacenado que reciba como parámetro el código de proveedor y utilizando variables tipo tabla 
--    muestre la siguiente información 
--    CompraID ProveedorID NombreProv. Nombre Tipo SubTotal Impuesto Total Calculando la información a partir de la tabla compradetalle.
CREATE OR ALTER PROCEDURE spReporteComprasProveedor
    @ProveedorID INT
AS
BEGIN
    DECLARE @TablaReporte TABLE (
        CompraID INT, ProvID INT, NombreProv VARCHAR(100), NomTipo VARCHAR(50), 
        SubTotal DECIMAL(18,2), Impuesto DECIMAL(18,2), Total DECIMAL(18,2)
    )

    INSERT INTO @TablaReporte
    SELECT 
        c.CompraID, c.ProveedorID, p.Nombre, tp.Nombre,
        SUM(cd.Cantidad * cd.Precio),
        SUM(cd.Cantidad * cd.Precio * cd.Tasa),
        SUM(cd.Cantidad * cd.Precio * (1 + cd.Tasa))
    FROM Compra c
    JOIN Proveedor p ON c.ProveedorID = p.ProveedorID
    JOIN TipoProveedor tp ON p.TipoProveedorID = tp.TipoProveedorID
    JOIN CompraDetalle cd ON c.CompraID = cd.CompraID
    WHERE c.ProveedorID = @ProveedorID
    GROUP BY c.CompraID, c.ProveedorID, p.Nombre, tp.Nombre

    SELECT * FROM @TablaReporte
END
GO

-- 9. Asegurarse que sus tablas tengan integridad referencial sin cascada y hacer un procedimiento almacenado que reciba 
--    como parámetro el tipo de articulo sea capaz de borrar dicho registro de latabla Tipo.
CREATE OR ALTER PROCEDURE spBorrarTipoArticulo
    @TipoID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Articulo WHERE TipoID = @TipoID)
        PRINT 'No se puede borrar: Existen artículos asociados a este tipo.'
    ELSE
        DELETE FROM Tipo WHERE TipoID = @TipoID
END
GO
-- 10. Agregar una columna saldo a la table proveedor y hacer un procedimiento almacenado que actualiceel total de compras por cada proveedor.
-- ALTER TABLE Proveedor ADD Saldo DECIMAL(18,2) DEFAULT 0

CREATE OR ALTER PROCEDURE spActualizarSaldoProveedor
AS
BEGIN
    UPDATE Proveedor
    SET Saldo = ISNULL((SELECT SUM(cd.Cantidad * cd.Precio * (1 + cd.Tasa)) 
                        FROM Compra c 
                        JOIN CompraDetalle cd ON c.CompraID = cd.CompraID 
                        WHERE c.ProveedorID = Proveedor.ProveedorID), 0)
END
GO

-- 11. Hacer un procedimiento almacenado que recibía como parámetro el nombre de una ciudad y quemuestre la siguiente información
--     Ciudad Cant.Clientes Cant.Proveedores
--     ejecútelo con dos ciudades diferentes y calcule la eficiencia del procedimiento vrs. hacerlo con unavista.
CREATE OR ALTER PROCEDURE spActividadCiudad
    @Ciudad VARCHAR(50)
AS
BEGIN
    SELECT 
        @Ciudad AS Ciudad,
        (SELECT COUNT(*) FROM Cliente WHERE Direccion = @Ciudad) AS CantClientes,
        (SELECT COUNT(*) FROM Proveedor WHERE Direccion = @Ciudad) AS CantProveedores
END
GO

-- 12. Haga un procedimiento almacenado que muestre la siguiente información. Que reciba comoparámetros Cliente y dos fechas y 
--     que permita mostrar todas las facturas de un cliente o todas lasfacturas de un rengo de fecha. De ser posible use tablas 
--     temporales o variables tipo tabla.
--     FacturaID ClienteID Nombre Tipo Fecha Valor 
CREATE OR ALTER PROCEDURE spConsultaFacturas
    @ClienteID INT = NULL,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SELECT f.FacturaID, f.ClientID, c.Nombre, f.Tipo, f.Fecha, f.Total AS Valor
    INTO #Resultados
    FROM Factura f
    JOIN Cliente c ON f.ClientID = c.ClientID
    WHERE (@ClienteID IS NULL OR f.ClientID = @ClienteID)
      AND ((@FechaInicio IS NULL AND @FechaFin IS NULL) OR (f.Fecha BETWEEN @FechaInicio AND @FechaFin))

    SELECT * FROM #Resultados
END
GO

