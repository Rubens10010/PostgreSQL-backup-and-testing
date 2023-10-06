# Here you should put all sql sentences to be executed after db is created and before dump data is restored
CREATE EXTENSION pgcrypto;
CREATE TEXT SEARCH CONFIGURATION public.es ( COPY = pg_catalog.spanish );
