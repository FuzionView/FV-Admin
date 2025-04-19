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

-- CREATE EXTENSION postgis SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- CREATE SCHEMA public;
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
		insert into fv.archived_tickets
		values((OLD).*, now());
		return old;
	end
$$;


--
-- Name: FUNCTION archive_deleted_tickets(); Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON FUNCTION fv.archive_deleted_tickets() IS 'Trigger function to automatically move a ticket into the archived_tickets table when it is deleted from the tickets table.';


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
    dataset_id bigint,
    ticket_no text NOT NULL,
    ticket_type text NOT NULL,
    ticket_url text,
    geom public.geometry(MultiPolygon,6344) NOT NULL,
    publish_date timestamp with time zone NOT NULL,
    purge_date timestamp with time zone NOT NULL,
    is_latest boolean NOT NULL,
    created_at timestamp with time zone,
    archived_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE archived_tickets; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.archived_tickets IS 'Stores tickets after they are purged from the tickets table.';


--
-- Name: COLUMN archived_tickets.archived_at; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.archived_tickets.archived_at IS 'Timestamp of when the ticket was archived.';


--
-- Name: auth_type; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.auth_type (
    id text NOT NULL,
    name text NOT NULL
);


--
-- Name: TABLE auth_type; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.auth_type IS 'Domain list for credentials.auth_type.  Represents known auth types.';


--
-- Name: COLUMN auth_type.id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.auth_type.id IS 'Auth type identifier (needs to match code in update_feature_cache program)';


--
-- Name: COLUMN auth_type.name; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.auth_type.name IS 'Display name.';


