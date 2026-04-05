-- original, and "good practice" would be...
-- ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
-- ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
-- ACCEPT pdbAdminPassword CHAR PROMPT 'Enter new password for PDBADMIN: ' HIDE

-- we are in a hurry, we dont like typos...

define      sysPassword=oracle
define   systemPassword=oracle
define pdbAdminPassword=oracle

-- prompt three pwds set
