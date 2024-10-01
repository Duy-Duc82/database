--2 Tìm kiếm tất cả các giao dịch ủng hộ trong khoảng 30 phút gần đây nhất.
SELECT * FROM ung_ho
WHERE thoi_gian_uh >= NOW() - INTERVAL '30 minutes';
-------------------------------------------------------------------------------------------
--9 Tìm kiếm tất cả nhà hảo tâm không sử dụng tài khoản
SELECT * FROM nha_hao_tam 
WHERE ho_va_ten is null;
-------------------------------------------------------------------------------------------
--12 Trả về top 10 chiến dịch có số lượng người ủng hộ trong 1 tuần (gần nhất) nhiều nhất
SELECT cd.id_chien_dich, cd.ten_chien_dich, COUNT(uh.id_giao_dich) AS so_luong_ung_ho FROM chien_dich_gay_quy cd
JOIN ung_ho uh ON cd.id_chien_dich = uh.id_chien_dich
WHERE uh.thoi_gian_uh >= (NOW() - INTERVAL '1 WEEK') AND uh.thoi_gian_uh <= NOW()
GROUP BY cd.id_chien_dich
ORDER BY so_luong_ung_ho DESC
LIMIT 10;
-------------------------------------------------------------------------------------------
--13 Tìm kiếm tất cả các chiến dịch sắp kết thúc (Còn 1 tuần cho đến ngày đáo hạn)
SELECT * FROM chien_dich_gay_quy
WHERE ngay_ket_thuc <= NOW() + INTERVAL '1 WEEK' ;
-------------------------------------------------------------------------------------------
--15 Trả về top 10 chiến dịch có số lượng người theo dõi nhiều nhất
SELECT cd.id_chien_dich, COUNT(td.id_chien_dich) AS luot_theo_doi, cd.ten_chien_dich
FROM chien_dich_gay_quy cd
LEFT JOIN theo_doi td ON cd.id_chien_dich = td.id_chien_dich
GROUP BY cd.id_chien_dich, cd.ten_chien_dich
ORDER BY luot_theo_doi DESC
LIMIT 10;
-------------------------------------------------------------------------------------------
--17 "Trả về top 10 chiến dịch có số lượng theo dõi trong 1 tuần tăng nhanh nhất (Top trending)"
SELECT 
    id_chien_dich, 
    COUNT(id_tai_khoan) AS so_luong_theo_doi
FROM 
    theo_doi
WHERE 
    thoi_gian_theo_doi >= (
        SELECT NOW() - INTERVAL '1 week'
    )
GROUP BY 
    id_chien_dich
ORDER BY 
    so_luong_theo_doi DESC
LIMIT 10;
-------------------------------------------------------------------------------------------
--19 "Trả về top 10 tổ chức tích cực thỏa mãn:
--Có nhiều chiến dịch gây quỹ. 
--Các chiến dịch gây quỹ đó được ủng hộ nhiều (Các chiến dịch đều đạt mục tiêu >=50%)
--Sắp xếp theo thứ tự giảm dần về số lượng chiến dịch đạt >=70%. Tổ chức nào có số 
--lượng chiến dịch đạt >=70% nhiều hơn xếp trên)"
WITH campaign_stats AS (
    SELECT
        tc.id_to_chuc,
        tc.ten_to_chuc,
        cd.id_chien_dich,
        cd.ten_chien_dich,
        cd.muc_tieu,
        COALESCE(SUM(uh.so_tien), '0'::money) AS tong_tien_quyen_gop,
        (COALESCE(SUM(uh.so_tien), '0'::money) / cd.muc_tieu) * 100 AS phan_tram_dat_duoc
    FROM
        to_chuc_tu_thien tc
    JOIN
        to_chuc_chien_dich tccd ON tc.id_to_chuc = tccd.id_to_chuc
    JOIN
        chien_dich_gay_quy cd ON tccd.id_chien_dich = cd.id_chien_dich
    LEFT JOIN
        ung_ho uh ON cd.id_chien_dich = uh.id_chien_dich
    GROUP BY
        tc.id_to_chuc, tc.ten_to_chuc, cd.id_chien_dich, cd.ten_chien_dich, cd.muc_tieu
    HAVING
        (COALESCE(SUM(uh.so_tien), '0'::money) / cd.muc_tieu) >= 0.50
),
organization_ranking AS (
    SELECT
        id_to_chuc,
        ten_to_chuc,
        COUNT(*) AS total_campaigns,
        SUM(CASE WHEN phan_tram_dat_duoc >= 70 THEN 1 ELSE 0 END) AS campaigns_above_70
    FROM
        campaign_stats
    GROUP BY
        id_to_chuc, ten_to_chuc
    HAVING
        COUNT(*) > 0
)
SELECT
    id_to_chuc,
    ten_to_chuc,
    total_campaigns,
    campaigns_above_70
FROM
    organization_ranking
ORDER BY
    campaigns_above_70 DESC,
    total_campaigns DESC
LIMIT 10;
-------------------------------------------------------------------------------------------
--24
SELECT id_giao_dich, thoi_gian_uh AS thoi_gian, ngan_hang_nht, so_tien, loi_chuc
FROM ung_ho
WHERE thoi_gian_uh >= NOW() - INTERVAL '1 MONTH'
UNION ALL 
-- Lấy các giao dịch sử dụng quỹ trong vòng 1 tháng kể từ thời điểm hiện tại --
SELECT id_giao_dich, thoi_gian_giao_dich AS thoi_gian, NULL AS ngan_hang_nht, so_tien, NULL AS loi_chuc
FROM su_dung_quy
WHERE thoi_gian_giao_dich >= NOW() - INTERVAL '1 MONTH';
--Son

