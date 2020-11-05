-- *****************************************************************************************************************
-- gpgen_sqlldr v1.0 
-- 
-- The gpgen_sqlldr is an sql script, created under GNU General Public License v3.0 to generate a .dat and .ctl
-- files for oracle utility sqlldr. Basically permits to export a table with the possibility to filter data.
-- 
-- Script requiered two parameters :
-- 
--       @gpgen_sqlldr.sql <TABLE NAME> <CONDITION>
--
-- ex.
--
--      @gpgen_sqlldr.sql users "1=1"
--
-- Will be created these files :
--
--      users.dat
--      users.ctl
--
-- To use with :
--
-- sqlldr userid={user}/{password} control=users.ctl log=users.log
-- 
-- *****************************************************************************************************************
--  History of changes
--  yyyy.mm.dd | Version | Author                | Changes
--  -----------+---------+-----------------------+-------------------------
--  2020.08.20 |  1.0    | Giovanni Palleschi    | First Release --
--
-- *****************************************************************************************************************

set echo off
set termout off
set feedback off
SET serverout ON size unlimited
set linesize 8192
SET TRIMSPOOL ON
set pagesize 0 
set verify off
set heading off

host echo ' Start Generacion sqlldr files for table &1 and condition &2'
host echo ' '
host echo ' '
host echo ' ......... Working ......... '
host echo ' '
host echo ' '

spool ./gen_dat.wrk

DECLARE

-- TO MODIFY

Separator  VARCHAR2(1) := CHR(30);
DateFormat VARCHAR2(20) := 'YYYYMMDD HH24MISS';

CURSOR UserTabColumns_cursor ( TableName IN VARCHAR2 )
IS
SELECT
COLUMN_ID,
COLUMN_NAME,
DATA_TYPE,
DATA_LENGTH
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = upper(TableName) ORDER BY COLUMN_ID;
recUserTabColumns UserTabColumns_cursor%ROWTYPE;

