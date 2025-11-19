/*Trigger*/
-- 1. Ngăn không cho nhập tổng tiền âm
CREATE TRIGGER trg_KhongXoaBacSiConLich
ON BACSI
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM LICHKHAM LK
        JOIN DELETED D ON LK.MaBS = D.MaBS
    )
    BEGIN
        RAISERROR(N'Không thể xóa bác sĩ vì còn lịch khám liên quan!',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    ELSE
        DELETE FROM BACSI WHERE MaBS IN (SELECT MaBS FROM DELETED);
END;

-- Giả sử bác sĩ BS01 có lịch khám
DELETE FROM BACSI WHERE MaBS = 'BS01';

GO

-- 2. Ghi log khi thêm bệnh nhân mới
IF OBJECT_ID('LogBenhNhan', 'U') IS NOT NULL
    DROP TABLE LogBenhNhan;
GO
CREATE TABLE LogBenhNhan (
    MaBN VARCHAR(10),
    NgayThem DATETIME
);
GO
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_LogBenhNhan')
    DROP TRIGGER trg_LogBenhNhan;
GO
CREATE TRIGGER trg_LogBenhNhan
ON BENHNHAN
AFTER INSERT
AS
INSERT INTO LogBenhNhan
SELECT MaBN, GETDATE() FROM inserted;
GO
INSERT INTO BENHNHAN VALUES 
('BN100', N'Nguyễn Minh An', '2000-05-12', N'Nam', N'Hà Nội', '0909123456');

SELECT * FROM LogBenhNhan;
GO
-- 3. Kiểm tra trùng lịch khám của bác sĩ
CREATE TRIGGER trg_KiemTraTrungLichKham
ON LICHKHAM
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM LICHKHAM L
        JOIN INSERTED I ON L.MaBS = I.MaBS 
        AND L.NgayKham = I.NgayKham 
        AND L.ThoiGianKham = I.ThoiGianKham
    )
    BEGIN
        RAISERROR(N'Bác sĩ đã có lịch khám tại thời điểm này!',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    ELSE
        INSERT INTO LICHKHAM(MaLK, NgayKham, ThoiGianKham, MaBS, MaBN)
        SELECT MaLK, NgayKham, ThoiGianKham, MaBS, MaBN FROM INSERTED;
END;
GO
INSERT INTO LICHKHAM VALUES
('LK10', '2025-11-03', '09:00', 'BS02', 'BN10');

-- 4. Khi xóa bệnh nhân → tự xóa lịch khám và hóa đơn liên quan
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_XoaBenhNhan')
    DROP TRIGGER trg_XoaBenhNhan;
GO
CREATE TRIGGER trg_XoaBenhNhan
ON BENHNHAN
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM LICHKHAM WHERE MaBN IN (SELECT MaBN FROM deleted);
    DELETE FROM HOADON WHERE MaBN IN (SELECT MaBN FROM deleted);
    DELETE FROM BENHNHAN WHERE MaBN IN (SELECT MaBN FROM deleted);
END;
GO
DELETE FROM BENHNHAN WHERE MaBN = 'BN05';
SELECT * FROM LICHKHAM WHERE MaBN = 'BN05';
SELECT * FROM HOADON WHERE MaBN = 'BN05';


-- 5. Khi cập nhật mã khoa của bác sĩ → in ra thông báo
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_ThongBaoCapNhatBS')
    DROP TRIGGER trg_ThongBaoCapNhatBS;
GO
CREATE TRIGGER trg_ThongBaoCapNhatBS
ON BACSI
AFTER UPDATE
AS
IF UPDATE(MaKhoa)
    PRINT N'⚠️ Bác sĩ đã được chuyển sang khoa khác!';
GO
UPDATE BACSI SET MaKhoa = 'K02' WHERE MaBS = 'BS01';


--6. Tự động cập nhật tổng tiền bệnh nhân khi thêm hóa đơn
--Thêm cột nếu chưa có
IF COL_LENGTH('BENHNHAN', 'TongChiPhi') IS NULL
BEGIN
    ALTER TABLE BENHNHAN ADD TongChiPhi DECIMAL(18,2) DEFAULT 0;
END
GO

-- Cập nhật tổng chi phí cho tất cả bệnh nhân dựa trên hóa đơn đã có
UPDATE BN
SET BN.TongChiPhi = ISNULL(Tong.HoaDonTong, 0)
FROM BENHNHAN BN
LEFT JOIN (
    SELECT MaBN, SUM(TongTien) AS HoaDonTong
    FROM HOADON
    GROUP BY MaBN
) Tong ON BN.MaBN = Tong.MaBN;
GO

-- Xóa trigger cũ nếu có
IF OBJECT_ID('trg_CapNhatTongTien_BenhNhan', 'TR') IS NOT NULL
    DROP TRIGGER trg_CapNhatTongTien_BenhNhan;
GO

-- Tạo lại trigger tự động cộng dồn cho hóa đơn mới
CREATE TRIGGER trg_CapNhatTongTien_BenhNhan
ON HOADON
AFTER INSERT
AS
BEGIN
    -- Cập nhật tổng chi phí khi có hóa đơn mới
    UPDATE BN
    SET BN.TongChiPhi = ISNULL(BN.TongChiPhi, 0) + I.TongTien
    FROM BENHNHAN BN
    JOIN INSERTED I ON BN.MaBN = I.MaBN;
END;
GO


INSERT INTO HOADON VALUES ('HD07', 'BN06', GETDATE(), 500000);
INSERT INTO HOADON VALUES ('HD08', 'BN06', GETDATE(), 300000);

SELECT MaBN, TongChiPhi FROM BENHNHAN WHERE MaBN = 'BN06';

--7. Tự động sinh mã hóa đơn
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_TuDongSinhMaHoaDon')
    DROP TRIGGER trg_TuDongSinhMaHoaDon;
GO
CREATE TRIGGER trg_TuDongSinhMaHoaDon
ON HOADON
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MaxSo INT, @MaMoi VARCHAR(10);

    -- Lấy số lớn nhất trong mã HD hiện có (VD: HD01 → 1, HD120 → 120)
    SELECT @MaxSo = ISNULL(MAX(CAST(SUBSTRING(MaHD, 3, LEN(MaHD)) AS INT)), 0)
    FROM HOADON;

    -- Duyệt tất cả dòng được chèn (có thể INSERT nhiều dòng 1 lúc)
    INSERT INTO HOADON (MaHD, MaBN, NgayLapHD, TongTien)
    SELECT
        -- Nếu người dùng không nhập MaHD, hệ thống tự sinh
        CASE 
            WHEN MaHD IS NULL OR MaHD = '' 
                THEN 'HD' + RIGHT(REPLICATE('0', 2) + CAST(@MaxSo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(10)), 
                                  CASE 
                                      WHEN @MaxSo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) < 100 THEN 2 
                                      ELSE LEN(CAST(@MaxSo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(10))) 
                                  END)
            ELSE MaHD
        END AS MaHD,
        MaBN,
        ISNULL(NgayLapHD, GETDATE()),
        ISNULL(TongTien, 0)
    FROM inserted;
