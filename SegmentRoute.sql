create or REPLACE function "__SegmentRoute"(id_route integer, step integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
  route        RECORD;
  route_length FLOAT;
  divisore     INTEGER;
  passo        INTEGER;
  i            INTEGER;
  sts          FLOAT;
  ends         FLOAT;
  km           real;
  geome        GEOMETRY;
  line         RECORD;

BEGIN
  passo:=step;

  CREATE TABLE IF NOT EXISTS route_segments (
    gid   SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES railway_routes(gid),
    km   real,
    geom GEOMETRY
  );

  CREATE TABLE IF NOT EXISTS current_route_segments (
    gid   SERIAL PRIMARY KEY,
    km   real,
    geom GEOMETRY,
    name VARCHAR
  );

  SELECT
    id,
    st_linemerge(geom) AS geom,
    railway_routes.name
  INTO route
  FROM railway_routes
  WHERE id = id_route;

  route_length:=st_length(route.geom);
  divisore:=route_length / passo;

  i:=0;
  WHILE i < divisore LOOP
    km:=(i * passo) / 1000::real;
    RAISE NOTICE 'kilometro %',km;
    --RAISE NOTICE 'length%', route_length;
    sts:=(i * passo) / route_length;
    ends:=((i + 1) * passo) / route_length;

    IF (ends >= 1)
    THEN
      ends:=1;
    END IF;
    --RAISE NOTICE 'segmentSTART%', sts;
    --RAISE NOTICE 'segmentEND%', ends;
    geome:=st_linemerge(ST_LineSubString(route.geom, sts, ends));

    IF st_geometrytype(geome) = 'ST_MultiLineString'
    THEN
      --IF THE MERGED GEOMETRY IS A MULTILINESTRING WE MUST DUMP IT TO OBTAIN LINESTRINGS
      FOR line IN SELECT *
                  FROM (SELECT (ST_Dump(geome)).geom) AS a LOOP
        --RAISE NOTICE 'LINE%', line.geom;
        INSERT INTO current_route_segments (km, geom, name) VALUES (km, line.geom, route.name);
        INSERT INTO route_segments (km,route_id,geom) VALUES (km,route.id,line.geom);
      END LOOP;

    ELSE
      INSERT INTO current_route_segments (km, geom, name) VALUES (km, geome, route.name);
      INSERT INTO route_segments (km,route_id,geom) VALUES (km,route.id,geome);
    END IF;

    i:=i + 1;
  END LOOP;

END;
$$;
