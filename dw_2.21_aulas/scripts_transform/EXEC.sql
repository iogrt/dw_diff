-- CREATES AND POPULATES THE DSA STRUCTURES
@@CREATE_data_tables
@@CREATE_lookup_tables

-- CREATES THE TRANSFORMATION ERROR LOGGER (TEL) STRUCTURES
@@CREATE_external_tables
@@CREATE_tel_tables
@@CREATE_sequences
@@CREATE_triggers
@@CREATE_views

@@CREATE_package_pck_transform
@@INSERT_data.sql

COMMIT;
