create or REPLACE function "__contributionoflandslide"(idstazione integer, dr double precision) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    landslidezone RECORD;
    exposure FLOAT;
    Building RECORD;
    avg_area FLOAT;
    impfact FLOAT;
    landslide GEOMETRY;
    distance FLOAT;


  BEGIN
    CREATE TABLE IF NOT EXISTS exposure (
      id SERIAL PRIMARY KEY ,
			Building_gid INTEGER,
			exposure FLOAT,
      geom GEOMETRY,
      name VARCHAR
		);

    exposure := 0;
    SELECT * INTO Building FROM points WHERE gid = idstazione;
    SELECT avg(st_area(geom)) INTO avg_area FROM dataset;
    FOR landslidezone IN (SELECT * FROM landslidezones) LOOP

      IF (ST_Intersects(Building.geom, landslidezone.geom)) THEN
        exposure := exposure + (st_area(landslidezone.geom) * landslidezone.szk);
      ELSE

        distance:=st_distance(Building.geom, landslidezone.geom);
        SELECT geom INTO landslide FROM linearregression WHERE linearregression.id_zone = landslidezone.id;
        impfact := (st_area(st_intersection(st_buffer(Building.geom,dr),landslide)))/(st_area(st_buffer(Building.geom,dr)));
        exposure := (exposure + ((st_area(landslidezone.geom) * landslidezone.szk)*impfact));


      END IF;
    END LOOP;
    INSERT INTO exposure (Building_gid,name, geom,exposure) VALUES (Building.gid, Building.name,Building.geom,exposure/avg_area);

  END;
$$;
