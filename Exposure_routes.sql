create or REPLACE function "__exposure_routes"(id_route integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    point RECORD;
    route_segment RECORD;
    points INTEGER;
    iterator INTEGER;
    divisor INTEGER;
    lastexposure RECORD;
    startid INTEGER;

  BEGIN

      DROP TABLE IF EXISTS current_route_segments;

      PERFORM "__SegmentRoute"(id_route,1500);

      FOR route_segment IN SELECT * FROM current_route_segments LOOP
          PERFORM "__GenerateRoutePoints"(route_segment.gid,300);
      END LOOP;

      DROP TABLE IF EXISTS points;
      CREATE TABLE  points AS (SELECT * FROM current_route_points ORDER BY gid ASC);
      DROP TABLE IF EXISTS current_route_points;

      SELECT COUNT(*) FROM points INTO points;
      SELECT COUNT(*) FROM points WHERE km=0 INTO divisor;
      SELECT gid FROM points LIMIT 1 INTO startid;
      iterator:=1;
      RAISE NOTICE 'TOTAL POINTS %',points;
      FOR point IN SELECT * FROM points LOOP
        RAISE NOTICE 'POINT NUMBER %',iterator;
        IF (point.gid-startid)%divisor=0 AND iterator!=1 THEN
          RAISE NOTICE 'JUMPED EXPOSURE %',iterator;
          SELECT * FROM exposure ORDER BY id DESC LIMIT 1 INTO lastexposure;

        --  SELECT gid FROM route_points WHERE route_points.geom=point.geom ORDER BY gid DESC LIMIT 1 INTO pointid;
          RAISE NOTICE 'ID POINT %',point.gid;
          --INSERT INTO exposure (building_gid, name, geom, exposure) VALUES (point.gid, point.name, point.geom, lastexposure.exposure);

          INSERT INTO exposure (point_gid, exposure) VALUES (point.gid, lastexposure.exposure);

        ELSE

            DROP TABLE IF EXISTS nearestzones;
            DROP TABLE IF EXISTS nearestisoipses;
            DROP TABLE IF EXISTS zonefragments;
            DROP TABLE IF EXISTS bufferedlinearregression;
            DROP TABLE IF EXISTS landslidezones;
            DROP TABLE IF EXISTS landslide;

                PERFORM __nearestzonefinder(point.gid,800);
                PERFORM __nearestisoipsefinder(point.gid,850);
                PERFORM __zonefragmentsfinder();
                PERFORM __bufferedlinearregressionfinder(point.gid,2.5);
                PERFORM __landslidefinder(point.gid,50);
                PERFORM __contributionoflandslide(point.gid,50);

        END IF;

        iterator:=iterator+1;

      END LOOP;

     CREATE TABLE IF NOT EXISTS exposure_route_points (pointid INTEGER PRIMARY KEY REFERENCES route_points(gid) ,exposure FLOAT);
     CREATE TABLE IF NOT EXISTS exposure_routes (routeid INTEGER PRIMARY KEY REFERENCES route_segments(gid),exposure FLOAT);

     INSERT INTO exposure_route_points (pointid,exposure) SELECT point_gid,exposure FROM exposure;
     INSERT INTO exposure_routes (routeid,exposure) SELECT t.gid, AVG(e.exposure) FROM route_points as p INNER JOIN exposure as e ON p.gid=e.point_gid INNER JOIN route_segments as t ON t.gid=p.segmentid GROUP BY t.gid;

     PERFORM __cleartables();
	END;
$$;
