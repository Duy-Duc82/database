--Bang thuc the--
------------------------------------------------
CREATE TABLE nha_hao_tam (
 id_nha_hao_tam VARCHAR(20) PRIMARY KEY,
 ho_va_ten VARCHAR(100),
	mail VARCHAR(25),
	id_tai_khoan VARCHAR(20)
);

CREATE TABLE chien_dich_gay_quy(
	id_chien_dich VARCHAR(20) PRIMARY KEY,
	ten_chien_dich VARCHAR(100) NOT NULL,
	gioi_thieu_chien_dich VARCHAR(200),
	muc_tieu MONEY NOT NULL,
	ngay_bat_dau date NOT NULL,
	so_tai_khoan VARCHAR(20) NOT NULL,
    	ngan_hang VARCHAR(100) NOT NULL,
	ngay_ket_thuc date NOT NULL
);

CREATE TABLE gia_dinh_thu_huong (
    id_ho_gia_dinh VARCHAR(20) PRIMARY KEY,
    so_tai_khoan VARCHAR(20) NOT NULL,
    ngan_hang VARCHAR(100) NOT NULL,
    so_dien_thoai VARCHAR(15) NOT NULL,
    ten_ho_gia_dinh VARCHAR(100) NOT NULL,
    thanh_pho VARCHAR(30) NOT NULL,
    quan VARCHAR(30) NOT NULL
);

CREATE TABLE tai_khoan (
    id_tai_khoan VARCHAR(20) PRIMARY KEY,
    ten_dang_nhap VARCHAR(50) NOT NULL,
    loai_tk VARCHAR(20) NOT NULL,
    mat_khau VARCHAR(50) NOT NULL
);

CREATE TABLE to_chuc_tu_thien (
    id_to_chuc VARCHAR(20) PRIMARY KEY,
    ten_to_chuc VARCHAR(50),
    website VARCHAR(100),
    tru_so VARCHAR(200),
    sdt VARCHAR(15),
    id_tai_khoan VARCHAR(20),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan)
);
------------------------------------------------

--Bang quan he--
------------------------------------------------
CREATE TABLE ung_ho(
	id_giao_dich VARCHAR(20) PRIMARY KEY,
	id_chien_dich VARCHAR(20),
	id_nha_hao_tam VARCHAR(20),
	loi_chuc VARCHAR(100),
	thoi_gian_uh TIMESTAMP NOT null,
	so_tien MONEY,
so_tai_khoan_nht VARCHAR(20) NOT NULL,
    	ngan_hang_nht VARCHAR(100) NOT NULL,
	FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich),
	FOREIGN KEY (id_nha_hao_tam) REFERENCES nha_hao_tam(id_nha_hao_tam)
);



CREATE TABLE tk_to_chuc (
    id_to_chuc VARCHAR(20),
    id_tai_khoan VARCHAR(20),
    thoi_gian_tao_tk TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_to_chuc, id_tai_khoan),
    FOREIGN KEY (id_to_chuc) REFERENCES to_chuc_tu_thien(id_to_chuc),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan)
);

CREATE TABLE tk_nha_hao_tam (
    id_nha_hao_tam VARCHAR(20),
    id_tai_khoan VARCHAR(20),
    thoi_gian_tao_tk TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_nha_hao_tam, id_tai_khoan),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan),
	FOREIGN KEY (id_nha_hao_tam) REFERENCES nha_hao_tam(id_nha_hao_tam)
);


CREATE TABLE su_dung_quy (
    id_chien_dich VARCHAR(20),
    id_ho_gia_dinh VARCHAR(20),
    id_giao_dich VARCHAR(20),
    so_tien MONEY,
    thoi_gian_giao_dich TIMESTAMP NOT NULL,
    PRIMARY KEY (id_chien_dich, id_ho_gia_dinh, id_giao_dich),
    FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich),
    FOREIGN KEY (id_ho_gia_dinh) REFERENCES gia_dinh_thu_huong(id_ho_gia_dinh)
);

CREATE TABLE gay_quy (
    id_chien_dich VARCHAR(20),
    id_tai_khoan VARCHAR(20),
    PRIMARY KEY (id_chien_dich, id_tai_khoan),
    FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan)
);

CREATE TABLE theo_doi (
    id_tai_khoan VARCHAR(20),
    id_chien_dich VARCHAR(20),
    thoi_gian_theo_doi TIMESTAMP NOT NULL,
    PRIMARY KEY (id_tai_khoan, id_chien_dich),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan),
    FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich)
);

CREATE TABLE chia_se (
    id_bai_viet VARCHAR(20) PRIMARY KEY,
    noi_dung TEXT,
    id_chien_dich VARCHAR(20),
    id_tai_khoan VARCHAR(20),
    thoi_gian_chia_se TIMESTAMP NOT NULL,
    FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich),
    FOREIGN KEY (id_tai_khoan) REFERENCES tai_khoan(id_tai_khoan)
);

CREATE TABLE to_chuc_chien_dich (
    id_to_chuc VARCHAR(20),
    id_chien_dich VARCHAR(20),
    PRIMARY KEY (id_to_chuc, id_chien_dich),
    FOREIGN KEY (id_to_chuc) REFERENCES to_chuc_tu_thien(id_to_chuc),
    FOREIGN KEY (id_chien_dich) REFERENCES chien_dich_gay_quy(id_chien_dich)
);

CREATE OR REPLACE FUNCTION check_campaign_goal()
RETURNS TRIGGER AS $$
DECLARE
    total_amount numeric;
BEGIN
    SELECT COALESCE(SUM(so_tien::numeric), 0) INTO total_amount
    FROM ung_ho
    WHERE id_chien_dich = NEW.id_chien_dich;
    
    total_amount := total_amount + NEW.so_tien::numeric;

    IF total_amount >= (SELECT muc_tieu::numeric FROM chien_dich_gay_quy WHERE id_chien_dich = NEW.id_chien_dich) THEN
        RAISE NOTICE 'Chien dich da hoan thanh muc tieu, cam on moi nguoi da ung ho';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_ung_ho
BEFORE INSERT ON ung_ho
FOR EACH ROW
EXECUTE FUNCTION check_campaign_goal();

CREATE OR REPLACE FUNCTION check_campaign_date()
RETURNS TRIGGER AS $$
DECLARE
    ngay_end date;
BEGIN
    SELECT ngay_ket_thuc INTO ngay_end
    FROM chien_dich_gay_quy
    WHERE id_chien_dich = NEW.id_chien_dich;
    

    IF CURRENT_DATE>ngay_end THEN
        RAISE NOTICE 'Chien dich da ket thuc, cam on moi nguoi da ung ho';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_ung_ho_2
BEFORE INSERT ON ung_ho
FOR EACH ROW
EXECUTE FUNCTION check_campaign_date();




