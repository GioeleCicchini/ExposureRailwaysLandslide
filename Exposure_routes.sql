create or REPLACE function "__exposure_routes"(id_route integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    point RECORD;
    route RECORD;
    points INTEGER;
    iterator INTEGER;
    divisor INTEGER;
    lastexposure RECORD;

  BEGIN
      DROP TABLE IF EXISTS route_points;
      DROP TABLE IF EXISTS sotto_tratte_temp;

      PERFORM "__SegmentRoute"(id_route,1500);

      FOR route IN SELECT * FROM sotto_tratte_temp LOOP
          PERFORM "__GenerateRoutePoints"(route.id,300);
      END LOOP;

      DROP TABLE IF EXISTS points;
      CREATE TABLE  points AS (SELECT * FROM route_points ORDER BY gid ASC);
      DROP TABLE IF EXISTS route_points;

      SELECT COUNT(*) FROM points INTO points;
      SELECT COUNT(*) FROM points WHERE km=0 INTO divisor;
      iterator:=1;
      RAISE NOTICE 'TOTAL POINTS %',points;
      FOR point IN SELECT * FROM points LOOP
        RAISE NOTICE 'POINT NUMBER %',iterator;
        IF (point.gid-1)%divisor=0 AND iterator!=1 THEN
          RAISE NOTICE 'JUMPED EXPOSURE %',iterator;
          SELECT * FROM exposure ORDER BY id DESC LIMIT 1 INTO lastexposure;
          INSERT INTO exposure (building_gid, name, geom, exposure) VALUES (point.gid, point.name, point.geom, lastexposure.exposure);

        ELSE

            DROP TABLE IF EXISTS nearestzones;
            DROP TABLE IF EXISTS nearestisoipses;
            DROP TABLE IF EXISTS zonefragments;
            DROP TABLE IF EXISTS linearregression;
            DROP TABLE IF EXISTS hazardzones;
            DROP TABLE IF EXISTS landslide;

                PERFORM __nearestzonefinder(point.gid,800);
                PERFORM __nearestisoipsefinder(point.gid,850);
                PERFORM __zonefragmentsfinder();
                PERFORM __linearregressionfinder(point.gid,2.5);
                PERFORM __landslidefinder(point.gid,50);
                PERFORM __contributionoflandslide(point.gid,50);

        END IF;

        iterator:=iterator+1;

      END LOOP;


     CREATE TABLE IF NOT EXISTS exposure_routes ( gid serial PRIMARY KEY,km INTEGER, geom Geometry, name varchar,exposure FLOAT);
     CREATE TABLE IF NOT EXISTS exposure_route_points ( gid serial PRIMARY KEY,km INTEGER, geom Geometry, name varchar,exposure FLOAT);

     INSERT INTO exposure_routes (km,geom,name,exposure) SELECT ro.km, ro.routegeom, exposure.name,SUM (exposure.exposure) as exposure FROM exposure INNER JOIN points as ro ON exposure.building_gid=ro.gid GROUP BY exposure.name , ro.routegeom, ro.km;
     INSERT INTO exposure_route_points (km,geom,name,exposure) SELECT ro.km, ro.geom, exposure.name,exposure.exposure FROM exposure INNER JOIN points as ro ON exposure.building_gid=ro.gid;

     PERFORM __cleartables();
	END;
$$;

SELECT __exposure_routes(2)