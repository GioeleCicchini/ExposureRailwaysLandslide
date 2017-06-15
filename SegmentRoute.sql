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
  km           INTEGER;
  geome        GEOMETRY;
  line         RECORD;

BEGIN
  passo:=step;

  CREATE TABLE IF NOT EXISTS sotto_tratte_temp (
    id   SERIAL PRIMARY KEY,
    km   INTEGER,
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
    km:=(i * passo) / 1000;
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

      FOR line IN SELECT *
                  FROM (SELECT (ST_Dump(geome)).geom) AS a LOOP
        --RAISE NOTICE 'LINE%', line.geom;
        INSERT INTO sotto_tratte_temp (km, geom, name) VALUES (km, line.geom, route.name);
      END LOOP;

    ELSE
      INSERT INTO sotto_tratte_temp (km, geom, name) VALUES (km, geome, route.name);
    END IF;

    i:=i + 1;
  END LOOP;

END;
$$;
