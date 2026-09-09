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
-- Q1: order details, optional member and employee (includes anonymous customers).
SELECT o.OrderNo,COALESCE(m.DisplayName,N'非会员') AS Customer,e.EmployeeName,
 d.ProductName,d.CupSize,d.Quantity,d.UnitPrice,d.LineAmount,o.Payable
FROM dbo.SalesOrder o LEFT JOIN dbo.Member m ON o.MemberID=m.MemberID
LEFT JOIN dbo.Employee e ON o.EmployeeID=e.EmployeeID
JOIN dbo.OrderItem d ON o.OrderID=d.OrderID ORDER BY o.OrderID,d.LineNumber;
-- Q2: delivery recipient / rider / delivery state.
SELECT o.OrderNo,r.EmployeeName AS Rider,d.Status,d.PickedAt,d.DeliveredAt
FROM dbo.Delivery d JOIN dbo.SalesOrder o ON d.OrderID=o.OrderID
LEFT JOIN dbo.Employee r ON d.RiderID=r.EmployeeID;
-- Q3: available coupons at a fixed reproducible demo time (expires exclusive).
DECLARE @asOf datetime2(0)='2026-09-09T09:00:00';
SELECT m.MemberCode,c.CouponName,c.MinimumAmount,c.DiscountAmount
FROM dbo.MemberCoupon mc JOIN dbo.Member m ON mc.MemberID=m.MemberID
JOIN dbo.Coupon c ON mc.CouponID=c.CouponID
WHERE mc.Status='AVAILABLE' AND @asOf>=c.StartsAt AND @asOf<c.ExpiresAt;
-- Q4: aggregate receipts once per order, never multiply totals by detail joins.
SELECT * FROM dbo.v_DailySales;
SELECT * FROM dbo.v_ProductSales ORDER BY ProductID;
-- Q5: ledger reconciliation; all differences must be zero.
SELECT m.MemberCode,m.Balance,COALESCE(w.Total,0) AS LedgerBalance,m.Balance-COALESCE(w.Total,0) AS Difference
FROM dbo.Member m LEFT JOIN (SELECT MemberID,SUM(Delta) Total FROM dbo.WalletLedger GROUP BY MemberID) w ON w.MemberID=m.MemberID;
SELECT s.IngredientID,s.OnHand,COALESCE(t.Total,0) AS LedgerStock,s.OnHand-COALESCE(t.Total,0) AS Difference
FROM dbo.Stock s LEFT JOIN(SELECT IngredientID,SUM(Delta) Total FROM dbo.StockMovement GROUP BY IngredientID)t ON t.IngredientID=s.IngredientID;
-- Q6: low-stock candidates, not automatic purchase orders.
SELECT * FROM dbo.v_StockAvailable WHERE Available < CASE WHEN Unit=N'套' THEN 100 ELSE 1000 END;
GO


