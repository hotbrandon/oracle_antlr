create or replace Procedure         P_CT_CTAF074
   ( V_TYPE VARCHAR2,
     V_SEG_SEGMENT_NO VARCHAR2)
   IS
/*******************************************************************************
PURPOSE: <CTAF074>
USED BY: <CTAF074�ϥ�>
DESC   :  V_TYPE�ǤJ��=4 or 5
DATE        PERSON     VER    COMMENT
--------------------------------------------------------------------------------
2011/10/04  sandy     1.01   �p���ݨD�簣��������
2011/02/08  fong       1.00   new create  
*******************************************************************************/
BEGIN
  delete from gl_report_temp
  where RPT_ID='CTAF074';
  INSERT INTO GL_REPORT_TEMP(RPT_ID,ATTR1,ATTR2,ATTR3,ATTR4)
  SELECT 'CTAF074',
  --3.�yA�����禬�z�G�s�b�����s�@������,list�������ѬD��,�^�sct_epitaph_make_d���t�d�Hcheck_user�Χ�����finish_date(���`�B�s�@�Ȥ��K�B�t�X�i����)
  --4.�yB�ʪ��H�K�z�G�s�b�����禬������,list�������ѬD��,�^�sct_epitaph_make_d���t�d�Hcheck_user�B������finish_date�B�ܰ��~salary(���`)
         m.apply_no,
         m.apply_no1,
         --a.epitaph_user,
         a.content,
         a.seg_segment_no
from ct_epitaph_make_m m, ct_epitaph a 
where m.seg_segment_no=a.seg_segment_no
and m.seg_segment_no=V_SEG_SEGMENT_NO
and m.apply_no=a.apply_no
and m.apply_no1=a.apply_no1
and substr(m.apply_no1,1,4)<>'AA0E'  -- v1.01 add 2011.10.04
and m.normal<>'2'
and exists ( select 'x' from ct_epitaph_make_d where seg_segment_no=m.seg_segment_no and apply_no= m.apply_no and check_item in ('1','2','3') and check_user is not null)
and exists ( select 'x' from ct_epitaph_make_d where seg_segment_no=m.seg_segment_no and apply_no= m.apply_no and check_item='4'
             and( (check_user is null  and V_TYPE='4') or (check_user is not null  and V_TYPE='5') )
           )
and exists ( select 'x' from ct_epitaph_make_d where seg_segment_no=m.seg_segment_no and apply_no= m.apply_no and check_item='5' and check_user is null);
  
  

END;
