USE MASTER;
GO
ALTER DATABASE QLBENHVIEN SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
IF EXISTS (SELECT * FROM  SYS.DATABASES WHERE NAME = 'QLBENHVIEN')
    DROP DATABASE QLBENHVIEN;
GO
CREATE DATABASE QLBENHVIEN;
GO
USE QLBENHVIEN;
GO
/*Tạo các bảng trên và khai báo khóa chính, khóa ngoại.*/

CREATE TABLE BENHNHAN (
    MaBN VARCHAR(10) PRIMARY KEY,
    TenBN NVARCHAR(50) NOT NULL,
    NgaySinh DATE NOT NULL,
    GioiTinh NVARCHAR(5) NOT NULL CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    DiaChi NVARCHAR(100),
    SDT VARCHAR(15)
);

GO
CREATE TABLE KHOA (
    MaKhoa VARCHAR(10) PRIMARY KEY,
    TenKhoa NVARCHAR(50) NOT NULL
);

GO
CREATE TABLE BACSI (
    MaBS VARCHAR(10) PRIMARY KEY,
    TenBS NVARCHAR(50) NOT NULL,
    ChuyenKhoa NVARCHAR(100) NOT NULL,
    MaKhoa VARCHAR(10) References KHOA(MaKhoa)
);

GO
CREATE TABLE HOADON (
    MaHD VARCHAR(10) PRIMARY KEY,
    MaBN VARCHAR(10) NOT NULL,
    NgayLapHD DATE NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(18,2) NOT NULL CHECK (TongTien >= 0),
    CONSTRAINT FK_HOADON_BENHNHAN FOREIGN KEY (MaBN) REFERENCES BENHNHAN(MaBN)
);

GO
CREATE TABLE LICHKHAM (
    MaLK VARCHAR(10) PRIMARY KEY,
    NgayKham DATE NOT NULL DEFAULT GETDATE(),
    ThoiGianKham TIME NOT NULL,
	MaBS VARCHAR(10) NOT NULL,
    MaBN VARCHAR(10) NOT NULL,
    CONSTRAINT FK_LICHKHAM_BACSI FOREIGN KEY (MaBS) REFERENCES BACSI(MaBS),
    CONSTRAINT FK_LICHKHAM_BENHNHAN FOREIGN KEY (MaBN) REFERENCES BENHNHAN(MaBN)
);
GO

/*--- Dữ liệu KHOA ---*/
INSERT INTO KHOA VALUES 
('K01', N'Nội Tổng Hợp'),
('K02', N'Ngoại Chấn Thương'),
('K03', N'Nhi Khoa'),
('K04', N'Tim Mạch'),
('K05', N'Tai Mũi Họng');

/*--- Dữ liệu BỆNH NHÂN ---*/
INSERT INTO BENHNHAN VALUES
('BN01', N'Nguyễn Văn Tuấn', '1990-03-15', N'Nam', N'Hà Nội', '0912345678'),
('BN02', N'Trần Thị Bích', '1985-07-22', N'Nữ', N'Hải Phòng', '0987654321'),
('BN03', N'Lê Văn Chiến', '2000-12-05', N'Nam', N'Nam Định', '0909123456'),
('BN04', N'Phạm Thị Dung', '1995-05-10', N'Nữ', N'Ninh Bình', '0934567890'),
('BN05', N'Đỗ Văn Huy', '1988-09-19', N'Nam', N'Hà Nam', '0978123456');

/*--- Dữ liệu BÁC SĨ ---*/
INSERT INTO BACSI VALUES
('BS01', N'Nguyễn Hữu Minh', N'Nội tổng hợp', 'K01'),
('BS02', N'Trần Văn Thắng', N'Ngoại tổng hợp', 'K02'),
('BS03', N'Lê Thị Hồng', N'Nhi khoa', 'K03'),
('BS04', N'Phạm Văn Nam', N'Tim mạch', 'K04'),
('BS05', N'Hoàng Thị Lan', N'Tai Mũi Họng', 'K05');

/*--- Dữ liệu LỊCH KHÁM ---*/
INSERT INTO LICHKHAM VALUES
('LK01', CAST(GETDATE() AS DATE), '08:30', 'BS01', 'BN01'),
('LK02', '2025-11-03', '09:00', 'BS02', 'BN02'),
('LK03', '2025-11-04', '10:15', 'BS03', 'BN03'),
('LK04', CAST(GETDATE() AS DATE), '13:45', 'BS04', 'BN04'),
('LK05', '2025-11-05', '15:30', 'BS05', 'BN05');
SELECT * FROM BACSI;
SELECT * FROM LICHKHAM;
SELECT * FROM HOADON;

/*--- Dữ liệu HÓA ĐƠN ---*/
INSERT INTO HOADON VALUES
('HD01', 'BN01', '2025-11-02', 250000),
('HD02', 'BN02', '2025-11-03', 350000),
('HD03', 'BN03', '2025-11-04', 150000),
('HD04', 'BN04', '2025-11-04', 500000),
('HD05', 'BN05', '2025-11-05', 420000);
GO

/*===========================================================
  KIỂM TRA DỮ LIỆU
===========================================================*/
SELECT * FROM KHOA;
SELECT * FROM BENHNHAN;
SELECT * FROM BACSI;
SELECT * FROM LICHKHAM;
SELECT * FROM HOADON;

/*Các chỉ mục*/
-- 1. Tìm nhanh bệnh nhân theo tên
CREATE INDEX IDX_BENHNHAN_TenBN ON BENHNHAN(TenBN);

-- 2. Tìm bệnh nhân theo số điện thoại
CREATE INDEX IDX_BENHNHAN_SDT ON BENHNHAN(SDT);

-- 3. Tăng hiệu suất tìm kiếm lịch khám theo ngày.
CREATE INDEX IDX_LICHKHAM_NgayKham ON LICHKHAM(NgayKham);

-- 4. Tìm bác sĩ theo khoa
CREATE INDEX IDX_BACSI_MaKhoa ON BACSI(MaKhoa);

-- 5. Tìm hóa đơn theo bệnh nhân
CREATE INDEX IDX_HOADON_MaBN ON HOADON(MaBN);
GO