BEGIN
  DBMS_OUTPUT.PUT_LINE('###QUERY###SET LINESIZE 32767');
  DBMS_OUTPUT.PUT_LINE('###QUERY###SET TRIMSPOOL ON');
  DBMS_OUTPUT.PUT_LINE('###QUERY###SET PAGESIZE 0');
  DBMS_OUTPUT.PUT_LINE('###QUERY###SET HEADING OFF');
  DBMS_OUTPUT.PUT_LINE('###QUERY###begin');
  DBMS_OUTPUT.PUT_LINE('###QUERY###declare');
  DBMS_OUTPUT.PUT_LINE('###QUERY###TYPE numlist IS TABLE OF varchar2(8192) INDEX BY BINARY_INTEGER;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###ff numlist;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer varchar2(32767);');
  DBMS_OUTPUT.PUT_LINE('###QUERY###cursor cur is');
  DBMS_OUTPUT.PUT_LINE('###QUERY###SELECT ');
  DBMS_OUTPUT.PUT_LINE('###CTRL###LOAD DATA');
  -- #### YOU CAN MODIFY PATH FOR FILES .dat, .bad, .dsc
  DBMS_OUTPUT.PUT_LINE('###CTRL###INFILE ''./&1..dat''');
  DBMS_OUTPUT.PUT_LINE('###CTRL###BADFILE ''./&1..bad''');
  DBMS_OUTPUT.PUT_LINE('###CTRL###DISCARDFILE ''./&1..dsc''');
  -- #### YOU CAN MODIFY PATH FOR FILES .dat, .bad, .dsc
  DBMS_OUTPUT.PUT_LINE('###CTRL###TRUNCATE');
  DBMS_OUTPUT.PUT_LINE('###CTRL###INTO TABLE &1');
  DBMS_OUTPUT.PUT_LINE('###CTRL###FIELDS TERMINATED BY '''|| Separator || '''');
  DBMS_OUTPUT.PUT_LINE('###CTRL###TRAILING NULLCOLS');
  DBMS_OUTPUT.PUT_LINE('###CTRL###(');

  OPEN UserTabColumns_cursor('&1');
  LOOP
    FETCH UserTabColumns_cursor INTO recUserTabColumns;
    EXIT WHEN UserTabColumns_cursor%NOTFOUND;

    if recUserTabColumns.DATA_TYPE IN ('CLOB','BLOB') THEN
      CONTINUE;
    end if;

    IF recUserTabColumns.COLUMN_ID > 1 THEN
      DBMS_OUTPUT.PUT_LINE('###QUERY###||''' || Separator || '''||');
      DBMS_OUTPUT.PUT_LINE('###CTRL###,');
    END IF;

    IF recUserTabColumns.DATA_TYPE = 'DATE' THEN
      DBMS_OUTPUT.PUT_LINE('###QUERY###   to_char(' || recUserTabColumns.COLUMN_NAME || ',''' || DateFormat || ''')');
      DBMS_OUTPUT.PUT_LINE('###CTRL###' || recUserTabColumns.COLUMN_NAME || ' DATE ' || '"' || DateFormat ||'"');

    ELSIF recUserTabColumns.DATA_TYPE IN ('LONG RAW','LONG','RAW') THEN
      DBMS_OUTPUT.PUT_LINE('###CTRL###   ' || recUserTabColumns.COLUMN_NAME);
      DBMS_OUTPUT.PUT_LINE('###QUERY###   ''''');

    ELSIF recUserTabColumns.DATA_TYPE in ('VARCHAR2','NVARCHAR2','NCHAR','CHAR') THEN
      DBMS_OUTPUT.PUT_LINE('###QUERY###   REPLACE(' || recUserTabColumns.COLUMN_NAME || ',CHR(10),'' '')');
      DBMS_OUTPUT.PUT_LINE('###CTRL###   ' || recUserTabColumns.COLUMN_NAME || ' CHAR(' || recUserTabColumns.DATA_LENGTH || ')');

    ELSE
      DBMS_OUTPUT.PUT_LINE('###QUERY###   ' || recUserTabColumns.COLUMN_NAME);
      DBMS_OUTPUT.PUT_LINE('###CTRL###   ' || recUserTabColumns.COLUMN_NAME);
  	END IF;
  END LOOP;

  CLOSE UserTabColumns_cursor;
  IF LENGTH('&2') > 0 THEN
     DBMS_OUTPUT.PUT_LINE('###QUERY###FROM &1 WHERE &2;');
  ELSE
     DBMS_OUTPUT.PUT_LINE('###QUERY###FROM &1;');
  END IF;   
  DBMS_OUTPUT.PUT_LINE('###CTRL###)');
  DBMS_OUTPUT.PUT_LINE('###QUERY###begin');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := null;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###open cur;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###loop');
  DBMS_OUTPUT.PUT_LINE('###QUERY###fetch cur bulk collect into ff limit 10000;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###exit when cur%NOTFOUND;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###for i in ff.first..ff.last');
  DBMS_OUTPUT.PUT_LINE('###QUERY###loop');
  DBMS_OUTPUT.PUT_LINE('###QUERY###if (length(appo_buffer)+ length(ff(i)) + 1) >= 32767');
  DBMS_OUTPUT.PUT_LINE('###QUERY###then');
  DBMS_OUTPUT.PUT_LINE('###QUERY###dbms_output.put_line(substr(appo_buffer,1,length(appo_buffer)-1));');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := null;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end if;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := appo_buffer || ff(i) || chr(10);');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end loop;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end loop;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###if length(appo_buffer) > 0');
  DBMS_OUTPUT.PUT_LINE('###QUERY###then');
  DBMS_OUTPUT.PUT_LINE('###QUERY###dbms_output.put_line(substr(appo_buffer,1,length(appo_buffer)-1));');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end if;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := null;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###close cur;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###if (ff.first is not null) then');
  DBMS_OUTPUT.PUT_LINE('###QUERY###for i in ff.first..ff.last');
  DBMS_OUTPUT.PUT_LINE('###QUERY###loop');
  DBMS_OUTPUT.PUT_LINE('###QUERY###if (length(appo_buffer)+ length(ff(i)) + 1) >= 32767');
  DBMS_OUTPUT.PUT_LINE('###QUERY###then');
  DBMS_OUTPUT.PUT_LINE('###QUERY###dbms_output.put_line(substr(appo_buffer,1,length(appo_buffer)-1));');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := null;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end if;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###appo_buffer := appo_buffer || ff(i) || chr(10);');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end loop;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###if length(appo_buffer) > 0');
  DBMS_OUTPUT.PUT_LINE('###QUERY###then');
  DBMS_OUTPUT.PUT_LINE('###QUERY###dbms_output.put_line(substr(appo_buffer,1,length(appo_buffer)-1));');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end if;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end if;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###end;');
  DBMS_OUTPUT.PUT_LINE('###QUERY###/');

EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20001,'Oracle Error MSG: >' || SQLERRM(SQLCODE) || '<');
END;
/
spool off

host grep "###QUERY###" ./gen_dat.wrk > ./gen_dat.wrk2
host sed -e "s/###QUERY###//" -e "s/ *$//" ./gen_dat.wrk2 > ./gen_dat.sql
host grep "###CTRL###" ./gen_dat.wrk > ./gen_dat.wrk2
host sed -e "s/###CTRL###//" -e "s/ *$//" ./gen_dat.wrk2 > ./&1..ctl

spool ./gen_dat.wrk
@./gen_dat.sql
spool off

host sed -e "s/ *$//" ./gen_dat.wrk > ./&1..dat

host rm -fr ./gen_dat.wrk
host rm -fr ./gen_dat.wrk2
host rm -fr ./gen_dat.sql

host echo ' '
host echo ' '
host echo ' End Generacion sqlldr files for table &1 and codition &2 '
host echo ' '
host echo ' '

exit