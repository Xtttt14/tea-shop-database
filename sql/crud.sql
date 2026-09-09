SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
USE TeaShopCourse;
GO
SET XACT_ABORT ON;
SET NOCOUNT ON;
-- Reversible product INSERT / SELECT / UPDATE / DELETE.
BEGIN TRANSACTION;
INSERT dbo.Product VALUES (900,'DEMO-TEMP',N'演示商品',N'中杯',15,1);
SELECT * FROM dbo.Product WHERE ProductID=900;
UPDATE dbo.Product SET Price=16 WHERE ProductID=900;
IF (SELECT Price FROM dbo.Product WHERE ProductID=900) <> 16 THROW 51001,'CRUD update failed',1;
DELETE dbo.Product WHERE ProductID=900;
IF EXISTS(SELECT 1 FROM dbo.Product WHERE ProductID=900) THROW 51002,'CRUD delete failed',1;
ROLLBACK;
PRINT 'PASS: product CRUD';

-- Stock receipt and its movement must be written together.
BEGIN TRANSACTION;
UPDATE dbo.Stock SET OnHand=OnHand+500 WHERE IngredientID=1;
INSERT dbo.StockMovement(MovementID,IngredientID,Kind,Delta,EmployeeID,Note) VALUES(900,1,'INBOUND',500,4,N'补货演示');
SELECT * FROM dbo.v_StockAvailable WHERE IngredientID=1;
ROLLBACK;
PRINT 'PASS: stock receipt rollback';

-- One fully worked, serialized course demonstration: member 2 purchases milk tea,
-- self-pickup, external payment, no coupon. Not a production payment API.
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.SalesOrder(OrderID,OrderNo,MemberID,EmployeeID,Channel,Fulfillment,Status,GoodsAmount)
 VALUES(900,'DEMO-CRUD-ORDER',2,2,'ONLINE','PICKUP','PENDING',18);
 INSERT dbo.OrderItem(OrderID,LineNumber,ProductID,ProductName,CupSize,Quantity,UnitPrice,Sugar,Temperature)
 SELECT 900,1,ProductID,ProductName,CupSize,1,Price,N'半糖',N'热' FROM dbo.Product WHERE ProductID=3 AND IsActive=1;
 DECLARE @need TABLE(IngredientID int PRIMARY KEY,Quantity decimal(12,3));
 INSERT @need SELECT IngredientID,Quantity FROM dbo.Recipe WHERE ProductID=3;
 DECLARE @expected int=(SELECT COUNT(*) FROM @need);
 IF @expected=0 THROW 51003,'Missing recipe',1;
 UPDATE s WITH (UPDLOCK,HOLDLOCK) SET Reserved=Reserved+n.Quantity
 FROM dbo.Stock s JOIN @need n ON s.IngredientID=n.IngredientID
 WHERE s.OnHand-s.Reserved>=n.Quantity;
 IF @@ROWCOUNT<>@expected THROW 51004,'Insufficient stock',1;
 -- Simulated successful external payment.
 INSERT dbo.Payment(PaymentID,OrderID,Kind,Channel,Amount,Status,ReferenceNo)
 VALUES(900,900,'PAY','EXTERNAL',18,'SUCCESS','DEMO-CRUD-PAY');
 UPDATE s SET OnHand=OnHand-n.Quantity,Reserved=Reserved-n.Quantity
 FROM dbo.Stock s JOIN @need n ON s.IngredientID=n.IngredientID;
 INSERT dbo.StockMovement(MovementID,IngredientID,Kind,Delta,OrderID,EmployeeID,Note)
 SELECT 900+IngredientID,IngredientID,'SALE',-Quantity,900,2,N'交易演示标准耗料' FROM @need;
 UPDATE dbo.SalesOrder SET Status='MAKING' WHERE OrderID=900;
 UPDATE dbo.SalesOrder SET Status='READY' WHERE OrderID=900;
 UPDATE dbo.SalesOrder SET Status='COMPLETED',CompletedAt=SYSDATETIME() WHERE OrderID=900;
 UPDATE dbo.Member SET Points=Points+18 WHERE MemberID=2;
 INSERT dbo.PointLedger VALUES(900,2,900,'EARN',18);
 IF (SELECT Payable FROM dbo.SalesOrder WHERE OrderID=900)<>18 THROW 51005,'Order total mismatch',1;
 SELECT * FROM dbo.v_OrderSummary WHERE OrderID=900;
 ROLLBACK;
 PRINT 'PASS: complete order / stock / payment / points flow, rolled back';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
GO