--
-- Name: credentials; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.credentials (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    name text NOT NULL,
    auth_type text NOT NULL,
    auth_url text,
    auth_uid text NOT NULL,
    auth_key text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: TABLE credentials; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.credentials IS 'A set of credentials to connect to a service hosting datasets.';


--
-- Name: COLUMN credentials.owner_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.owner_id IS 'Owner of the credentials';


--
-- Name: COLUMN credentials.name; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.name IS 'Display name for these credentials';


--
-- Name: COLUMN credentials.auth_type; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.auth_type IS 'Auth type';


--
-- Name: COLUMN credentials.auth_url; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.auth_url IS 'Ticket endpoint';


--
-- Name: COLUMN credentials.auth_uid; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.auth_uid IS 'Username/Access Key/Client ID - store encrypted';


--
-- Name: COLUMN credentials.auth_key; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.credentials.auth_key IS 'Password/Secret Key/Client Secret - store encrypted';


--
-- Name: credentials_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: fv; Owner: -
--

ALTER SEQUENCE fv.credentials_id_seq OWNED BY fv.credentials.id;


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
-- Name: TABLE ticket_type; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.ticket_type IS 'Domain list for tickets.ticket_type.';


--
-- Name: COLUMN ticket_type.id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_type.id IS 'Code for the ticket type from the upstream ticketing system';


--
-- Name: COLUMN ticket_type.description; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_type.description IS 'Description for ticket type (presented in UI)';


--
-- Name: COLUMN ticket_type.color_mapserv; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_type.color_mapserv IS 'Display color for tickets of this type in integer RGB e.g. 128 120 0)';


--
-- Name: COLUMN ticket_type.color_hex; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_type.color_hex IS 'Display color for tickets of this type in HTML/CSS hex form e.g. #807800).  The update_colors cli tool will update this column from the color_mapserv column.';


--
-- Name: tickets; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.tickets (
    id bigint NOT NULL,
    dataset_id bigint,
    ticket_no text NOT NULL,
    ticket_type text NOT NULL,
    ticket_url text,
    geom public.geometry(MultiPolygon,6344) NOT NULL,
    publish_date timestamp with time zone NOT NULL,
    purge_date timestamp with time zone NOT NULL,
    is_latest boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tickets; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.tickets IS 'Represents a ticket from the upstream ticketing system.';


--
-- Name: COLUMN tickets.dataset_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.dataset_id IS 'NULL for normal upstream tickets.  If NOT NULL then this is a test ticket linked to this dataset id.  A test ticket will only fetch features for this dataset, will ignore the enabled flag, and will only show up in ticket lists for this dataset.';


--
-- Name: COLUMN tickets.ticket_no; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.ticket_no IS 'Upstream ticket identifier (stable between updates/revisions of the same ticket)';


--
-- Name: COLUMN tickets.ticket_type; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.ticket_type IS 'Type of ticket (ex. normal, emergency, ...).  The type is displayed to user and impacts display color.';


--
-- Name: COLUMN tickets.ticket_url; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.ticket_url IS 'URL of the upstream ticket';


--
-- Name: COLUMN tickets.geom; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.geom IS 'Geographic boundary of the ticket area.  Buffered and used to query datasets for features applicable to the ticket.';


--
-- Name: COLUMN tickets.publish_date; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.publish_date IS 'FuzionView will not show a ticket before this timestamp.';


--
-- Name: COLUMN tickets.purge_date; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.purge_date IS 'FuzionView will not show a ticket after this timestamp.  It will also archive the ticket and delete any features associated with this ticket shortly after this timestamp.';


--
-- Name: COLUMN tickets.is_latest; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.is_latest IS 'Internal flag marking a row that contains the latest version of the ticket.  (A row can be an older version if a ticket was updated upstream.  A new ticket row is created in that case to log the change and force the feature cache to be refreshed.';


--
-- Name: COLUMN tickets.created_at; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.tickets.created_at IS 'Timestamp when ticket was loaded into FuzionView. Optionally: timestamp when upstream ticket was created/edited?';


--
-- Name: current_tickets; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.current_tickets AS
 SELECT tickets.id,
    tickets.dataset_id,
    tickets.ticket_no,
    tickets.ticket_type,
    tickets.ticket_url,
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
-- Name: VIEW current_tickets; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON VIEW fv.current_tickets IS 'Tickets that are currently active.  Also denormalizes as needed for map display.';


--
-- Name: datasets; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.datasets (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    credential_id bigint,
    name text NOT NULL,
    source_dataset text NOT NULL,
    source_sql text NOT NULL,
    source_co text[],
    source_srs text NOT NULL,
    cache_whole_dataset boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE datasets; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.datasets IS 'Configuration of source datasets to query to pull features into FuzionView';


--
-- Name: COLUMN datasets.name; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.name IS 'Name of the dataset';


--
-- Name: COLUMN datasets.source_dataset; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.source_dataset IS 'OGR connection string for connecting to the dataset.';


--
-- Name: COLUMN datasets.source_sql; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.source_sql IS 'OGR SQLite SQL statement to query the dataset and transform it into the FuzionView features schema.';


--
-- Name: COLUMN datasets.source_co; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.source_co IS 'OGR configuration options to apply for connecting to the dataset.';


--
-- Name: COLUMN datasets.source_srs; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.source_srs IS 'OGR spatial-reference-system that will be used to query the dataset and that the dataset''s features are returned in.  Can be any OGR compatible SRS format such as EPSG:4326 or a full WKT2 SRS.';


--
-- Name: COLUMN datasets.cache_whole_dataset; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.cache_whole_dataset IS 'If true FuzionView will cache the entire dataset at once (saving the need to query the dataset for each ticket boundary).';


--
-- Name: COLUMN datasets.enabled; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.datasets.enabled IS 'If true FuzionView will query this dataset for features, otherwise it is ignored for regular tickets.  (The dataset will still be queried for test tickets created from the admin interface).';


--
-- Name: datasets_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.datasets_id_seq
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
-- Name: feature_accuracy_class; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.feature_accuracy_class (
    id text NOT NULL,
    name text NOT NULL
);


--
-- Name: TABLE feature_accuracy_class; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.feature_accuracy_class IS 'Domain list for features.accuracy_class.  Represents the expected accuracy of a feature as reported from the data owner.';


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
-- Name: TABLE feature_class; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.feature_class IS 'Domain list for featuress.feature_class.  Feature class is how FV groups features for display.  Typically configured as APWA color codes.';


--
-- Name: COLUMN feature_class.id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.feature_class.id IS 'Code for the feature class.';


--
-- Name: COLUMN feature_class.name; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.feature_class.name IS 'Display name for this feature class.';


--
-- Name: COLUMN feature_class.code; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.feature_class.code IS 'Short (ex. 3 letter) abbreviation for feature class for map labeling.';


--
-- Name: COLUMN feature_class.color_mapserv; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.feature_class.color_mapserv IS 'Display color in integer RGB e.g. 128 120 0)';


--
-- Name: COLUMN feature_class.color_hex; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.feature_class.color_hex IS 'Display color in HTML/CSS hex form e.g. #807800).  The update_colors cli tool will update this column from the color_mapserv column.';


--
-- Name: feature_status; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.feature_status (
    id text NOT NULL,
    name text NOT NULL
);


--
-- Name: TABLE feature_status; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.feature_status IS 'Domain list for features.status.  Represents the status of the asset reprensented by this feature as reported from the data owner (ex. active or abandoned).';


--
-- Name: features; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.features (
    id bigint NOT NULL,
    dataset_id bigint NOT NULL,
    ticket_id bigint,
    provider_fid text,
    feature_class text NOT NULL,
    geom public.geometry(Geometry,6344) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    status text,
    size double precision,
    depth double precision,
    accuracy_class text,
    description text
);


--
-- Name: TABLE features; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.features IS 'Cache of features (ex. points, lines, polygons, ...) from upstream datasets optionally associated with tickets.';


--
-- Name: COLUMN features.dataset_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.dataset_id IS 'Dataset this feature came from.';


--
-- Name: COLUMN features.ticket_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.ticket_id IS 'Ticket this feature is associated with (or NULL if this is a dataset where cache_whole_dataset is true)';


--
-- Name: COLUMN features.provider_fid; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.provider_fid IS 'From upstream dataset: represents a unique id to tie this row back to the original record from the dataset';


--
-- Name: COLUMN features.feature_class; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.feature_class IS 'From upstream dataset: feature_class id this feature belongs to.';


--
-- Name: COLUMN features.geom; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.geom IS 'From upstream dataset: Geometry (any type supported by PostGIS) of the feature.';


--
-- Name: COLUMN features.updated_at; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.updated_at IS 'Last time this feature was updated.';


--
-- Name: COLUMN features.status; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.status IS 'From upstream dataset: Feature status';


--
-- Name: COLUMN features.size; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.size IS 'From upstream dataset: Feature size';


--
-- Name: COLUMN features.depth; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.depth IS 'From upstream dataset: Feature depth';


--
-- Name: COLUMN features.accuracy_class; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.accuracy_class IS 'From upstream dataset: Accuracy class';


--
-- Name: COLUMN features.description; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.features.description IS 'From upstream dataset: Human readable description of the feature.';


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
    id bigint NOT NULL,
    name text NOT NULL,
    service_area public.geometry(MultiPolygon,6344)
);


--
-- Name: TABLE owners; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.owners IS 'Grouping of source datasets by data owners (organizations)';


--
-- Name: COLUMN owners.name; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.owners.name IS 'Name of entity that owns datasets';


--
-- Name: COLUMN owners.service_area; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.owners.service_area IS 'Optional boundary outside of which it is known there are no features for this owner.  Avoids querying this owner''s datasets for tickets outside of this area.';


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
            features.status,
            feature_status.name AS status_name,
            features.updated_at,
            features.size,
            features.depth,
            features.accuracy_class,
            features.description,
            feature_class.color_mapserv,
            feature_class.color_hex,
            features.ticket_id,
            features.provider_fid
           FROM fv.features,
            fv.feature_class,
            fv.datasets,
            fv.owners,
            fv.feature_status
          WHERE ((features.dataset_id = datasets.id) AND (datasets.owner_id = owners.id) AND (features.feature_class = feature_class.id) AND (features.status = feature_status.id))
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
    f.status_name,
    f.updated_at,
    f.size,
    f.depth,
    f.accuracy_class,
    f.description,
    f.color_mapserv,
    f.color_hex,
    f.ticket_id,
    f.provider_fid,
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
    f.status_name,
    f.updated_at,
    f.size,
    f.depth,
    f.accuracy_class,
    f.description,
    f.color_mapserv,
    f.color_hex,
    f.ticket_id,
    f.provider_fid,
    NULL::character varying AS ticket_no,
    NULL::timestamp with time zone AS ticket_publish_date,
    NULL::timestamp with time zone AS ticket_purge_date
   FROM f
  WHERE (f.ticket_id IS NULL);


--
-- Name: VIEW map_features; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON VIEW fv.map_features IS 'Denormalizes features for map display';


--
-- Name: owners_id_seq; Type: SEQUENCE; Schema: fv; Owner: -
--

CREATE SEQUENCE fv.owners_id_seq
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
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.schema_migrations IS 'Keep track of which schema migrations have been applied.';


--
-- Name: ticket_dataset_status; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.ticket_dataset_status (
    ticket_id bigint,
    dataset_id bigint NOT NULL,
    status text,
    feature_count integer,
    updated_at timestamp with time zone DEFAULT now(),
    attempt integer DEFAULT 1 NOT NULL,
    elapsed_time interval
);


--
-- Name: TABLE ticket_dataset_status; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.ticket_dataset_status IS 'Keeps track of attempts of FuzionView to query a dataset, optionally on behalf of a ticket.';


--
-- Name: COLUMN ticket_dataset_status.ticket_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.ticket_id IS 'ticket_id associated with this attempt (if not cache_whole_dataset).';


--
-- Name: COLUMN ticket_dataset_status.dataset_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.dataset_id IS 'dataset_id associated with this attempt.';


--
-- Name: COLUMN ticket_dataset_status.status; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.status IS 'Status message resulting from attempt.  Can be multiline separated by newlines.  Either SUCCESS or gives information about why an attempt failed.';


--
-- Name: COLUMN ticket_dataset_status.feature_count; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.feature_count IS 'Number of features returned by this attempt (if successful).';


--
-- Name: COLUMN ticket_dataset_status.updated_at; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.updated_at IS 'Timestamp of when this attempt finished.';


--
-- Name: COLUMN ticket_dataset_status.attempt; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.attempt IS 'Number of attempts to query this dataset_id+ticket_id.  Used to implement a backoff-rate in case the query failed.';


--
-- Name: COLUMN ticket_dataset_status.elapsed_time; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.ticket_dataset_status.elapsed_time IS 'Runtime of the attempt.  Useful to troubleshoot datasets that might be unusually slow.';


--
-- Name: ticket_dataset_retry; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.ticket_dataset_retry AS
 SELECT ticket_dataset_status.ticket_id,
    ticket_dataset_status.dataset_id,
    ticket_dataset_status.status,
    ticket_dataset_status.updated_at,
    ticket_dataset_status.attempt,
    l1.success,
    l3.retry_after,
    l3.retry_now
   FROM fv.ticket_dataset_status,
    LATERAL ( SELECT (ticket_dataset_status.status ~~ 'SUCCESS:%'::text) AS success,
            (ticket_dataset_status.updated_at + '7 days'::interval) AS retry_success_after,
            (ticket_dataset_status.updated_at + ('00:05:00'::interval * ((2)::double precision ^ (LEAST(ticket_dataset_status.attempt, 8))::double precision))) AS retry_failed_after) l1(success, retry_success_after, retry_failed_after),
    LATERAL ( SELECT (now() > l1.retry_success_after) AS "?column?",
            (now() > l1.retry_failed_after) AS "?column?") l2(retry_success, retry_failed),
    LATERAL ( SELECT
                CASE
                    WHEN l1.success THEN l1.retry_success_after
                    ELSE l1.retry_failed_after
                END AS retry_after,
                CASE
                    WHEN l1.success THEN l2.retry_success
                    ELSE l2.retry_failed
                END AS retry_now) l3(retry_after, retry_now);


--
-- Name: VIEW ticket_dataset_retry; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON VIEW fv.ticket_dataset_retry IS 'Implements the logic for when a query for features for a dataset_id+ticket_id should be attempted next.';


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
    t.ticket_url,
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
-- Name: VIEW ticket_dataset_status_vw; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON VIEW fv.ticket_dataset_status_vw IS 'Denormalizes ticket_dataset_status for API';


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
-- Name: update_feature_cache; Type: VIEW; Schema: fv; Owner: -
--

CREATE VIEW fv.update_feature_cache AS
 SELECT datasets.id AS dataset_id,
    datasets.name AS dataset_name,
    datasets.source_dataset,
    datasets.source_sql,
    datasets.source_co,
    datasets.source_srs,
    NULL::bigint AS ticket_id,
    NULL::text AS ticket_no,
    NULL::public.geometry AS buffered_geom,
    NULL::boolean AS in_service_area,
    tds.attempt,
    tds.retry_after,
    (tds.retry_now OR (tds.retry_now IS NULL)) AS update_now,
    owners.id AS owner_id,
    datasets.credential_id
   FROM ((fv.owners
     JOIN fv.datasets ON ((owners.id = datasets.owner_id)))
     LEFT JOIN fv.ticket_dataset_retry tds ON (((tds.dataset_id = datasets.id) AND (tds.ticket_id IS NULL))))
  WHERE (datasets.enabled AND datasets.cache_whole_dataset)
UNION ALL
 SELECT datasets.id AS dataset_id,
    datasets.name AS dataset_name,
    datasets.source_dataset,
    datasets.source_sql,
    datasets.source_co,
    datasets.source_srs,
    tickets.id AS ticket_id,
    tickets.ticket_no,
    tickets.buffered_geom,
    l1.in_service_area,
    tds.attempt,
    tds.retry_after,
    (tds.retry_now OR (tds.retry_now IS NULL)) AS update_now,
    owners.id AS owner_id,
    datasets.credential_id
   FROM (((fv.owners
     JOIN fv.datasets ON ((owners.id = datasets.owner_id)))
     CROSS JOIN fv.current_tickets tickets)
     LEFT JOIN fv.ticket_dataset_retry tds ON (((tds.dataset_id = datasets.id) AND (tds.ticket_id = tickets.id)))),
    LATERAL ( SELECT public.st_intersects(owners.service_area, tickets.buffered_geom) AS st_intersects) l1(in_service_area)
  WHERE (datasets.enabled AND (NOT datasets.cache_whole_dataset) AND (tickets.dataset_id IS NULL) AND ((owners.service_area IS NULL) OR l1.in_service_area))
UNION ALL
 SELECT datasets.id AS dataset_id,
    datasets.name AS dataset_name,
    datasets.source_dataset,
    datasets.source_sql,
    datasets.source_co,
    datasets.source_srs,
    tickets.id AS ticket_id,
    tickets.ticket_no,
    tickets.buffered_geom,
    l1.in_service_area,
    tds.attempt,
    tds.retry_after,
    (tds.retry_now OR (tds.retry_now IS NULL)) AS update_now,
    owners.id AS owner_id,
    datasets.credential_id
   FROM (((fv.owners
     JOIN fv.datasets ON ((owners.id = datasets.owner_id)))
     CROSS JOIN fv.current_tickets tickets)
     LEFT JOIN fv.ticket_dataset_retry tds ON (((tds.dataset_id = datasets.id) AND (tds.ticket_id = tickets.id)))),
    LATERAL ( SELECT public.st_intersects(owners.service_area, tickets.buffered_geom) AS st_intersects) l1(in_service_area)
  WHERE (tickets.dataset_id = datasets.id);


--
-- Name: VIEW update_feature_cache; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON VIEW fv.update_feature_cache IS 'Used by update_feature_cache program to determine which datasets (and for which tickets) need to be loaded into the features cache.';


--
-- Name: users; Type: TABLE; Schema: fv; Owner: -
--

CREATE TABLE fv.users (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    email_address text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: TABLE users; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON TABLE fv.users IS 'Assocates a user accounts (people) with the rights to manage a (data) owners.';


--
-- Name: COLUMN users.owner_id; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.users.owner_id IS 'ID of owner that can be managed by this user.';


--
-- Name: COLUMN users.email_address; Type: COMMENT; Schema: fv; Owner: -
--

COMMENT ON COLUMN fv.users.email_address IS 'User identifier.';


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
-- Name: credentials id; Type: DEFAULT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.credentials ALTER COLUMN id SET DEFAULT nextval('fv.credentials_id_seq'::regclass);


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
-- Name: auth_type auth_type_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.auth_type
    ADD CONSTRAINT auth_type_pkey PRIMARY KEY (id);


--
-- Name: credentials credentials_id_owner_id_key; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.credentials
    ADD CONSTRAINT credentials_id_owner_id_key UNIQUE (id, owner_id);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (id);


--
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: feature_accuracy_class feature_accuracy_class_pkey; Type: CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.feature_accuracy_class
    ADD CONSTRAINT feature_accuracy_class_pkey PRIMARY KEY (id);


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
-- Name: archived_tickets_geom_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX archived_tickets_geom_idx ON fv.archived_tickets USING gist (geom);


--
-- Name: archived_tickets_ticket_no_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX archived_tickets_ticket_no_idx ON fv.archived_tickets USING btree (ticket_no);


--
-- Name: features_gidx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX features_gidx ON fv.features USING gist (geom);


--
-- Name: tickets_geom_buffered_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_geom_buffered_idx ON fv.tickets USING gist (public.st_buffer(geom, (((100.0 * (1200)::numeric) / (3937)::numeric))::double precision));


--
-- Name: tickets_geom_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_geom_idx ON fv.tickets USING gist (geom);


--
-- Name: tickets_ticket_no_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX tickets_ticket_no_idx ON fv.tickets USING btree (ticket_no);


--
-- Name: users_owner_id_idx; Type: INDEX; Schema: fv; Owner: -
--

CREATE INDEX users_owner_id_idx ON fv.users USING btree (owner_id);


--
-- Name: tickets archive_deleted; Type: TRIGGER; Schema: fv; Owner: -
--

CREATE TRIGGER archive_deleted BEFORE DELETE ON fv.tickets FOR EACH ROW EXECUTE FUNCTION fv.archive_deleted_tickets();


--
-- Name: credentials credentials_auth_type_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.credentials
    ADD CONSTRAINT credentials_auth_type_fkey FOREIGN KEY (auth_type) REFERENCES fv.auth_type(id);


--
-- Name: credentials credentials_owner_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.credentials
    ADD CONSTRAINT credentials_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES fv.owners(id);


--
-- Name: datasets datasets_credential_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_credential_id_fkey FOREIGN KEY (credential_id) REFERENCES fv.credentials(id);


--
-- Name: datasets datasets_credential_id_owner_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_credential_id_owner_id_fkey FOREIGN KEY (credential_id, owner_id) REFERENCES fv.credentials(id, owner_id);


--
-- Name: datasets datasets_owner_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.datasets
    ADD CONSTRAINT datasets_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES fv.owners(id);


--
-- Name: features features_accuracy_class_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_accuracy_class_fkey FOREIGN KEY (accuracy_class) REFERENCES fv.feature_accuracy_class(id);


--
-- Name: features features_dataset_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES fv.datasets(id) ON DELETE CASCADE;


--
-- Name: features features_feature_class_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_feature_class_fkey FOREIGN KEY (feature_class) REFERENCES fv.feature_class(id);


--
-- Name: features features_status_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_status_fkey FOREIGN KEY (status) REFERENCES fv.feature_status(id);


--
-- Name: features features_ticket_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.features
    ADD CONSTRAINT features_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES fv.tickets(id) ON DELETE CASCADE;


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
-- Name: tickets tickets_dataset_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets
    ADD CONSTRAINT tickets_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES fv.datasets(id);


--
-- Name: tickets tickets_ticket_type_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.tickets
    ADD CONSTRAINT tickets_ticket_type_fkey FOREIGN KEY (ticket_type) REFERENCES fv.ticket_type(id);


--
-- Name: users users_owner_id_fkey; Type: FK CONSTRAINT; Schema: fv; Owner: -
--

ALTER TABLE ONLY fv.users
    ADD CONSTRAINT users_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES fv.owners(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO fv,public;

INSERT INTO "schema_migrations" (version) VALUES
('20250326000000'),
('20250112022845'),
('20241206111420'),
('20240414204740');

