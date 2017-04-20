CREATE OR REPLACE FUNCTION z_linemergeisoipse () RETURNS void
	LANGUAGE plpgsql
AS $$

	DECLARE
    Poligoni RECORD;
    PrimoPoligono RECORD ;
    PrimaIsoipse RECORD ;
    IsoipseRimaste INTEGER;
    PoligonoFinale BOOLEAN;
  BEGIN


     DROP TABLE IF EXISTS PoligoniStazione;
      CREATE TABLE PoligoniStazione(
        id SERIAL PRIMARY KEY ,
        geom GEOMETRY,
        id_voronoi_polygon INTEGER
      );

    --- Prendo un primo poligono e interseco con le curve di livello (curve risultanti dall'intersezione con il buffer)

    FOR Poligoni IN (SELECT * FROM  nearstationpolygons) LOOP

         Raise NOTICE  'Poligono %',Poligoni.id;


    DROP TABLE IF EXISTS IsoipseIntersectPoligon;
   CREATE TEMP TABLE IsoipseIntersectPoligon(
        id INTEGER,
        counter SERIAL,
        geom GEOMETRY,
        altitude INTEGER
      );
    DROP TABLE IF EXISTS TempPoligon;
      CREATE TEMP TABLE TempPoligon(
        id SERIAL PRIMARY KEY ,
        geom GEOMETRY
      );
      DROP TABLE IF EXISTS FinalPoligonSplit;
      CREATE TEMP TABLE FinalPoligonSplit(
        id SERIAL PRIMARY KEY ,
        geom GEOMETRY,
        id_voronoi_polygon INTEGER,
        altitude INTEGER
      );


      SELECT * INTO PrimoPoligono FROM nearstationpolygons WHERE id = Poligoni.id;
      INSERT INTO IsoipseIntersectPoligon(id,geom) (SELECT isoipsenearstation.id,(st_dump(st_collectionextract(st_intersection(isoipsenearstation.geom,PrimoPoligono.geom),2))).geom as geom FROM isoipsenearstation);

    --- prendo un isoipse e divido per la prima volta
    SELECT * INTO PrimaIsoipse FROM IsoipseIntersectPoligon LIMIT 1;
      --- split da fare con isoipse
      INSERT INTO TempPoligon(geom) (SELECT (st_dump(
          st_collectionextract(st_split(PrimoPoligono.geom,(SELECT isoipsenearstation.geom FROM isoipsenearstation WHERE isoipsenearstation.id = PrimaIsoipse.id)),3))).geom);


     WHILE TRUE LOOP
      IF (SELECT count(*) FROM TempPoligon)> 0 THEN
          SELECT * INTO PrimoPoligono FROM TempPoligon LIMIT 1;

        PoligonoFinale := TRUE ;
        IsoipseRimaste := 0;

       --  Raise NOTICE  'Poligono IN WHILE %',Poligoni.id;
         --Raise NOTICE  'Numero Poligoni %', (SELECT count(*) FROM TempPoligon);

          WHILE IsoipseRimaste < (SELECT count(*) FROM IsoipseIntersectPoligon) LOOP
        IsoipseRimaste := IsoipseRimaste + 1;
            CREATE TEMP TABLE TMP AS (SELECT (st_dump(st_collectionextract(st_split(PrimoPoligono.geom,(SELECT isoipsenearstation.geom FROM isoipsenearstation WHERE isoipsenearstation.id =(SELECT IsoipseIntersectPoligon.id FROM IsoipseIntersectPoligon WHERE counter= IsoipseRimaste))),3))).geom);
            DELETE FROM TMP WHERE st_area(geom) < 500;
                  IF (SELECT count(*) FROM TMP) > 1 THEN

                    PoligonoFinale := FALSE ;

                    INSERT INTO TempPoligon(geom) (SELECT (st_dump(st_collectionextract(st_split(PrimoPoligono.geom,(SELECT isoipsenearstation.geom FROM isoipsenearstation WHERE isoipsenearstation.id =(SELECT IsoipseIntersectPoligon.id FROM IsoipseIntersectPoligon WHERE IsoipseIntersectPoligon.counter = IsoipseRimaste))),3))).geom);

                    DELETE FROM TempPoligon WHERE st_area(geom) < 0.05;
                --Raise NOTICE  'area %', (SELECT  st_area(geom) From TempPoligon WHERE TempPoligon.id = PrimoPoligono.id );

                    DELETE FROM TempPoligon WHERE TempPoligon.id = PrimoPoligono.id ;


                    DROP TABLE TMP;
                    EXIT ;
                  END IF;
          DROP TABLE TMP;
          END LOOP;


--         Raise NOTICE  'Fuori while interno';
           IF PoligonoFinale = TRUE THEN
                INSERT INTO FinalPoligonSplit(geom,id_voronoi_polygon) SELECT PrimoPoligono.geom,Poligoni.id;
               DELETE FROM TempPoligon WHERE TempPoligon.id = PrimoPoligono.id ;
            END IF;
       --  Raise NOTICE  '--------';

      ELSE
          EXIT ;
      END IF;
    END LOOP;

      INSERT INTO PoligoniStazione(geom,id_voronoi_polygon) (SELECT FinalPoligonSplit.geom,FinalPoligonSplit.id_voronoi_polygon FROM FinalPoligonSplit);
      DELETE FROM poligonistazione WHERE st_area(poligonistazione.geom) < 10;

      RAISE NOTICE 'Finito un hotspot';
      TRUNCATE TABLE IsoipseIntersectPoligon CONTINUE IDENTITY RESTRICT;
      TRUNCATE TABLE TempPoligon CONTINUE IDENTITY RESTRICT;
      TRUNCATE TABLE FinalPoligonSplit CONTINUE IDENTITY RESTRICT;

END LOOP ;


	END;
$$
