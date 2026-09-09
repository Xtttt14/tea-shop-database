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
IF OBJECT_ID(N'dbo.Product') IS NOT NULL THROW 50001, 'Schema exists; use a fresh course database.', 1;
BEGIN TRANSACTION;
CREATE TABLE dbo.Product (
 ProductID int NOT NULL PRIMARY KEY, ProductCode varchar(20) NOT NULL UNIQUE,
 ProductName nvarchar(60) NOT NULL, CupSize nvarchar(10) NOT NULL,
 Price decimal(10,2) NOT NULL, IsActive bit NOT NULL DEFAULT 1
);
CREATE TABLE dbo.Ingredient (
 IngredientID int NOT NULL PRIMARY KEY, IngredientName nvarchar(60) NOT NULL UNIQUE,
 Unit nvarchar(10) NOT NULL
);
CREATE TABLE dbo.Recipe (
 ProductID int NOT NULL REFERENCES dbo.Product(ProductID),
 IngredientID int NOT NULL REFERENCES dbo.Ingredient(IngredientID),
 Quantity decimal(12,3) NOT NULL, PRIMARY KEY(ProductID, IngredientID)
);
CREATE TABLE dbo.Stock (
 IngredientID int NOT NULL PRIMARY KEY REFERENCES dbo.Ingredient(IngredientID),
 OnHand decimal(12,3) NOT NULL, Reserved decimal(12,3) NOT NULL DEFAULT 0
);
CREATE TABLE dbo.Employee (
 EmployeeID int NOT NULL PRIMARY KEY, EmployeeCode varchar(20) NOT NULL UNIQUE,
 EmployeeName nvarchar(40) NOT NULL, Job varchar(20) NOT NULL, IsActive bit NOT NULL DEFAULT 1
);
CREATE TABLE dbo.Member (
 MemberID int NOT NULL PRIMARY KEY, MemberCode varchar(20) NOT NULL UNIQUE,
 DisplayName nvarchar(40) NOT NULL, Phone varchar(20) NOT NULL UNIQUE,
 Balance decimal(10,2) NOT NULL DEFAULT 0, Points int NOT NULL DEFAULT 0
);
CREATE TABLE dbo.Coupon (
 CouponID int NOT NULL PRIMARY KEY, CouponName nvarchar(60) NOT NULL,
 MinimumAmount decimal(10,2) NOT NULL, DiscountAmount decimal(10,2) NOT NULL,
 StartsAt datetime2(0) NOT NULL, ExpiresAt datetime2(0) NOT NULL
);
CREATE TABLE dbo.MemberCoupon (
 MemberCouponID int NOT NULL PRIMARY KEY, MemberID int NOT NULL REFERENCES dbo.Member(MemberID),
 CouponID int NOT NULL REFERENCES dbo.Coupon(CouponID), Status varchar(12) NOT NULL DEFAULT 'AVAILABLE',
 UNIQUE(MemberID, CouponID), UNIQUE(MemberCouponID, MemberID)
);
CREATE TABLE dbo.SalesOrder (
 OrderID int NOT NULL PRIMARY KEY, OrderNo varchar(30) NOT NULL UNIQUE,
 MemberID int NULL REFERENCES dbo.Member(MemberID), EmployeeID int NULL REFERENCES dbo.Employee(EmployeeID),
 Channel varchar(10) NOT NULL, Fulfillment varchar(10) NOT NULL,
 Status varchar(16) NOT NULL, CreatedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
 CompletedAt datetime2(0) NULL,
 GoodsAmount decimal(10,2) NOT NULL, DiscountAmount decimal(10,2) NOT NULL DEFAULT 0,
 DeliveryFee decimal(10,2) NOT NULL DEFAULT 0,
 Payable AS (GoodsAmount - DiscountAmount + DeliveryFee) PERSISTED,
 MemberCouponID int NULL,
 FOREIGN KEY(MemberCouponID, MemberID) REFERENCES dbo.MemberCoupon(MemberCouponID, MemberID)
);
CREATE UNIQUE INDEX UX_Order_ActiveCoupon ON dbo.SalesOrder(MemberCouponID)
 WHERE MemberCouponID IS NOT NULL AND Status <> 'CANCELLED' AND Status <> 'REFUNDED';
CREATE TABLE dbo.OrderItem (
 OrderID int NOT NULL REFERENCES dbo.SalesOrder(OrderID), LineNumber int NOT NULL,
 ProductID int NOT NULL REFERENCES dbo.Product(ProductID), ProductName nvarchar(60) NOT NULL,
 CupSize nvarchar(10) NOT NULL, Quantity int NOT NULL, UnitPrice decimal(10,2) NOT NULL,
 Sugar nvarchar(10) NOT NULL, Temperature nvarchar(10) NOT NULL,
 LineAmount AS (Quantity * UnitPrice) PERSISTED, PRIMARY KEY(OrderID, LineNumber)
);
CREATE TABLE dbo.Payment (
 PaymentID int NOT NULL PRIMARY KEY, OrderID int NOT NULL REFERENCES dbo.SalesOrder(OrderID),
 Kind varchar(10) NOT NULL, Channel varchar(10) NOT NULL, Amount decimal(10,2) NOT NULL,
 Status varchar(10) NOT NULL, ReferenceNo varchar(60) NOT NULL UNIQUE,
 OriginalPaymentID int NULL REFERENCES dbo.Payment(PaymentID),
 CreatedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME()
);
CREATE UNIQUE INDEX UX_Payment_OneSuccess ON dbo.Payment(OrderID, Kind) WHERE Status = 'SUCCESS';
CREATE TABLE dbo.WalletLedger (
 WalletID int NOT NULL PRIMARY KEY, MemberID int NOT NULL REFERENCES dbo.Member(MemberID),
 Kind varchar(10) NOT NULL, Delta decimal(10,2) NOT NULL,
 OrderID int NULL REFERENCES dbo.SalesOrder(OrderID),
 ReferenceNo varchar(60) NOT NULL UNIQUE, CreatedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.PointLedger (
 PointID int NOT NULL PRIMARY KEY, MemberID int NOT NULL REFERENCES dbo.Member(MemberID),
 OrderID int NOT NULL REFERENCES dbo.SalesOrder(OrderID), Kind varchar(10) NOT NULL,
 Delta int NOT NULL, UNIQUE(OrderID, Kind)
);
CREATE TABLE dbo.Delivery (
 OrderID int NOT NULL PRIMARY KEY REFERENCES dbo.SalesOrder(OrderID),
 Recipient nvarchar(40) NOT NULL, Phone varchar(20) NOT NULL, Address nvarchar(200) NOT NULL,
 RiderID int NULL REFERENCES dbo.Employee(EmployeeID), Status varchar(12) NOT NULL,
 PickedAt datetime2(0) NULL, DeliveredAt datetime2(0) NULL, ExceptionNote nvarchar(200) NULL
);
CREATE TABLE dbo.StockMovement (
 MovementID int NOT NULL PRIMARY KEY, IngredientID int NOT NULL REFERENCES dbo.Ingredient(IngredientID),
 Kind varchar(12) NOT NULL, Delta decimal(12,3) NOT NULL,
 OrderID int NULL REFERENCES dbo.SalesOrder(OrderID),
 EmployeeID int NOT NULL REFERENCES dbo.Employee(EmployeeID), Note nvarchar(200) NOT NULL,
 CreatedAt datetime2(0) NOT NULL DEFAULT SYSDATETIME()
);
COMMIT;
GO


