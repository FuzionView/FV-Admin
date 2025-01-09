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
-- Name: fv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA fv;

CREATE EXTENSION postgis SCHEMA public;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: archive_deleted_tickets(); Type: FUNCTION; Schema: fv; Owner: -
--

CREATE FUNCTION fv.archive_deleted_tickets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
		insert into fv.archived_tickets(id,ticket_no,ticket_type,geom,publish_date,purge_date,is_latest,created_at) values((OLD).*);
		return old;
	end

$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: archived_tickets; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.archived_tickets (
    id bigint NOT NULL,
    dataset_id integer,
    ticket_no text NOT NULL,
    ticket_type text NOT NULL,
    geom public.geometry(MultiPolygon,6344) NOT NULL,
    publish_date timestamp with time zone NOT NULL,
    purge_date timestamp with time zone NOT NULL,
    is_latest boolean NOT NULL,
    created_at timestamp with time zone,
    archived_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ticket_type; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.ticket_type (
    id text NOT NULL,
    description text NOT NULL,
    color_mapserv text,
    color_hex text
);


--
-- Name: tickets; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.tickets (
    id bigint NOT NULL,
    dataset_id integer,
    ticket_no text NOT NULL,
    ticket_type text NOT NULL,
    geom public.geometry(MultiPolygon,6344) NOT NULL,
    publish_date timestamp with time zone NOT NULL,
    purge_date timestamp with time zone NOT NULL,
    is_latest boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: current_tickets; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.current_tickets AS
 SELECT tickets.id,
    tickets.dataset_id,
    tickets.ticket_no,
    tickets.ticket_type,
    ticket_type.description AS ticket_type_description,
    ticket_type.color_mapserv AS ticket_type_color_mapserv,
    ticket_type.color_hex AS ticket_type_color_hex,
    tickets.geom,
    public.st_buffer(tickets.geom, (((100.0 * (1200)::numeric) / (3937)::numeric))::double precision) AS buffered_geom,
    tickets.publish_date,
    tickets.purge_date,
    tickets.is_latest,
    tickets.created_at
   FROM (fv.tickets
     JOIN fv.ticket_type ON ((tickets.ticket_type = ticket_type.id)))
  WHERE (tickets.is_latest AND (now() >= tickets.publish_date) AND (now() <= tickets.purge_date));


--
-- Name: datasets; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.datasets (
    id integer NOT NULL,
    owner_id integer,
    name text,
    source_dataset text NOT NULL,
    source_sql text NOT NULL,
    source_co text[],
    source_srs text NOT NULL,
    cache_whole_dataset boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: datasets_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.datasets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.datasets_id_seq OWNED BY fv.datasets.id;


--
-- Name: feature_class; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.feature_class (
    id text NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    color_mapserv text,
    color_hex text
);


--
-- Name: feature_status; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.feature_status (
    id integer NOT NULL,
    status text NOT NULL
);


--
-- Name: features; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.features (
    id bigint NOT NULL,
    dataset_id integer,
    ticket_id integer,
    owner_fid text,
    feature_class text NOT NULL,
    geom public.geometry(Geometry,6344) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status_id integer,
    size double precision,
    depth double precision,
    accuracy_value double precision,
    description text
);


--
-- Name: features_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.features_id_seq OWNED BY fv.features.id;


--
-- Name: owners; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.owners (
    id integer NOT NULL,
    name text,
    service_area public.geometry(MultiPolygon,6344)
);


--
-- Name: map_features; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.map_features AS
 WITH f AS NOT MATERIALIZED (
         SELECT features.id,
            features.geom,
            owners.id AS owner_id,
            owners.name AS owner_name,
            datasets.name AS dataset_name,
            features.feature_class,
            feature_class.name AS feature_class_name,
            feature_class.code AS feature_class_code,
            feature_status.status,
            features.updated_at,
            features.size,
            features.depth,
            features.accuracy_value,
            features.description,
            feature_class.color_mapserv,
            feature_class.color_hex,
            features.ticket_id
           FROM fv.features,
            fv.feature_class,
            fv.datasets,
            fv.owners,
            fv.feature_status
          WHERE ((features.dataset_id = datasets.id) AND (datasets.owner_id = owners.id) AND (features.feature_class = feature_class.id) AND (features.status_id = feature_status.id))
        )
 SELECT f.id,
    f.geom,
    f.owner_id,
    f.owner_name,
    f.dataset_name,
    f.feature_class,
    f.feature_class_name,
    f.feature_class_code,
    f.status,
    f.updated_at,
    f.size,
    f.depth,
    f.accuracy_value,
    f.description,
    f.color_mapserv,
    f.color_hex,
    f.ticket_id,
    current_tickets.ticket_no,
    current_tickets.publish_date AS ticket_publish_date,
    current_tickets.purge_date AS ticket_purge_date
   FROM f,
    fv.current_tickets
  WHERE (f.ticket_id = current_tickets.id)
UNION ALL
 SELECT f.id,
    f.geom,
    f.owner_id,
    f.owner_name,
    f.dataset_name,
    f.feature_class,
    f.feature_class_name,
    f.feature_class_code,
    f.status,
    f.updated_at,
    f.size,
    f.depth,
    f.accuracy_value,
    f.description,
    f.color_mapserv,
    f.color_hex,
    f.ticket_id,
    NULL::character varying AS ticket_no,
    NULL::timestamp with time zone AS ticket_publish_date,
    NULL::timestamp with time zone AS ticket_purge_date
   FROM f
  WHERE (f.ticket_id IS NULL);


--
-- Name: owners_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.owners_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: owners_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.owners_id_seq OWNED BY fv.owners.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ticket_dataset_status; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.ticket_dataset_status (
    ticket_id integer,
    dataset_id integer NOT NULL,
    status text,
    feature_count integer,
    updated_at timestamp with time zone DEFAULT now(),
    attempt integer DEFAULT 1 NOT NULL,
    elapsed_time interval
);


--
-- Name: ticket_dataset_status_vw; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.ticket_dataset_status_vw AS
 SELECT o.id AS owner_id,
    d.id AS dataset_id,
    t.id AS ticket_id,
    o.name AS dataset_owner_name,
    d.name AS dataset_name,
    t.ticket_no,
    t.ticket_type,
    t.publish_date AS ticket_publish_date,
    t.purge_date AS ticket_purge_date,
    t.created_at AS ticket_created_at,
    tds.status,
    tds.feature_count,
    tds.attempt,
    tds.elapsed_time
   FROM fv.ticket_dataset_status tds,
    fv.current_tickets t,
    fv.datasets d,
    fv.owners o
  WHERE ((tds.ticket_id = t.id) AND (tds.dataset_id = d.id) AND (d.owner_id = o.id));


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.tickets_id_seq OWNED BY fv.tickets.id;


--
-- Name: users; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.users (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    email_address character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.users_id_seq OWNED BY fv.users.id;


--
-- Name: datasets id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets ALTER COLUMN id SET DEFAULT nextval('fv.datasets_id_seq'::regclass);


--
-- Name: features id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features ALTER COLUMN id SET DEFAULT nextval('fv.features_id_seq'::regclass);


--
-- Name: owners id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.owners ALTER COLUMN id SET DEFAULT nextval('fv.owners_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets ALTER COLUMN id SET DEFAULT nextval('fv.tickets_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.users ALTER COLUMN id SET DEFAULT nextval('fv.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: archived_tickets archived_tickets_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.archived_tickets
    ADD CONSTRAINT archived_tickets_pkey PRIMARY KEY (id);


--
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: feature_class feature_class_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.feature_class
    ADD CONSTRAINT feature_class_pkey PRIMARY KEY (id);


--
-- Name: feature_status feature_status_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.feature_status
    ADD CONSTRAINT feature_status_pkey PRIMARY KEY (id);


--
-- Name: features features_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- Name: owners owners_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.owners
    ADD CONSTRAINT owners_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: ticket_dataset_status tds_unique; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.ticket_dataset_status
    ADD CONSTRAINT tds_unique UNIQUE NULLS NOT DISTINCT (ticket_id, dataset_id);


--
-- Name: ticket_type ticket_type_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.ticket_type
    ADD CONSTRAINT ticket_type_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: features_gidx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX features_gidx ON fv.features USING gist (geom);


--
-- Name: index_users_on_owner_id; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX index_users_on_owner_id ON fv.users USING btree (owner_id);


--
-- Name: tickets_geom_buffered_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_geom_buffered_idx ON fv.tickets USING gist (public.st_buffer(geom, (((100.0 * (1200)::numeric) / (3937)::numeric))::double precision));


--
-- Name: tickets_geom_geom_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_geom_geom_idx ON fv.tickets USING gist (geom);


--
-- Name: tickets_ticket_no_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_ticket_no_idx ON fv.tickets USING btree (ticket_no);


--
-- Name: tickets archive_deleted; Type: TRIGGER; Schema: fv; Owner: -
--

CREATE TRIGGER archive_deleted BEFORE DELETE ON fv.tickets FOR EACH ROW EXECUTE FUNCTION fv.archive_deleted_tickets();


--
-- Name: datasets datasets_owner; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_owner FOREIGN KEY (owner_id) REFERENCES fv.owners(id) MATCH FULL;


--
-- Name: features feature_status; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT feature_status FOREIGN KEY (status_id) REFERENCES fv.feature_status(id) MATCH FULL;


--
-- Name: features features_datasets_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_datasets_fkey FOREIGN KEY (dataset_id) REFERENCES fv.datasets(id) ON DELETE CASCADE;


--
-- Name: features features_feature_class; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_feature_class FOREIGN KEY (feature_class) REFERENCES fv.feature_class(id);


--
-- Name: features features_tickets_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_tickets_fkey FOREIGN KEY (ticket_id) REFERENCES fv.tickets(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_3b42a03d2f; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.users
    ADD CONSTRAINT fk_rails_3b42a03d2f FOREIGN KEY (owner_id) REFERENCES fv.owners(id);


--
-- Name: ticket_dataset_status tds_datasets_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.ticket_dataset_status
    ADD CONSTRAINT tds_datasets_fkey FOREIGN KEY (dataset_id) REFERENCES fv.datasets(id) ON DELETE CASCADE;


--
-- Name: ticket_dataset_status tds_tickets_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.ticket_dataset_status
    ADD CONSTRAINT tds_tickets_fkey FOREIGN KEY (ticket_id) REFERENCES fv.tickets(id) ON DELETE CASCADE;


--
-- Name: tickets tickets_dataset_id_fk; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets
    ADD CONSTRAINT tickets_dataset_id_fk FOREIGN KEY (dataset_id) REFERENCES fv.datasets(id);


--
-- Name: tickets tickets_ticket_type_fk; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets
    ADD CONSTRAINT tickets_ticket_type_fk FOREIGN KEY (ticket_type) REFERENCES fv.ticket_type(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO fv,public;

INSERT INTO "schema_migrations" (version) VALUES
('20240414204740');
