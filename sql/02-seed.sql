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
BEGIN TRANSACTION;
INSERT dbo.Product VALUES (1,'TEA-M',N'原味奶茶',N'中杯',12,1),(2,'TEA-L',N'原味奶茶',N'大杯',16,1),(3,'MILK-M',N'鲜奶茶',N'中杯',18,1);
INSERT dbo.Ingredient VALUES (1,N'茶汤',N'毫升'),(2,N'牛奶',N'毫升'),(3,N'杯具',N'套');
INSERT dbo.Recipe VALUES (1,1,200),(1,2,100),(1,3,1),(2,1,300),(2,2,150),(2,3,1),(3,1,150),(3,2,200),(3,3,1);
INSERT dbo.Employee VALUES (1,'E001',N'示例店长','MANAGER',1),(2,'E002',N'示例收银','CASHIER',1),(3,'E003',N'示例制作','MAKER',1),(4,'E004',N'示例仓管','STOCK',1),(5,'E005',N'示例骑手','RIDER',1);
INSERT dbo.Member VALUES (1,'M001',N'测试会员甲','TEST-PHONE-001',88,33),(2,'M002',N'测试会员乙','TEST-PHONE-002',0,18);
INSERT dbo.Coupon VALUES (1,N'满20减3',20,3,'2026-01-01','2027-01-01'),(2,N'满30减5',30,5,'2026-01-01','2027-01-01');
INSERT dbo.MemberCoupon VALUES (1,1,1,'USED'),(2,1,2,'AVAILABLE'),(3,2,1,'AVAILABLE');
INSERT dbo.SalesOrder(OrderID,OrderNo,MemberID,EmployeeID,Channel,Fulfillment,Status,CreatedAt,CompletedAt,GoodsAmount,DiscountAmount,DeliveryFee,MemberCouponID) VALUES
 (1,'DEMO-001',1,2,'ONLINE','DELIVERY','COMPLETED','2026-09-09T10:00:00','2026-09-09T10:35:00',24,3,3,1),
 (2,'DEMO-002',NULL,2,'COUNTER','PICKUP','COMPLETED','2026-09-09T11:00:00','2026-09-09T11:10:00',16,0,0,NULL),
 (3,'DEMO-003',2,2,'ONLINE','PICKUP','COMPLETED','2026-09-09T12:00:00','2026-09-09T12:10:00',18,0,0,NULL),
 (4,'DEMO-004',1,2,'COUNTER','PICKUP','COMPLETED','2026-09-09T13:00:00','2026-09-09T13:10:00',12,0,0,NULL);
-- Historical item prices are stored separately from the current menu.
INSERT dbo.OrderItem(OrderID,LineNumber,ProductID,ProductName,CupSize,Quantity,UnitPrice,Sugar,Temperature) VALUES
 (1,1,1,N'原味奶茶',N'中杯',2,12,N'半糖',N'少冰'),(2,1,2,N'原味奶茶',N'大杯',1,16,N'全糖',N'正常冰'),
 (3,1,3,N'鲜奶茶',N'中杯',1,18,N'无糖',N'热'),(4,1,1,N'原味奶茶',N'中杯',1,12,N'半糖',N'常温');
INSERT dbo.Payment(PaymentID,OrderID,Kind,Channel,Amount,Status,ReferenceNo) VALUES
 (1,1,'PAY','EXTERNAL',24,'SUCCESS','DEMO-PAY-001'),(2,2,'PAY','CASH',16,'SUCCESS','DEMO-PAY-002'),
 (3,3,'PAY','EXTERNAL',18,'SUCCESS','DEMO-PAY-003'),(4,4,'PAY','BALANCE',12,'SUCCESS','DEMO-PAY-004');
-- Member 1: recharge 100, spend 12, closing balance 88.

INSERT dbo.WalletLedger(WalletID,MemberID,Kind,Delta,OrderID,ReferenceNo) VALUES
 (1,1,'RECHARGE',100,NULL,'DEMO-TOPUP-001'),(2,1,'SPEND',-12,4,'DEMO-WALLET-004');
INSERT dbo.PointLedger VALUES (1,1,1,'EARN',21),(2,2,3,'EARN',18),(3,1,4,'EARN',12);
INSERT dbo.Delivery VALUES (1,N'示例收件人','TEST-PHONE-001',N'虚构地址：示例校园测试楼',5,'DELIVERED','2026-09-09T10:15:00','2026-09-09T10:35:00',NULL);
INSERT dbo.Stock VALUES (1,8950,0),(2,9350,0),(3,995,0);
INSERT dbo.StockMovement(MovementID,IngredientID,Kind,Delta,OrderID,EmployeeID,Note) VALUES
 (1,1,'INBOUND',10000,NULL,4,N'初始入库'),(2,2,'INBOUND',10000,NULL,4,N'初始入库'),(3,3,'INBOUND',1000,NULL,4,N'初始入库'),
 (11,1,'SALE',-400,1,2,N'标准耗料'),(12,2,'SALE',-200,1,2,N'标准耗料'),(13,3,'SALE',-2,1,2,N'标准耗料'),
 (21,1,'SALE',-300,2,2,N'标准耗料'),(22,2,'SALE',-150,2,2,N'标准耗料'),(23,3,'SALE',-1,2,2,N'标准耗料'),
 (31,1,'SALE',-150,3,2,N'标准耗料'),(32,2,'SALE',-200,3,2,N'标准耗料'),(33,3,'SALE',-1,3,2,N'标准耗料'),
 (41,1,'SALE',-200,4,2,N'标准耗料'),(42,2,'SALE',-100,4,2,N'标准耗料'),(43,3,'SALE',-1,4,2,N'标准耗料');
COMMIT;
GO



