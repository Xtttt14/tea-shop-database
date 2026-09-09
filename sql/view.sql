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
CREATE OR ALTER VIEW dbo.v_Menu AS
 SELECT ProductID, ProductCode, ProductName, CupSize, Price FROM dbo.Product WHERE IsActive=1;
GO
CREATE OR ALTER VIEW dbo.v_StockAvailable AS
 SELECT i.IngredientID,i.IngredientName,i.Unit,s.OnHand,s.Reserved,s.OnHand-s.Reserved AS Available
 FROM dbo.Ingredient i JOIN dbo.Stock s ON i.IngredientID=s.IngredientID;
GO
CREATE OR ALTER VIEW dbo.v_MakingQueue AS
 SELECT o.OrderID,o.OrderNo,o.Status,o.Fulfillment,d.LineNumber,d.ProductName,d.CupSize,d.Quantity,d.Sugar,d.Temperature
 FROM dbo.SalesOrder o JOIN dbo.OrderItem d ON o.OrderID=d.OrderID
 WHERE o.Status IN ('PAID','MAKING','READY');
GO
CREATE OR ALTER VIEW dbo.v_DailySales AS
 SELECT CONVERT(date,CompletedAt) AS SalesDate,COUNT_BIG(*) AS OrderCount,
 SUM(GoodsAmount) AS GoodsTotal,SUM(DiscountAmount) AS DiscountTotal,
 SUM(DeliveryFee) AS DeliveryTotal,SUM(Payable) AS ReceiptTotal
 FROM dbo.SalesOrder WHERE Status='COMPLETED' GROUP BY CONVERT(date,CompletedAt);
GO
CREATE OR ALTER VIEW dbo.v_ProductSales AS
 SELECT p.ProductID,p.ProductName,p.CupSize,SUM(d.Quantity) AS Cups,SUM(d.LineAmount) AS GrossSales
 FROM dbo.Product p JOIN dbo.OrderItem d ON p.ProductID=d.ProductID
 JOIN dbo.SalesOrder o ON d.OrderID=o.OrderID WHERE o.Status='COMPLETED'
 GROUP BY p.ProductID,p.ProductName,p.CupSize;
GO
CREATE OR ALTER VIEW dbo.v_OrderSummary AS
 SELECT o.OrderID,o.OrderNo,o.Channel,o.Fulfillment,o.Status,o.GoodsAmount,o.DiscountAmount,o.DeliveryFee,o.Payable
 FROM dbo.SalesOrder o;
GO


