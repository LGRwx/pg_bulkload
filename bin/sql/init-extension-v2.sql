SET client_min_messages = warning;
\set ECHO none
CREATE EXTENSION pg_bulkload;
DROP DATABASE IF EXISTS contrib_regression_sqlascii;
DROP DATABASE IF EXISTS contrib_regression_utf8;
\set ECHO all
RESET client_min_messages;

CREATE TABLE customer (
    c_id            int4 NOT NULL,
    c_d_id          int2 NOT NULL,
    c_w_id          int4 NOT NULL,
    c_first         varchar(16) NOT NULL,
    c_middle        char(2) NOT NULL,
    c_last          varchar(16) NOT NULL,
    c_street_1      varchar(20) NOT NULL,
    c_street_2      varchar(20) NOT NULL,
    c_city          varchar(20) NOT NULL,
    c_state         char(2) NOT NULL,
    c_zip           char(9) NOT NULL,
    c_phone         char(16) NOT NULL,
    c_since         timestamp NOT NULL,
    c_credit        char(2) NOT NULL,
    c_credit_lim    numeric(16,4) NOT NULL,
    c_discount      numeric(16,4) NOT NULL,
    c_balance       numeric(16,4) NOT NULL,
    c_ytd_payment   numeric(16,4) NOT NULL,
    c_payment_cnt   float4 NOT NULL,
    c_delivery_cnt  float8 NOT NULL,
    c_data          varchar(500) NOT NULL
) WITH (fillfactor=20);

ALTER TABLE customer ADD PRIMARY KEY (c_id, c_w_id, c_d_id);
CREATE INDEX idx_btree ON customer USING btree (c_d_id, c_last);
CREATE INDEX idx_btree_fn ON customer USING btree ((abs(c_w_id) + c_d_id));
CREATE INDEX idx_hash ON customer USING hash (c_d_id);
CREATE INDEX idx_hash_fn ON customer USING hash ((abs(c_w_id) + c_d_id));
---------------------------------------------------------------------------
-- load_check Import duplicate data
CREATE TABLE import_duplicate_data_test (
    id1 int, 
    id2 int, 
    id3 int, UNIQUE(id1, id2, id3)
);
---------------------------------------------------------------------------
-- load_check test
CREATE TABLE master (
    id int PRIMARY KEY,
   str text
);
CREATE TABLE target (
    id int PRIMARY KEY,
   str text CHECK(length(str) < 10) NOT NULL UNIQUE,
master int REFERENCES master (id)
);
CREATE TABLE target_like (
     id int,
    str text,
 master int
);

CREATE FUNCTION f_t_target() RETURNS trigger AS
$$
BEGIN
    INSERT INTO target_like VALUES(new.*);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_target
 AFTER INSERT
    ON target
   FOR EACH ROW
EXECUTE PROCEDURE f_t_target();

INSERT INTO master VALUES(1, 'aaa');

---------------------------------------------------------------------------
-- load_filter test
--------------------------------
-- error case
--------------------------------
-- VARIACIC function
CREATE FUNCTION variadic_f(int, VARIADIC text[]) RETURNS target AS
$$
    SELECT * FROM target;
$$ LANGUAGE SQL;

-- function overloading
CREATE FUNCTION overload_f() RETURNS target AS
$$
    SELECT * FROM target;
$$ LANGUAGE SQL;
CREATE FUNCTION overload_f(int4) RETURNS target AS
$$
    SELECT * FROM target;
$$ LANGUAGE SQL;

-- returns record using OUT paramator
CREATE FUNCTION outarg_f(OUT int4, OUT int4, OUT int4) RETURNS record AS
$$
    SELECT 1, 2, 3;
$$ LANGUAGE SQL;

-- returns setof function
CREATE FUNCTION setof_f() RETURNS SETOF target AS
$$
    SELECT * FROM target;
$$ LANGUAGE SQL;

-- returns data type mismatch
CREATE FUNCTION type_mismatch_f() RETURNS master AS
$$
    SELECT * FROM master LIMIT 1;
$$ LANGUAGE SQL;

-- returns record type mismatch
CREATE FUNCTION rec_mismatch_f() RETURNS record AS
$$
    SELECT 1, 'rec_mismatch_f', 1;
$$ LANGUAGE SQL;

--------------------------------
-- normal case
--------------------------------
-- no argument function
CREATE FUNCTION no_arg_f() RETURNS target AS
$$
    SELECT 1, 'call no_arg_f'::text, 3;
$$ LANGUAGE SQL;

---------------------------------------------------------------------------
-- load_encoding test
CREATE DATABASE contrib_regression_sqlascii TEMPLATE template0 ENCODING 'sql_ascii';
ALTER DATABASE contrib_regression_sqlascii SET lc_messages TO 'C';
ALTER DATABASE contrib_regression_sqlascii SET lc_monetary TO 'C';
ALTER DATABASE contrib_regression_sqlascii SET lc_numeric TO 'C';
ALTER DATABASE contrib_regression_sqlascii SET lc_time TO 'C';
ALTER DATABASE contrib_regression_sqlascii SET timezone_abbreviations TO 'Default';
CREATE DATABASE contrib_regression_utf8 TEMPLATE template0 ENCODING 'utf8';
ALTER DATABASE contrib_regression_utf8 SET lc_messages TO 'C';
ALTER DATABASE contrib_regression_utf8 SET lc_monetary TO 'C';
ALTER DATABASE contrib_regression_utf8 SET lc_numeric TO 'C';
ALTER DATABASE contrib_regression_utf8 SET lc_time TO 'C';
ALTER DATABASE contrib_regression_utf8 SET timezone_abbreviations TO 'Default';

\connect contrib_regression_sqlascii
CREATE TABLE target (id int, str text, master int);
CREATE INDEX i_target ON target (id);
\set ECHO none
CREATE EXTENSION pg_bulkload;
\set ECHO all

\connect contrib_regression_utf8
CREATE TABLE target (id int, str text, master int);
CREATE INDEX i_target ON target (id);
\set ECHO none
CREATE EXTENSION pg_bulkload;
\set ECHO all

\! rm -f results/*.log results/*.prs results/*.dup results/*.bin results/*.ctl
