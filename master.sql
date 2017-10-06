set termout on
set serveroutput on
set feedback off
set linesize 300
set trimout on
set trimspool on

/* Arguments */
DEFINE p_db_schema = &1
DEFINE p_db_owner = &2
DEFINE p_generator_filename = &3
DEFINE p_out_dir = &4
DEFINE p_ref_types = "&5"
DEFINE p_ref_names = "&6"
DEFINE p_types = "&7"
DEFINE p_gen_dir = &8

spool &p_gen_dir/&p_generator_filename

DECLARE
	l_filename VARCHAR2(100);
	l_schema VARCHAR2(30) := '&p_db_schema';
	l_owner VARCHAR2(30) := '&p_db_owner';
	l_out_dir VARCHAR(100) := '&p_out_dir';
	l_gen_dir VARCHAR(100) := '&p_gen_dir';
	l_types VARCHAR2(4000) := '&p_types';
	l_ref_types VARCHAR2(4000) := '&p_ref_types';
	l_ref_names VARCHAR2(4000) := '&p_ref_names';
BEGIN
FOR r IN (
	select distinct lower(name) as name from dba_dependencies where owner=l_owner 
	and type in (
		select regexp_substr(
			replace(replace(
				'&p_types'
				, q'[ ]', q'[,]'), q'[_]', q'[ ]'), 
			'[^,]+', 1, level) from dual
        connect by regexp_substr(
        	replace(replace('&p_types', q'[ ]', q'[,]'), q'[_]', q'[ ]'), 
        	'[^,]+', 1, level) is not null) 
	and referenced_type in (
		select regexp_substr(
			replace(replace('&p_ref_types', q'[ ]', q'[,]'), q'[_]', q'[ ]'), 
			'[^,]+', 1, level) from dual
        connect by regexp_substr(
        	replace(replace('&p_ref_types', q'[ ]', q'[,]'), q'[_]', q'[ ]'), 
        	'[^,]+', 1, level) is not null )
	order by name
)
	LOOP
	l_filename := r.name || '_ddl.sql';

		dbms_output.put_line('spool ' || l_out_dir || '/' || l_filename);
		dbms_output.put_line('BEGIN');
		dbms_output.put_line(
			q'[FOR r IN (select to_char(concat(replace(dbms_metadata.get_ddl(referenced_type, referenced_name, ']' 
			|| l_schema 
			|| q'['), chr(10), q'()'),q'(;)')) as ddl from dba_dependencies where owner=']' 
			|| l_owner 
			|| q'[' and type in ( select regexp_substr(replace(replace(']' 
			|| l_types
			|| q'[', q'( )', q'(,)'), q'(_)', q'( )'), '[^,]+', 1, level) from dual connect by regexp_substr(replace(replace(']'
			|| l_types
			|| q'[', q'( )', q'(,)'), q'(_)', q'( )'), '[^,]+', 1, level) is not null ) and referenced_name not in ( select regexp_substr(replace(']'
			|| '&p_ref_names'
			|| q'[', q'( )', q'(,)'), '[^,]+', 1, level) from dual connect by regexp_substr(replace(']'
			|| '&p_ref_names'
			|| q'[', q'( )', q'(,)'), '[^,]+', 1, level) is not null ) and referenced_type in ( select regexp_substr(replace(replace(']'
			|| '&p_ref_types'
			|| q'[', q'( )', q'(,)'), q'(_)', q'( )'), '[^,]+', 1, level) from dual connect by regexp_substr(replace(replace(']'
			|| '&p_ref_types'
			|| q'[', q'( )', q'(,)'), q'(_)', q'( )'), '[^,]+', 1, level) is not null )]');
		dbms_output.put_line(q'[and name = upper(']' || r.name || q'[')  order by 1) ]');
		dbms_output.put_line('LOOP');
		dbms_output.put_line(q'[dbms_output.put_line(r.ddl || chr(10) );]');
		dbms_output.put_line('END LOOP;');
		dbms_output.put_line('END;');
		dbms_output.put_line('/');
		dbms_output.put_line('spool off');
	END LOOP;
END;
/

spool off 

@&p_gen_dir/&p_generator_filename

exit