END;
GO


INSERT INTO HOADON (MaBN, TongTien) VALUES ('BN02', 250000);
SELECT * FROM HOADON;
DELETE FROM HOADON
WHERE MaHD = 'HD009';

GO

INSERT INTO HOADON VALUES
('HD06', 'BN06', '2025-11-07', 250000);
INSERT INTO LICHKHAM VALUES
('LK06', '2025-11-07', '08:30', 'BS05', 'BN06');

-- 8> Ghi log xóa bệnh nhân
CREATE TABLE LOG_XOABENHNHAN (
    MaBN VARCHAR(10),
    TenBN NVARCHAR(50),
    NgayXoa DATETIME DEFAULT GETDATE(),
    NguoiThucHien NVARCHAR(50) DEFAULT SUSER_NAME()
);
GO

CREATE TRIGGER trg_LogXoaBenhNhan
ON BENHNHAN
AFTER DELETE
AS
BEGIN
    INSERT INTO LOG_XOABENHNHAN(MaBN, TenBN)
    SELECT MaBN, TenBN FROM DELETED;
END;
GO
DELETE FROM BENHNHAN WHERE MaBN = 'BN11';

SELECT * FROM LOG_XOABENHNHAN;
INSERT INTO BENHNHAN VALUES
('BN11', N'Nguyễn Đức An', '1999-03-15', N'Nam', N'Hà Nội', '0912987762', 0);
INSERT INTO LICHKHAM VALUES
('LK11', '2025-11-10', '08:30', 'BS01', 'BN11');
INSERT INTO HOADON VALUES
('HD11', 'BN11', '2025-11-10', 300000);
select * from BENHNHAN


