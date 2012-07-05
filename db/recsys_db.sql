CREATE TABLE clusters (
    id integer,
    centerid integer,
    size integer
);

CREATE TABLE learning_objects (
    id integer,
    clusterid integer,
    type character varying(255),
    position integer
);

CREATE TABLE users (
    id integer,
    clusterid integer,
    position integer
);

INSERT INTO clusters (id, centerid, size) VALUES (0, 1, 1);

INSERT INTO users (id, clusterid, position) VALUES (1, 0, 1);

