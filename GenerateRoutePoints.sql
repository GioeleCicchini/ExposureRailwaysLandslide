create or REPLACE function "__GenerateRoutePoints"(id_route integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE
    route RECORD;
    route_length float;
    divisore INTEGER;
    passo INTEGER;
    i INTEGER;
    sts float;

    km INTEGER;

  BEGIN
  passo:=2000;

  --DROP TABLE route_points;
  CREATE TABLE IF NOT EXISTS route_points ( gid serial PRIMARY KEY,km INTEGER, geom Geometry, name varchar,routegeom geometry);

  FOR route IN SELECT * FROM sotto_tratte_temp WHERE id=id_route LOOP



  route_length:=st_length(route.geom);
  divisore:=route_length/passo;

  i:=0;
  WHILE i<=divisore LOOP
    km:=(i*passo)/1000;
    sts:=(i*passo)/route_length;

    if(sts>=1) THEN
       sts:=1;
    END IF;
  RAISE NOTICE '%',st_geometrytype(route.geom);
      INSERT INTO route_points (km,geom,name,routegeom) VALUES (route.km,st_lineinterpolatepoint(route.geom,sts),route.name,route.geom);
       i:=i+1;

  END LOOP;
END LOOP;
  END;

$$;

 
