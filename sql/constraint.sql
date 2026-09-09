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
-- PK, candidate keys and FK are defined next to their columns in 01-schema.sql.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
ALTER TABLE dbo.Product ADD CONSTRAINT CK_Product_Price CHECK(Price > 0);
ALTER TABLE dbo.Recipe ADD CONSTRAINT CK_Recipe_Quantity CHECK(Quantity > 0);
ALTER TABLE dbo.Stock ADD CONSTRAINT CK_Stock_Balance CHECK(OnHand >= 0 AND Reserved >= 0 AND Reserved <= OnHand);
ALTER TABLE dbo.Member ADD CONSTRAINT CK_Member_Assets CHECK(Balance >= 0 AND Points >= 0);
ALTER TABLE dbo.Employee ADD CONSTRAINT CK_Employee_Job CHECK(Job IN ('MANAGER','CASHIER','MAKER','STOCK','RIDER'));
ALTER TABLE dbo.Coupon ADD CONSTRAINT CK_Coupon_Rule CHECK(MinimumAmount >= DiscountAmount AND DiscountAmount > 0 AND StartsAt < ExpiresAt);
ALTER TABLE dbo.MemberCoupon ADD CONSTRAINT CK_MemberCoupon_Status CHECK(Status IN ('AVAILABLE','RESERVED','USED','EXPIRED'));
ALTER TABLE dbo.SalesOrder ADD CONSTRAINT CK_Order_Channel CHECK(Channel IN ('ONLINE','COUNTER')),
 CONSTRAINT CK_Order_Fulfillment CHECK(Fulfillment IN ('PICKUP','DELIVERY')),
 CONSTRAINT CK_Order_Status CHECK(Status IN ('PENDING','PAID','MAKING','READY','DELIVERING','COMPLETED','CANCELLED','REFUNDED')),
 CONSTRAINT CK_Order_Amount CHECK(GoodsAmount > 0 AND DiscountAmount >= 0 AND DiscountAmount <= GoodsAmount AND DeliveryFee >= 0),
 CONSTRAINT CK_Order_Member CHECK((Channel <> 'ONLINE' OR MemberID IS NOT NULL) AND (MemberCouponID IS NULL OR MemberID IS NOT NULL)),
 CONSTRAINT CK_Order_PickupFee CHECK(Fulfillment <> 'PICKUP' OR DeliveryFee = 0),
 CONSTRAINT CK_Order_Completion CHECK((Status <> 'COMPLETED' OR CompletedAt IS NOT NULL) AND (CompletedAt IS NULL OR CompletedAt >= CreatedAt));
ALTER TABLE dbo.OrderItem ADD CONSTRAINT CK_Item_Values CHECK(LineNumber > 0 AND Quantity > 0 AND UnitPrice > 0),
 CONSTRAINT CK_Item_Options CHECK(Sugar IN (N'无糖',N'三分糖',N'半糖',N'全糖') AND Temperature IN (N'热',N'常温',N'少冰',N'正常冰'));
ALTER TABLE dbo.Payment ADD CONSTRAINT CK_Payment_Values CHECK(Amount >= 0 AND Kind IN ('PAY','REFUND') AND Channel IN ('CASH','EXTERNAL','BALANCE') AND Status IN ('PENDING','SUCCESS','FAILED')),
 CONSTRAINT CK_Payment_Original CHECK((Kind = 'PAY' AND OriginalPaymentID IS NULL) OR (Kind = 'REFUND' AND OriginalPaymentID IS NOT NULL AND OriginalPaymentID <> PaymentID));
ALTER TABLE dbo.WalletLedger ADD CONSTRAINT CK_Wallet_Sign CHECK((Kind = 'RECHARGE' AND Delta > 0 AND OrderID IS NULL) OR (Kind = 'SPEND' AND Delta < 0 AND OrderID IS NOT NULL) OR (Kind = 'REFUND' AND Delta > 0 AND OrderID IS NOT NULL));
ALTER TABLE dbo.PointLedger ADD CONSTRAINT CK_Point_Sign CHECK((Kind = 'EARN' AND Delta > 0) OR (Kind = 'REVERSE' AND Delta < 0));
ALTER TABLE dbo.Delivery ADD CONSTRAINT CK_Delivery_Status CHECK(Status IN ('WAITING','ASSIGNED','IN_TRANSIT','DELIVERED','FAILED')),
 CONSTRAINT CK_Delivery_Time CHECK((Status <> 'DELIVERED' OR (PickedAt IS NOT NULL AND DeliveredAt IS NOT NULL)) AND (DeliveredAt IS NULL OR (PickedAt IS NOT NULL AND DeliveredAt >= PickedAt))),
 CONSTRAINT CK_Delivery_Rider CHECK(Status NOT IN ('ASSIGNED','IN_TRANSIT','DELIVERED') OR RiderID IS NOT NULL);
ALTER TABLE dbo.StockMovement ADD CONSTRAINT CK_Movement_Sign CHECK((Kind IN ('INBOUND','RETURN') AND Delta > 0) OR (Kind IN ('SALE','LOSS') AND Delta < 0) OR (Kind = 'ADJUST' AND Delta <> 0));
COMMIT;
GO


