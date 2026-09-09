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
-- Member 2 tops up 50 and uses coupon 3: goods 24, discount 3,
-- delivery 3, payable 24. Validate coupon ownership and minimum first.
-- All records in this script are rolled back, allowing safe replay.
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @member int=2,@order int=800,@coupon int=3,@now datetime2(0)='2026-09-09T14:00:00';
 -- Successful recharge confirmation; unique reference prevents duplicate credit.
 INSERT dbo.WalletLedger(WalletID,MemberID,Kind,Delta,ReferenceNo)
 VALUES(800,@member,'RECHARGE',50,'DEMO-SERVICE-TOPUP');
 UPDATE dbo.Member SET Balance=Balance+50 WHERE MemberID=@member;
 DECLARE @discount decimal(10,2);
 SELECT @discount=c.DiscountAmount FROM dbo.MemberCoupon mc WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.Coupon c ON mc.CouponID=c.CouponID
 WHERE mc.MemberCouponID=@coupon AND mc.MemberID=@member AND mc.Status='AVAILABLE'
 AND @now>=c.StartsAt AND @now<c.ExpiresAt AND 24>=c.MinimumAmount;
 IF @discount IS NULL THROW 51101,'Coupon not eligible',1;
 INSERT dbo.SalesOrder(OrderID,OrderNo,MemberID,EmployeeID,Channel,Fulfillment,Status,CreatedAt,GoodsAmount,DiscountAmount,DeliveryFee,MemberCouponID)
 VALUES(@order,'DEMO-SERVICE-ORDER',@member,2,'ONLINE','DELIVERY','PENDING',@now,24,@discount,3,@coupon);
 INSERT dbo.OrderItem(OrderID,LineNumber,ProductID,ProductName,CupSize,Quantity,UnitPrice,Sugar,Temperature)
 VALUES(@order,1,1,N'原味奶茶',N'中杯',2,12,N'半糖',N'少冰');
 UPDATE dbo.MemberCoupon SET Status='RESERVED' WHERE MemberCouponID=@coupon;
 DECLARE @needed TABLE(IngredientID int PRIMARY KEY,Qty decimal(12,3));
 INSERT @needed SELECT IngredientID,Quantity*2 FROM dbo.Recipe WHERE ProductID=1;
 DECLARE @count int=(SELECT COUNT(*) FROM @needed);
 IF @count=0 THROW 51102,'Recipe missing',1;
 UPDATE s WITH(UPDLOCK,HOLDLOCK) SET Reserved=Reserved+n.Qty
 FROM dbo.Stock s JOIN @needed n ON s.IngredientID=n.IngredientID WHERE s.OnHand-s.Reserved>=n.Qty;
 IF @@ROWCOUNT<>@count THROW 51103,'Insufficient stock',1;
 DECLARE @pay decimal(10,2)=(SELECT Payable FROM dbo.SalesOrder WHERE OrderID=@order);
 UPDATE dbo.Member WITH(UPDLOCK,HOLDLOCK) SET Balance=Balance-@pay WHERE MemberID=@member AND Balance>=@pay;
 IF @@ROWCOUNT<>1 THROW 51104,'Insufficient balance',1;
 INSERT dbo.WalletLedger(WalletID,MemberID,Kind,Delta,OrderID,ReferenceNo)
 VALUES(801,@member,'SPEND',-@pay,@order,'DEMO-SERVICE-SPEND');
 INSERT dbo.Payment(PaymentID,OrderID,Kind,Channel,Amount,Status,ReferenceNo)
 VALUES(800,@order,'PAY','BALANCE',@pay,'SUCCESS','DEMO-SERVICE-PAY');
 UPDATE dbo.MemberCoupon SET Status='USED' WHERE MemberCouponID=@coupon;
 UPDATE s SET OnHand=OnHand-n.Qty,Reserved=Reserved-n.Qty FROM dbo.Stock s JOIN @needed n ON s.IngredientID=n.IngredientID;
 INSERT dbo.StockMovement(MovementID,IngredientID,Kind,Delta,OrderID,EmployeeID,Note)
 SELECT 800+IngredientID,IngredientID,'SALE',-Qty,@order,2,N'配送订单耗料' FROM @needed;
 UPDATE dbo.SalesOrder SET Status='MAKING' WHERE OrderID=@order;
 INSERT dbo.Delivery(OrderID,Recipient,Phone,Address,Status)
 VALUES(@order,N'虚构会员乙','TEST-PHONE-002',N'虚构地址：测试校园B栋','WAITING');
 UPDATE dbo.SalesOrder SET Status='READY' WHERE OrderID=@order;
 UPDATE dbo.Delivery SET RiderID=5,Status='ASSIGNED' WHERE OrderID=@order;
 UPDATE dbo.Delivery SET Status='IN_TRANSIT',PickedAt='2026-09-09T14:15:00' WHERE OrderID=@order;
 UPDATE dbo.SalesOrder SET Status='DELIVERING' WHERE OrderID=@order;
 UPDATE dbo.Delivery SET Status='DELIVERED',DeliveredAt='2026-09-09T14:30:00' WHERE OrderID=@order;
 UPDATE dbo.SalesOrder SET Status='COMPLETED',CompletedAt='2026-09-09T14:30:00' WHERE OrderID=@order;
 INSERT dbo.PointLedger VALUES(800,@member,@order,'EARN',21);
 UPDATE dbo.Member SET Points=Points+21 WHERE MemberID=@member;
 IF (SELECT Balance FROM dbo.Member WHERE MemberID=@member)<>26 THROW 51105,'Wrong balance',1;
 IF (SELECT Payable FROM dbo.SalesOrder WHERE OrderID=@order)<>24 THROW 51106,'Wrong payable',1;
 PRINT 'PASS: recharge / coupon / balance payment / stock / delivery / points';

 -- Whole-order refund after completion. Consumed materials remain consumed.
 INSERT dbo.Payment(PaymentID,OrderID,Kind,Channel,Amount,Status,ReferenceNo,OriginalPaymentID)
 VALUES(801,@order,'REFUND','BALANCE',@pay,'SUCCESS','DEMO-SERVICE-REFUND',800);
 INSERT dbo.WalletLedger(WalletID,MemberID,Kind,Delta,OrderID,ReferenceNo)
 VALUES(802,@member,'REFUND',@pay,@order,'DEMO-SERVICE-WALLET-REFUND');
 UPDATE dbo.Member SET Balance=Balance+@pay,Points=Points-21 WHERE MemberID=@member;
 INSERT dbo.PointLedger VALUES(801,@member,@order,'REVERSE',-21);
 UPDATE dbo.SalesOrder SET Status='REFUNDED' WHERE OrderID=@order;
 UPDATE dbo.MemberCoupon SET Status='AVAILABLE' WHERE MemberCouponID=@coupon;
 IF (SELECT Balance FROM dbo.Member WHERE MemberID=@member)<>50 THROW 51107,'Refund balance mismatch',1;
 IF (SELECT Points FROM dbo.Member WHERE MemberID=@member)<>18 THROW 51108,'Refund points mismatch',1;
 -- Sale movements retain consumed ingredients; refund receipt identifies loss,
 -- so no second negative stock movement is posted for the same ingredients.
 PRINT 'PASS: full refund / wallet reversal / coupon release / points reversal';
 ROLLBACK;
 PRINT 'PASS: service demonstration rolled back';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
GO


