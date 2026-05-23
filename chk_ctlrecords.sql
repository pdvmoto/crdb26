
column rec_type format A20
column rec_tot format 999
column rec_used format 9999

select type rec_type, records_total rec_tot, records_used rec_used
from v$controlfile_record_section
where 1=1
and ( 0=1
    or type like 'REDO%'
    or type like 'DATAFILE'
    or type like 'TABLESPACE'
    )
order by type; 