--13 Tìm kiếm tất cả các chiến dịch sắp kết thúc (Còn 1 tuần (hoặc ít hơn )cho đến ngày đáo hạn)
SELECT *
FROM chien_dich_gay_quy
WHERE ngay_ket_thuc-CURRENT_DATE<=7 and CURRENT_DATE<=ngay_ket_thuc;

--17 "Trả về top 10 chiến dịch có số lượng theo dõi trong 1 tuần tăng nhanh nhất (Top trending)"
SELECT 
    id_chien_dich, 
    COUNT(id_tai_khoan) AS so_luong_theo_doi
FROM 
    theo_doi
WHERE 
    thoi_gian_theo_doi >= (
        SELECT NOW() - INTERVAL '1 week'
    )
GROUP BY 
    id_chien_dich
ORDER BY 
    so_luong_theo_doi DESC
LIMIT 10;

--6 Tìm kiếm tất cả các giao dịch ủng hộ trong khoảng từ ngày ? đến ngày ?
create or replace function tim_cd_theo_ngay (ngay_bat_dau date, ngay_ket_thuc date)
returns table (
	id_giao_dich varchar(20),
	id_chien_dich varchar(20),
	id_nha_hao_tam varchar(20),
	loi_chuc varchar(100),
	thoi_gian_uh timestamp without time zone,
	so_tien money,
	so_tai_khoan_nht varchar(20),
	ngan_hang_nht varchar(100)
)
language plpgsql
as $$
begin 
	return query 
		SELECT *
		FROM ung_ho
		WHERE ung_ho.thoi_gian_uh BETWEEN ngay_bat_dau AND ngay_ket_thuc;
end;
$$;

--10 Tìm kiếm tất cả chiến dịch được thành lập trong 1 tuần gần nhất
create or replace function tim_cd_gan_day (khoang_tg interval)
returns table (
	id_chien_dich varchar(20), 
	ten_chien_dich varchar(100),
	gioi_thieu_chien_dich varchar(200),
	muc_tieu money,
	ngay_bat_dau date,
	so_tai_khoan varchar(20),
	ngan_hang varchar(100),
	ngay_ket_thuc date
)
language plpgsql
as $$
begin 
	return query 
		SELECT *
		FROM chien_dich_gay_quy cdgq
		WHERE cdgq.ngay_bat_dau >= (
    		SELECT NOW() - khoang_tg);
end;

--Danh sach nha hao tam cung voi so luot ung ho va so tien ung ho tren tat ca cac chien dich, sap xep theo tu giam dan so tien ung ho
SELECT 
    nh.id_nha_hao_tam, 
    nh.ho_va_ten,
    COUNT(uh.id_giao_dich) AS so_lan_ung_ho,
    SUM(uh.so_tien) AS tong_so_tien_ung_ho
FROM nha_hao_tam nh
LEFT JOIN ung_ho uh ON nh.id_nha_hao_tam = uh.id_nha_hao_tam
GROUP BY nh.id_nha_hao_tam, nh.ho_va_ten
ORDER BY tong_so_tien_ung_ho DESC;

--21 Danh sách những tổ chức (id, tên, thời gian tham gia) và tổng số tiền đã gây quỹ được 
--(Tính trên tất cả các chiến dịch gây quỹ)
SELECT 
    tc.id_to_chuc,
    tc.ten_to_chuc,
    ttk.thoi_gian_tao_tk,
    COALESCE(SUM(uh.so_tien), 0::money) AS tong_so_tien_gay_quy
FROM 
    to_chuc_tu_thien tc
JOIN 
    tk_to_chuc ttk ON tc.id_to_chuc = ttk.id_to_chuc
LEFT JOIN 
    to_chuc_chien_dich tcc ON tc.id_to_chuc = tcc.id_to_chuc
LEFT JOIN 
    chien_dich_gay_quy cd ON tcc.id_chien_dich = cd.id_chien_dich
LEFT JOIN 
    ung_ho uh ON cd.id_chien_dich = uh.id_chien_dich
GROUP BY 
    tc.id_to_chuc, tc.ten_to_chuc, ttk.thoi_gian_tao_tk;

--25 "Danh sách những dự án (Đang thực hiện/Đạt mục tiêu/Đã kết thúc), 
--(Còn bao nhiêu ngày), (Tỉ lệ mục tiêu), (Số lượng người đã ủng hộ) "
SELECT
    cd.id_chien_dich,
    cd.ten_chien_dich,
    CASE
        WHEN CURRENT_DATE >= cd.ngay_bat_dau AND CURRENT_DATE <= cd.ngay_ket_thuc AND COALESCE(SUM(uh.so_tien), 0::money) < cd.muc_tieu THEN 'Dang thuc hien'
        WHEN COALESCE(SUM(uh.so_tien), 0::money) >= cd.muc_tieu THEN 'Dat muc tieu'
        WHEN CURRENT_DATE > cd.ngay_ket_thuc THEN 'Da ket thuc'
    END AS trang_thai,
    GREATEST(cd.ngay_ket_thuc - CURRENT_DATE, 0) AS ngay_con_lai,
    COALESCE(SUM(uh.so_tien), 0::money) AS tong_so_tien_gay_quy_duoc,
     muc_tieu,
    (SELECT COUNT(*) FROM ung_ho WHERE ung_ho.id_chien_dich = cd.id_chien_dich) AS so_luong_ung_ho
FROM
    chien_dich_gay_quy cd
LEFT JOIN
    ung_ho uh ON cd.id_chien_dich = uh.id_chien_dich
GROUP BY
    cd.id_chien_dich,
    cd.ten_chien_dich,
    cd.ngay_bat_dau,
    cd.ngay_ket_thuc,
    cd.muc_tieu
ORDER BY
    cd.id_chien_dich;


    










