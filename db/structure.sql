SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: snowflake_id(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snowflake_id(now timestamp with time zone DEFAULT clock_timestamp()) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  epoch bigint := 1288834974657;
  seq_id bigint;
  ts bigint;

  -- Typically this would be an ID assigned to this database replica,
  -- but this is just a personal blog. We only have the one.
  worker_id int := 1;
  result bigint;
BEGIN
  SELECT NEXTVAL('public.snowflake_id_seq') INTO seq_id;
  SELECT FLOOR(EXTRACT(EPOCH FROM now) * 1000) INTO ts;

  result := (ts - epoch) << 22;
  result := result | (worker_id << 10);
  result := result | seq_id;

  return result;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint DEFAULT public.snowflake_id() NOT NULL,
    type character varying NOT NULL,
    title character varying,
    slug character varying NOT NULL,
    content text NOT NULL,
    html text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: snowflake_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snowflake_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 1024
    CACHE 1
    CYCLE;


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_posts_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_slug ON public.posts USING btree (slug);


--
-- Name: index_posts_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_type ON public.posts USING btree (type);


--
-- Name: index_posts_on_type_and_slug_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_posts_on_type_and_slug_and_created_at ON public.posts USING btree (type, slug, created_at);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20221030011319'),
('20221030014919');


