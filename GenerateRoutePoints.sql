create or REPLACE function "__GenerateRoutePoints"(id_route integer, step integer) returns void
LANGUAGE plpgsql
AS $$
DECLARE

    segmentid INTEGER;
    route_segment RECORD;
    route_length float;
    divisore INTEGER;
    passo INTEGER;
    i INTEGER;
    sts float;
    lastgid INTEGER;

    km real;

  BEGIN
  passo:=step;

  --DROP TABLE route_points;
  CREATE TABLE IF NOT EXISTS current_route_points (gid INTEGER,km real, geom Geometry, name varchar,routegeom geometry);
  CREATE TABLE IF NOT EXISTS route_points ( gid serial PRIMARY KEY,segmentid INTEGER REFERENCES route_segments(gid), geom Geometry);


  FOR route_segment IN SELECT * FROM current_route_segments WHERE gid=id_route LOOP

  SELECT a.gid FROM route_segments as a INNER JOIN current_route_segments as b ON b.geom=a.geom WHERE b.gid=id_route INTO segmentid;

  route_length:=st_length(route_segment.geom);
  divisore:=route_length/passo;

  i:=0;
  WHILE i<=divisore LOOP
    km:=(i*passo)/1000;
    sts:=(i*passo)/route_length;


    if(sts>=1) THEN
       sts:=1;
    END IF;

  --RAISE NOTICE '%',st_geometrytype(route.geom);
      INSERT INTO route_points (segmentid,geom) VALUES (segmentid,st_lineinterpolatepoint(route_segment.geom,sts));
    SELECT gid FROM route_points ORDER BY gid DESC LIMIT 1 INTO lastgid;
    INSERT INTO current_route_points (gid,km,geom,name,routegeom) VALUES (lastgid,route_segment.km,st_lineinterpolatepoint(route_segment.geom,sts),route_segment.name,route_segment.geom);

       i:=i+1;

  END LOOP;
END LOOP;

  END;
$$;
