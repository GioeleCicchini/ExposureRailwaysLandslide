create or REPLACE function "__exposure_routes"(id_route integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    point RECORD;
    route RECORD;

  BEGIN
      DROP TABLE IF EXISTS route_points;
      DROP TABLE IF EXISTS sotto_tratte_temp;

      PERFORM "__SegmentRoute"(id_route);

      FOR route IN SELECT * FROM sotto_tratte_temp LOOP
          PERFORM "__GenerateRoutePoints"(route.id);
      END LOOP;

      FOR point IN SELECT * FROM route_points LOOP
              PERFORM "__exposure"(point.gid);
      END LOOP;


      CREATE TABLE IF NOT EXISTS exposure_routes ( gid serial PRIMARY KEY,km INTEGER, geom Geometry, name varchar,exposure FLOAT);

     INSERT INTO exposure_routes (km,geom,name,exposure) SELECT route_points.km, route_points.routegeom, exposure.name,SUM (exposure.exposure) as exposure FROM exposure INNER JOIN route_points ON exposure.building_gid=route_points.gid GROUP BY exposure.name , route_points.routegeom, route_points.km;
     TRUNCATE TABLE exposure;
	END;
$$;