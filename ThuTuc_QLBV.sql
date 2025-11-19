/*Thủ tục*/
-- 1. Đếm số lịch khám của từng bác sĩ.
CREATE PROCEDURE sp_DemSoLichKham_BacSi
AS
SELECT BS.TenBS, COUNT(LK.MaLK) AS SoLichKham
FROM BACSI BS LEFT JOIN LICHKHAM LK ON BS.MaBS = LK.MaBS
GROUP BY BS.TenBS;

EXEC sp_DemSoLichKham_BacSi;
GO

-- 2. Tìm kiếm bệnh nhân theo mã
CREATE PROCEDURE sp_TimBenhNhanTheoMa @MaBN VARCHAR(10)
AS SELECT * FROM BENHNHAN WHERE MaBN = @MaBN;

EXEC sp_TimBenhNhanTheoMa @MaBN = 'BN01';
GO

-- 3. Tính tổng tiền hóa đơn của một bệnh nhân
CREATE PROCEDURE sp_TinhTongTienBenhNhan @MaBN VARCHAR(10)
AS
SELECT BN.TenBN, SUM(TongTien) AS TongTien
FROM HOADON HD JOIN BENHNHAN BN ON HD.MaBN = BN.MaBN
WHERE HD.MaBN = @MaBN GROUP BY BN.TenBN;

EXEC sp_TinhTongTienBenhNhan @MaBN = 'BN03';
GO

-- 4. Thêm bệnh nhân mới
CREATE PROCEDURE sp_ThemBenhNhan 
    @MaBN VARCHAR(10), @TenBN NVARCHAR(50), @NgaySinh DATE, 
    @GioiTinh NVARCHAR(5), @DiaChi NVARCHAR(100), @SDT VARCHAR(15)
AS
INSERT INTO BENHNHAN VALUES (@MaBN, @TenBN, @NgaySinh, @GioiTinh, @DiaChi, @SDT);

EXEC sp_ThemBenhNhan 
    @MaBN = 'BN11', 
    @TenBN = N'Lê Văn Nam', 
    @NgaySinh = '1995-10-12', 
    @GioiTinh = N'Nam', 
    @DiaChi = N'Hà Nội', 
    @SDT = '0912345678';
EXEC sp_ThemBenhNhan 
    @MaBN = 'BN06', 
    @TenBN = N'Trần Ánh Ngọc', 
    @NgaySinh = '2001-10-10', 
    @GioiTinh = N'Nữ', 
    @DiaChi = N'Hà Nội', 
    @SDT = '0916778241';
SELECT * FROM BENHNHAN WHERE MaBN = 'BN10';
GO

-- 5. Cập nhật địa chỉ bệnh nhân
CREATE PROCEDURE sp_CapNhatDiaChiBenhNhan @MaBN VARCHAR(10), @DiaChi NVARCHAR(100)
AS
UPDATE BENHNHAN SET DiaChi = @DiaChi WHERE MaBN = @MaBN;

EXEC sp_CapNhatDiaChiBenhNhan 
    @MaBN = 'BN10', 
    @DiaChi = N'Hồ Chí Minh';
SELECT * FROM BENHNHAN WHERE MaBN = 'BN10';
GO

-- 6. Xóa bệnh nhân theo mã
CREATE PROCEDURE sp_XoaBenhNhanTheoMa
    @MaBN VARCHAR(10)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM BENHNHAN WHERE MaBN = @MaBN)
    BEGIN
        DELETE FROM BENHNHAN WHERE MaBN = @MaBN;
        PRINT N'Đã xóa bệnh nhân có mã ' + @MaBN;
    END
    ELSE
    BEGIN
        PRINT N'Không tìm thấy bệnh nhân có mã ' + @MaBN;
    END
END;

EXEC sp_XoaBenhNhanTheoMa @MaBN = 'BN10';
SELECT * FROM BENHNHAN WHERE MaBN = 'BN10';
GO
