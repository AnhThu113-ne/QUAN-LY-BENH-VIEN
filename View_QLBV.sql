/*View*/
-- 1. View thông tin khám bệnh tổng hợp
CREATE VIEW VW_ThongTinKhamBenh AS
SELECT LK.MaLK, BN.TenBN, BS.TenBS, K.TenKhoa, LK.NgayKham, LK.ThoiGianKham
FROM LICHKHAM LK
JOIN BENHNHAN BN ON LK.MaBN = BN.MaBN
JOIN BACSI BS ON LK.MaBS = BS.MaBS
JOIN KHOA K ON BS.MaKhoa = K.MaKhoa;

SELECT * FROM VW_ThongTinKhamBenh
GO

-- 2. View danh sách hóa đơn cùng tên bệnh nhân
CREATE VIEW VW_HoaDonBenhNhan AS
SELECT HD.MaHD, BN.TenBN, HD.NgayLapHD, HD.TongTien
FROM HOADON HD 
JOIN BENHNHAN BN ON HD.MaBN = BN.MaBN;

SELECT * FROM VW_HoaDonBenhNhan
GO

-- 3. View danh sách bác sĩ và khoa làm việc
CREATE VIEW VW_BacSiKhoa AS
SELECT BS.MaBS, BS.TenBS, BS.ChuyenKhoa, K.TenKhoa
FROM BACSI BS JOIN KHOA K ON BS.MaKhoa = K.MaKhoa;
SELECT * FROM VW_BacSiKhoa
GO

-- 4. View tổng tiền hóa đơn theo từng bệnh nhân
CREATE VIEW VW_LichKhamHomNay AS
SELECT LK.MaLK, BN.TenBN, BS.TenBS, LK.ThoiGianKham
FROM LICHKHAM LK
JOIN BENHNHAN BN ON LK.MaBN = BN.MaBN
JOIN BACSI BS ON LK.MaBS = BS.MaBS
WHERE LK.NgayKham = CAST(GETDATE() AS DATE);

drop view VW_LichKhamHomNay
SELECT * FROM VW_LichKhamHomNay
GO

-- 5. View danh sách bệnh nhân và số lần khám
CREATE VIEW VW_SoLanKham AS
SELECT BN.TenBN, COUNT(LK.MaLK) AS SoLanKham
FROM BENHNHAN BN LEFT JOIN LICHKHAM LK ON BN.MaBN = LK.MaBN
GROUP BY BN.TenBN;

SELECT * FROM VW_SoLanKham
GO