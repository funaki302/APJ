CREATE  SEQUENCE SEQ_FEMELLE
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQFEMELLE
RETURN NUMBER IS
    v_val NUMBER;
BEGIN
    SELECT SEQ_FEMELLE.NEXTVAL INTO v_val FROM DUAL;
    RETURN v_val;
END;
/

CREATE SEQUENCE SEQ_MALE
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQMALE
RETURN NUMBER IS
    v_val NUMBER;
BEGIN
    SELECT SEQ_MALE.NEXTVAL INTO v_val FROM DUAL;
    RETURN v_val;
END;
/

ALTER TABLE TRIAGEBATIMENTPARQUETDETAIL MODIFY (ID VARCHAR2(250));

CREATE OR REPLACE FUNCTION getseq_triagebatparquetdetail (
    p_idsexe IN VARCHAR2
)
RETURN VARCHAR2
IS
    v_numero   NUMBER;         
    v_libelle  VARCHAR2(255);
    v_sexe     VARCHAR2(1);    
    v_val      NUMBER;          
BEGIN
    SELECT seq_triagebatparquetdetail.NEXTVAL INTO v_numero FROM DUAL;

    BEGIN
        SELECT UPPER(TRIM(VAL)) INTO v_libelle
          FROM SEXE
         WHERE ID = TRIM(p_idsexe)
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_libelle := NULL;
    END;

    v_sexe := CASE
        WHEN v_libelle LIKE 'F%' THEN 'V'
        WHEN v_libelle LIKE 'M%' THEN 'L'
        WHEN TRIM(p_idsexe) = '1' THEN 'L'   
        WHEN TRIM(p_idsexe) = '0' THEN 'V'
        ELSE 'X'
    END;

    IF v_sexe = 'L' THEN
        SELECT SEQ_MALE.NEXTVAL INTO v_val FROM DUAL;
    ELSIF v_sexe = 'V' THEN
        SELECT SEQ_FEMELLE.NEXTVAL INTO v_val FROM DUAL;
    ELSE
        v_val := v_numero;
    END IF;

    RETURN '-' || v_sexe || '-' || TO_CHAR(v_val) || '-' || TO_CHAR(v_numero);
END;
/