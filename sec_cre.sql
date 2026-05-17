
-- log seconds since "create datbase" 
-- useful during create-scripts, purely curiosity and speed measurement

-- trick for default
col themsg new_value 1
select null themsg from dual where 1=2; 

column sec_cre format 999,999,999 
column message format A50 

select ( sysdate - created ) * 24 * 3600 as sec_cre 
,   'sec_cre_msg=' || nvl ( '&1', 'dflt msg' )  as message
from v$database 
/

