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
SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Assertions are executable; failures cause sqlcmd -b to exit nonzero.
IF (SELECT COUNT(*) FROM dbo.Product)<>3 THROW 51200,'Seed product count',1;
IF (SELECT ReceiptTotal FROM dbo.v_DailySales WHERE SalesDate='2026-09-09')<>70 THROW 51200,'Daily receipt total',1;
IF (SELECT SUM(Cups) FROM dbo.v_ProductSales)<>5 THROW 51200,'Cups total',1;
IF EXISTS(SELECT 1 FROM dbo.SalesOrder o OUTER APPLY(SELECT SUM(LineAmount) Amount FROM dbo.OrderItem d WHERE d.OrderID=o.OrderID)x WHERE x.Amount IS NULL OR x.Amount<>o.GoodsAmount) THROW 51200,'Order item totals',1;
IF EXISTS(SELECT 1 FROM dbo.Member m OUTER APPLY(SELECT SUM(Delta) Amount FROM dbo.WalletLedger w WHERE w.MemberID=m.MemberID)x WHERE m.Balance<>COALESCE(x.Amount,0)) THROW 51200,'Wallet reconciliation',1;
IF EXISTS(SELECT 1 FROM dbo.Member m OUTER APPLY(SELECT SUM(Delta) Amount FROM dbo.PointLedger p WHERE p.MemberID=m.MemberID)x WHERE m.Points<>COALESCE(x.Amount,0)) THROW 51200,'Points reconciliation',1;
IF EXISTS(SELECT 1 FROM dbo.Stock s OUTER APPLY(SELECT SUM(Delta) Amount FROM dbo.StockMovement t WHERE t.IngredientID=s.IngredientID)x WHERE s.OnHand<>COALESCE(x.Amount,0)) THROW 51200,'Stock reconciliation',1;
IF EXISTS(SELECT 1 FROM dbo.SalesOrder o JOIN dbo.Payment p ON p.OrderID=o.OrderID AND p.Kind='PAY' AND p.Status='SUCCESS' WHERE p.Amount<>o.Payable) THROW 51200,'Payment reconciliation',1;
PRINT 'PASS: seed totals / order items / wallet / points / stock / payments';
DECLARE @cases TABLE(ID int PRIMARY KEY,Label varchar(80),Statement nvarchar(max),Expected int);
INSERT @cases VALUES
(1,'negative price',N'UPDATE dbo.Product SET Price=-1 WHERE ProductID=1',547),
(2,'negative stock',N'UPDATE dbo.Stock SET OnHand=-1 WHERE IngredientID=1',547),
(3,'over-reservation',N'UPDATE dbo.Stock SET Reserved=OnHand+1 WHERE IngredientID=1',547),
(4,'negative balance',N'UPDATE dbo.Member SET Balance=-1 WHERE MemberID=1',547),
(5,'orphan detail',N'INSERT dbo.OrderItem(OrderID,LineNumber,ProductID,ProductName,CupSize,Quantity,UnitPrice,Sugar,Temperature) VALUES(999,1,1,N''x'',N''中杯'',1,12,N''半糖'',N''热'')',547),
(6,'duplicate product code',N'INSERT dbo.Product VALUES(999,''TEA-M'',N''x'',N''中杯'',12,1)',2627),
(7,'delete referenced product',N'DELETE dbo.Product WHERE ProductID=1',547),
(8,'invalid coupon dates',N'UPDATE dbo.Coupon SET ExpiresAt=StartsAt WHERE CouponID=1',547),
(9,'wrong coupon owner',N'UPDATE dbo.SalesOrder SET MemberCouponID=3 WHERE OrderID=1',547),
(10,'zero item quantity',N'UPDATE dbo.OrderItem SET Quantity=0 WHERE OrderID=1',547),
(11,'duplicate payment reference',N'INSERT dbo.Payment(PaymentID,OrderID,Kind,Channel,Amount,Status,ReferenceNo) VALUES(999,1,''PAY'',''EXTERNAL'',24,''FAILED'',''DEMO-PAY-001'')',2627),
(12,'invalid delivery time',N'UPDATE dbo.Delivery SET DeliveredAt=''2026-09-09T09:00:00'' WHERE OrderID=1',547),
(13,'online anonymous order',N'UPDATE dbo.SalesOrder SET Channel=''ONLINE'' WHERE OrderID=2',547),
(14,'reuse active coupon',N'UPDATE dbo.SalesOrder SET MemberCouponID=1 WHERE OrderID=4',2601),
(15,'invalid wallet direction',N'UPDATE dbo.WalletLedger SET Delta=1 WHERE WalletID=2',547);
DECLARE @i int=1,@sql nvarchar(max),@label varchar(80),@expected int,@error int;
WHILE @i<=15
BEGIN
 SELECT @sql=Statement,@label=Label,@expected=Expected FROM @cases WHERE ID=@i;
 SET @error=0;
 BEGIN TRANSACTION;
 BEGIN TRY
  EXEC sys.sp_executesql @sql;
 END TRY
 BEGIN CATCH
  SET @error=ERROR_NUMBER();
 END CATCH;
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @error<>@expected
 BEGIN
  DECLARE @msg nvarchar(2048)=CONCAT('FAIL: ',@label,' expected ',@expected,' actual ',@error);
  THROW 51201,@msg,1;
 END;
 PRINT CONCAT('PASS: ',@label,' rejected (',@error,')');
 SET @i+=1;
END;

-- Authorized SELECT and an authorized manager UPDATE, then negative checks.
EXECUTE AS USER='demo_maker';
SELECT * FROM dbo.v_MakingQueue;
REVERT;
EXECUTE AS USER='demo_stock';
SELECT COUNT(*) AS StockRows FROM dbo.v_StockAvailable;
REVERT;
EXECUTE AS USER='demo_cashier';
SELECT COUNT(*) AS MenuRows FROM dbo.v_Menu;
REVERT;
BEGIN TRANSACTION;
EXECUTE AS USER='demo_manager';
BEGIN TRY
 UPDATE dbo.Product SET Price=Price+1 WHERE ProductID=1;
END TRY
BEGIN CATCH
 REVERT;
 ROLLBACK;
 THROW;
END CATCH;
REVERT;
IF (SELECT Price FROM dbo.Product WHERE ProductID=1)<>13
BEGIN
 ROLLBACK;
 THROW 51204,'Manager price update failed',1;
END;
ROLLBACK;
PRINT 'PASS: authorized role access';
SET @error=0;
EXECUTE AS USER='demo_cashier';
BEGIN TRY
 UPDATE dbo.Member SET Balance=0 WHERE MemberID=1;
END TRY
BEGIN CATCH
 SET @error=ERROR_NUMBER();
END CATCH;
REVERT;
IF @error<>229 THROW 51202,'Cashier unauthorized write was not rejected',1;
PRINT 'PASS: cashier balance write denied (229)';
SET @error=0;
EXECUTE AS USER='demo_maker';
BEGIN TRY
 SELECT Balance FROM dbo.Member;
END TRY
BEGIN CATCH
 SET @error=ERROR_NUMBER();
END CATCH;
REVERT;
IF @error<>229 THROW 51203,'Maker confidential read was not rejected',1;
PRINT 'PASS: maker member read denied (229)';
PRINT 'ALL TESTS PASSED';
GO


