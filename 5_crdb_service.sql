

-- create a service freepdb1 to mimick behaviour..

define SRVC=&1 

BEGIN
  DBMS_SERVICE.CREATE_SERVICE(
    service_name => '&&SRVC',
    network_name => '&&SRVC'
  );
END;
/

BEGIN
  DBMS_SERVICE.START_SERVICE( service_name => '&&SRVC'
  );
END;
/
SELECT name FROM v$services WHERE name = '&&SRVC';

ALTER SYSTEM SET service_names = '&&SRVC' SCOPE=BOTH;

-- probably need this too
alter system register ; 

