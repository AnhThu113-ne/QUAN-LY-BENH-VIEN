/*Hàm người dùng định nghĩa*/
-- 1. Tìm bệnh nhân theo tên gần đúng
CREATE FUNCTION fn_TimBenhNhanGanDung(@Ten NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT MaBN, TenBN, DiaChi, SDT
    FROM BENHNHAN
    WHERE TenBN LIKE '%' + @Ten + '%'
);

SELECT * FROM dbo.fn_TimBenhNhanGanDung(N'Nguyễn');
GO

-- 2. Lấy tên bác sĩ phụ trách điều trị cho bệnh nhân
CREATE FUNCTION fn_BacSiPhuTrach(@MaBN VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1 
        BS.MaBS, 
        BS.TenBS
    FROM LICHKHAM LK
    JOIN BACSI BS ON LK.MaBS = BS.MaBS
    WHERE LK.MaBN = @MaBN
    ORDER BY LK.NgayKham DESC
);

SELECT * FROM dbo.fn_BacSiPhuTrach('BN05');
GO

-- 3. Kiểm tra bệnh nhân có lịch khám hôm nay hay không
CREATE FUNCTION fn_CoLichKhamHomNay(@MaBN VARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @kq BIT = 0;
    IF EXISTS (SELECT * FROM LICHKHAM WHERE MaBN = @MaBN AND NgayKham = CAST(GETDATE() AS DATE))
        SET @kq = 1;
    RETURN @kq;
END;

SELECT dbo.fn_CoLichKhamHomNay('BN03') AS CoHenHomNay;
GO

-- 4. Kiểm tra bệnh nhân có hóa đơn hay chưa
CREATE FUNCTION fn_CoHoaDon(@MaBN VARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @kq BIT = 0;
    IF EXISTS (SELECT * FROM HOADON WHERE MaBN = @MaBN)
        SET @kq = 1;
    RETURN @kq;
END;

SELECT dbo.fn_CoHoaDon('BN01') AS CoHoaDon;
GO

-- 5. Tính số ngày kể từ lần khám gần nhất
CREATE FUNCTION fn_SoNgayTuLanKhamGanNhat(@MaBN VARCHAR(10))
RETURNS INT
AS
BEGIN
    DECLARE @NgayCuoi DATE;
    SELECT @NgayCuoi = MAX(NgayKham) FROM LICHKHAM WHERE MaBN = @MaBN;
    RETURN DATEDIFF(DAY, @NgayCuoi, GETDATE());
END;

SELECT dbo.fn_SoNgayTuLanKhamGanNhat('BN05') AS SoNgay;
GO

-- 6. Hàm kiểm tra bác sĩ có lịch khám trong ngày chưa
CREATE FUNCTION fn_BacSiDaCoLichHomNay(@MaBS VARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @kq BIT = 0;
    IF EXISTS (SELECT * FROM LICHKHAM WHERE MaBS = @MaBS AND NgayKham = CAST(GETDATE() AS DATE))
        SET @kq = 1;
    RETURN @kq;
END;

SELECT dbo.fn_BacSiDaCoLichHomNay('BS01') AS DaCoLich;
GO

-- 7. Tính số ngày kể từ lần khám gần nhất
CREATE FUNCTION fn_DanhSachBenhNhanTheoBacSi(@MaBS VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT BN.MaBN, BN.TenBN, BN.GioiTinh, BN.NgaySinh
    FROM BENHNHAN BN
    JOIN LICHKHAM LK ON BN.MaBN = LK.MaBN
    WHERE LK.MaBS = @MaBS
);

SELECT * FROM dbo.fn_DanhSachBenhNhanTheoBacSi('BS02');
GO