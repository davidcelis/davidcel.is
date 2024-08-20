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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: webmention_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.webmention_status AS ENUM (
    'unprocessed',
    'verified',
    'failed'
);


--
-- Name: webmention_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.webmention_type AS ENUM (
    'reply',
    'like',
    'repost',
    'mention'
);


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
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


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
-- Name: media_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_attachments (
    id bigint DEFAULT public.snowflake_id() NOT NULL,
    post_id bigint NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    featured boolean DEFAULT false NOT NULL
);


--
-- Name: places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places (
    id bigint DEFAULT public.snowflake_id() NOT NULL,
    name character varying NOT NULL,
    category character varying,
    street character varying,
    city character varying,
    state character varying,
    state_code character varying,
    postal_code character varying,
    country character varying,
    country_code character varying,
    coordinates point,
    apple_maps_id character varying,
    apple_maps_url character varying,
    foursquare_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    check_ins_count integer DEFAULT 0 NOT NULL,
    last_checked_in_at timestamp(6) without time zone,
    CONSTRAINT chk_rails_d4c44e2131 CHECK (((coordinates IS NOT NULL) OR (apple_maps_id IS NULL)))
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
    updated_at timestamp(6) without time zone NOT NULL,
    place_id bigint,
    weather jsonb,
    coordinates point,
    link_data jsonb,
    hashtags character varying[] DEFAULT '{}'::character varying[] NOT NULL
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
-- Name: syndication_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.syndication_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id bigint NOT NULL,
    platform character varying NOT NULL,
    url character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: threads_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.threads_credentials (
    id bigint NOT NULL,
    access_token character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: threads_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.threads_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: threads_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.threads_credentials_id_seq OWNED BY public.threads_credentials.id;


--
-- Name: webmentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webmentions (
    id bigint DEFAULT public.snowflake_id() NOT NULL,
    post_id bigint,
    source character varying NOT NULL,
    target character varying NOT NULL,
    status public.webmention_status DEFAULT 'unprocessed'::public.webmention_status NOT NULL,
    html text,
    mf2 jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type public.webmention_type DEFAULT 'mention'::public.webmention_type
);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: threads_credentials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads_credentials ALTER COLUMN id SET DEFAULT nextval('public.threads_credentials_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: media_attachments media_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT media_attachments_pkey PRIMARY KEY (id);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


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
-- Name: syndication_links syndication_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.syndication_links
    ADD CONSTRAINT syndication_links_pkey PRIMARY KEY (id);


--
-- Name: threads_credentials threads_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads_credentials
    ADD CONSTRAINT threads_credentials_pkey PRIMARY KEY (id);


--
-- Name: webmentions webmentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webmentions
    ADD CONSTRAINT webmentions_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_media_attachments_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_attachments_on_post_id ON public.media_attachments USING btree (post_id);


--
-- Name: index_places_on_coordinates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_coordinates ON public.places USING gist (coordinates);


--
-- Name: index_posts_on_hashtags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_hashtags ON public.posts USING gin (hashtags);


--
-- Name: index_posts_on_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_place_id ON public.posts USING btree (place_id);


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
-- Name: index_syndication_links_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_syndication_links_on_post_id ON public.syndication_links USING btree (post_id);


--
-- Name: index_webmentions_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webmentions_on_post_id ON public.webmentions USING btree (post_id);


--
-- Name: index_webmentions_on_post_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webmentions_on_post_id_and_type ON public.webmentions USING btree (post_id, type) WHERE (status = 'verified'::public.webmention_status);


--
-- Name: index_webmentions_on_source_and_target; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webmentions_on_source_and_target ON public.webmentions USING btree (source, target);


--
-- Name: index_webmentions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webmentions_on_status ON public.webmentions USING btree (status);


--
-- Name: index_webmentions_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webmentions_on_type ON public.webmentions USING btree (type);


--
-- Name: syndication_links fk_rails_012a515b9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.syndication_links
    ADD CONSTRAINT fk_rails_012a515b9c FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: webmentions fk_rails_36ae3448c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webmentions
    ADD CONSTRAINT fk_rails_36ae3448c9 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: media_attachments fk_rails_6d5c9ccfc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT fk_rails_6d5c9ccfc8 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240820040304'),
('20240802003938'),
('20240619222332'),
('20240219210343'),
('20240219210215'),
('20231117172246'),
('20230917160025'),
('20230906013328'),
('20230904231250'),
('20230828044721'),
('20230225013704'),
('20230218162820'),
('20230215164722'),
('20230214012129'),
('20230205022836'),
('20230111000416'),
('20230111000240'),
('20221030014919'),
('20221030011319');

