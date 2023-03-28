create or replace Procedure         P_CTAF008_INSERT
  (v_ct_pc_lend_d_seq NUMBER, v_position_no varchar2,v_times NUMBER,v_start_date DATE,v_end_date DATE,v_insert out VARCHAR2) IS

-- Purpose: 回傳新增狀態及訊息
--
-- MODIFICATION HISTORY
-- Person      Date        Comments
-- ---------   ----------  -------------------------------------------
-- sandy     2013/01/22  1.00 for pda保留確認

  v_date_e                       DATE;  
  v_count                         NUMBER :=0;
  v_count1                       NUMBER :=0;
  v_count2                       NUMBER :=0;
  v_count3                       NUMBER :=0;
  v_count4                       NUMBER :=0;
  v_pc_no                        VARCHAR2(10);  --設備編號
  v_lend_idno                   VARCHAR2(10);  --帶看人身份證字號
  v_lend_name                 VARCHAR2(32);  --帶看人姓名
  v_lend_tel                      VARCHAR2(20);  --帶看人電話
  v_customer_name          VARCHAR2(32);  --客戶姓名
  v_customer_telphone     VARCHAR2(20);   --客戶電話
  v_agent_name               VARCHAR2(32);   --業務員姓名
  v_agent_telphone           VARCHAR2(20);  --業務電話
  v_ct_pc_lend_m_seq       NUMBER(15);      --設備借用歸還主檔序號
  v_ct_position_res_m_seq NUMBER(15);     --選位保留主檔序號
  v_ct_position_res_d_seq NUMBER(15);     --選位保留明細檔序號
  v_apply_no                     VARCHAR2(14); --申請單號
  v_create_name               VARCHAR2(32); --建立者姓名
  v_insert_status               VARCHAR2(1);    --新增狀態 
  v_insert_failure               VARCHAR2(100); --新增訊息
  v_item_no                      NUMBER(4);         --項次
  v_memo                        VARCHAR2(100);  --備註


