CREATE TABLE CATEGORIEExercice (
                                   ID VARCHAR2(50) PRIMARY KEY,
                                   VAL VARCHAR2(255),
                                   DESCE VARCHAR2(255)
);

CREATE SEQUENCE SeqCategorieExercice
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE OR REPLACE FUNCTION getSeqCategorieExercice
RETURN NUMBER IS
    v_val NUMBER;
BEGIN
SELECT SeqCategorieExercice.NEXTVAL INTO v_val FROM DUAL;
RETURN v_val;
END;
/