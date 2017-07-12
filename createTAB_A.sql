create function createtaba() returns void
LANGUAGE plpgsql
AS $$
DECLARE
    cursore RECORD;
    railwayid INTEGER;
    n_tratte INTEGER;
    l_tratte FLOAT;
    l_tot FLOAT;
    perce FLOAT;



  BEGIN

     CREATE TABLE IF NOT EXISTS tabella_a(
    id SERIAL PRIMARY KEY,
    idroute INTEGER,
    sottotratte INTEGER,
    l_sottotratte FLOAT,
    l_totale FLOAT,
    perc FLOAT
      );

    FOR cursore IN (SELECT * FROM railway_routes) LOOP
      railwayid:= cursore.gid;
      SELECT count(*) FROM exposure_railway_view as e WHERE e.route_id=railwayid AND e.exposure>1.1 INTO n_tratte;
      SELECT SUM(st_length(geom)) FROM route_segments as s WHERE s.route_id=railwayid INTO l_tratte;
      SELECT st_length(geom) FROM railway_routes WHERE gid=railwayid INTO l_tot;
      perce:=(l_tratte*100)/l_tot;

          INSERT INTO tabella_a (idroute, sottotratte, l_sottotratte, l_totale, perc) VALUES (railwayid,n_tratte,l_tratte,l_tot,perce);

    END LOOP;


  END;

$$;