BEGIN
    BEGIN
       SELECT user_desc
         INTO v_create_name
         FROM app_users
        WHERE username = USER;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            v_create_name := USER;
    END;


    --取選位保留明細檔序號
    SELECT ct_position_res_d_seq.NEXTVAL
                INTO v_ct_position_res_d_seq
      FROM DUAL;

   --check同一平板同一帶看人同一次借用之位置不可重覆保留   
  SELECT ct_pc_lend_m_seq INTO v_ct_pc_lend_m_seq
     FROM ct_pc_lend_d
   WHERE ct_pc_lend_d_seq = v_ct_pc_lend_d_seq;

   SELECT count(*) INTO v_count3
      FROM ct_position_res_m a,ct_position_res_d b
    WHERE a.seg_segment_no='LP'
         AND a.ct_position_res_m_seq=b.ct_position_res_m_seq
         AND a.CT_PC_LEND_M_SEQ=v_ct_pc_lend_m_seq
         AND b.position_no=v_position_no;

   IF v_count3 > 0 THEN
       v_insert_status:='F';
       v_insert_failure:='新增失敗,同一位置只能保留一次';      
   ELSE
        v_insert_status:='T';
   END IF;

  --check 該位置該日期區間尚未被保留
   IF v_insert_status='T' THEN
    SELECT MAX(end_date)  INTO v_date_e 
      FROM ct_position_res_d d,ct_position_res_m m
    WHERE position_no=v_position_no
        AND m.seg_segment_no='LP'
        AND m.seg_segment_no = d.seg_segment_no
        AND m.ct_position_res_m_seq = d.ct_position_res_m_seq
        AND (v_start_date BETWEEN start_date AND end_date
                OR v_end_date BETWEEN start_date AND end_date
                OR ( v_start_date < start_date AND v_end_date > end_date ) ) ;

     IF v_date_e IS NOT NULL  THEN
        v_insert_status:='F';
        v_insert_failure:='新增失敗,按確定前已被保留至'||to_char(v_date_e,'YYYY/MM/DD');      
     ELSE
        v_insert_status:='T';
        v_insert_failure:='新增成功,本保留位置需至契約部列印保留單經簽名確認後始生效';
     END IF;
   END IF;

   IF v_insert_status='T' THEN
       --check每位客戶每種商品僅能保留4個位置
       SELECT count(*) INTO v_count4
         FROM ct_position_res_m a,ct_position_res_d b
         wHERE a.seg_segment_no='LP'
             AND a.ct_position_res_m_seq=b.ct_position_res_m_seq
             AND a.CT_PC_LEND_D_SEQ=v_ct_pc_lend_d_seq
             AND SUBSTR(b.position_no,3,3)=SUBSTR(v_position_no,3,3);

       IF v_count4 >=4 THEN
           v_insert_status:='F';
           v_insert_failure:='新增失敗,每位客戶每種商品只能保留4個位置';      
       ELSE
          v_insert_status:='T';
       END IF;
   END IF;

   IF v_insert_status='T' THEN 
       BEGIN
              SELECT a.pc_no,a.lend_idno,c.sales_name,c.sales_tel,b.customer_name,b.customer_telephone,d.sales_name agent_name,d.sales_tel agent_telephone
                  INTO v_pc_no,v_lend_idno,v_lend_name,v_lend_tel,v_customer_name,v_customer_telphone,v_agent_name,v_agent_telphone  
                FROM CT_PC_LEND_M a,CT_PC_LEND_D b,CT_SALESMAN c,CT_SALESMAN d
               WHERE a.ct_pc_lend_m_seq=b.ct_pc_lend_m_seq
                   AND  b.ct_pc_lend_d_seq=v_ct_pc_lend_d_seq
                   AND  a.lend_idno=c.sales_idno
                   AND  b.sales_idno=d.sales_idno;
       EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                          v_lend_idno := NULL;
                          v_insert_status:='F';
                          v_insert_failure:='新增失敗,查無平板借用相關資料';    
       END;
   END IF;     


   IF v_insert_status = 'T' THEN

      --檢查選位保留主檔資料是否存在
      select count(*) into v_count1
         from ct_position_res_m
         where ct_pc_lend_d_seq = v_ct_pc_lend_d_seq;

     --設備借用歸還明細檔序號不存在選位保留主檔   
      IF v_count1 = 0 THEN

          IF v_lend_idno IS NOT NULL THEN
             --取選位保留主檔序號
             SELECT ct_position_res_m_seq.NEXTVAL
                         INTO v_ct_position_res_m_seq
                FROM DUAL;

             --取申請單號
             v_apply_no := F_CT_APPLYCODE('CTAF008','LP','CTA008',SYSDATE);

             --新增選位保留主檔 

                 INSERT INTO CT_POSITION_RES_M
                   (
                   CT_POSITION_RES_M_SEQ,
                   APPLY_NO,
                   SEG_SEGMENT_NO,
                   APPLY_DATE,
                   CUSTOMER_NAME,
                   AGENT_NAME,
                   CUSTOMER_TELPHONE,
                   AGENT_TELPHONE,
                   CREATE_DATE,
                   CREATE_BY,
                   CREATE_NAME,
                   CREATE_SITE,
                   CREATE_PROGRAM,
                   UPDATE_DATE,
                   UPDATE_BY,
                   UPDATE_NAME,
                   UPDATE_SITE,
                   UPDATE_PROGRAM, 
                   TIMES,
                   PC_NO,
                   LEND_IDNO,
                   LEND_NAME,
                   LEND_TEL,
                   CT_PC_LEND_D_SEQ,
                   CT_PC_LEND_M_SEQ  
                   )
                VALUES (
                   v_ct_position_res_m_seq,
                   v_apply_no,
                   'LP',
                   trunc(SYSDATE),
                   V_CUSTOMER_NAME, 
                   V_AGENT_NAME,
                   V_CUSTOMER_TELPHONE,
                   V_AGENT_TELPHONE,
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04',
                   '平板',
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04' ,
                   '平板',
                   v_times,
                   V_PC_NO,
                   V_LEND_IDNO,
                   V_LEND_NAME,
                   V_LEND_TEL,
                   v_ct_pc_lend_d_seq,
                   v_ct_pc_lend_m_seq   
                  );         

          END IF;
      ELSE
          --取已存在選位保留主檔序號及申請單號
          SELECT ct_position_res_m_seq,apply_no INTO v_ct_position_res_m_seq,v_apply_no
             FROM ct_position_res_m
         where ct_pc_lend_d_seq = v_ct_pc_lend_d_seq;
      END IF;   

      IF v_lend_idno IS NOT NULL THEN
          --取項次
          SELECT NVL(max(item_no),0)+1 INTO v_item_no
             FROM CT_POSITION_RES_D
           WHERE ct_position_res_m_seq = v_ct_position_res_m_seq;

           --取備註
           IF v_start_date = TRUNC(sysdate) AND v_times =2 THEN
               v_memo:='二次';
           END IF;

           IF v_start_date <> TRUNC(sysdate) AND v_times=1 THEN
               v_memo:='順位';
           END IF;

            IF v_start_date <> TRUNC(sysdate) AND v_times=2 THEN
                v_memo:='順位二次';
           END IF;

          --新增選位保留明細檔

            INSERT INTO CT_POSITION_RES_D
                  (CT_POSITION_RES_D_SEQ,
                   CT_POSITION_RES_M_SEQ,
                   APPLY_NO,
                   ITEM_NO,
                   SEG_SEGMENT_NO,
                   POSITION_NO,
                   START_DATE,
                   END_DATE,
                   MEMO,
                   CREATE_DATE,
                   CREATE_BY,
                   CREATE_NAME,
                   CREATE_SITE,
                   CREATE_PROGRAM,
                   UPDATE_DATE,
                   UPDATE_BY,
                   UPDATE_NAME,
                   UPDATE_SITE,
                   UPDATE_PROGRAM,
                   TIMES
                  )
             VALUES (
                   v_ct_position_res_d_seq,
                   v_ct_position_res_m_seq,
                   v_apply_no,
                   v_item_no,
                   'LP',
                   v_position_no,
                   v_start_date,
                   v_end_date,
                   v_memo,
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04',
                   '平板',
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04' ,
                   '平板',
                   v_times
                  );

      END IF;

      --新增選位保留明細暫存檔
      INSERT INTO CT_POSITION_RES_D_TEMP
                  (CT_POSITION_RES_D_SEQ,
                   CT_POSITION_RES_M_SEQ,
                   CT_PC_LEND_D_SEQ,
                   APPLY_NO,
                   ITEM_NO,
                   SEG_SEGMENT_NO,
                   POSITION_NO,
                   TIMES,
                   START_DATE,
                   END_DATE,
                   MEMO,
                   INSERT_STATUS,
                   INSERT_FAILURE,
                   IF_DELETE,
                   CREATE_DATE,
                   CREATE_BY,
                   CREATE_NAME,
                   CREATE_SITE,
                   CREATE_PROGRAM,
                   UPDATE_DATE,
                   UPDATE_BY,
                   UPDATE_NAME,
                   UPDATE_SITE,
                   UPDATE_PROGRAM
                  )
      VALUES (
                   v_ct_position_res_d_seq,
                   v_ct_position_res_m_seq,
                   v_ct_pc_lend_d_seq,
                   v_apply_no,
                   v_item_no,
                   'LP',
                   v_position_no,
                   v_times,
                   v_start_date,
                   v_end_date,
                   v_memo,
                   v_insert_status,
                   v_insert_failure,
                   'N',
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04',
                   '平板',
                   SYSDATE,
                   USER,
                   v_create_name,
                   '04' ,
                   '平板'
                  );              
   END IF;

  COMMIT;

  v_insert :=v_insert_status||' '||v_insert_failure;

EXCEPTION
  WHEN OTHERS THEN
       ROLLBACK;
       v_insert :='F 新增失敗,'||SQLERRM;
       --raise_application_error(-20001,SQLERRM);
END;
