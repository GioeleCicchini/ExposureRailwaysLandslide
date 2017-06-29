CREATE VIEW exposure_railway_points_view as SELECT p.gid,t.km,p.geom,r.name,e.exposure FROM route_segments as t INNER JOIN route_points as p ON p.segmentid=t.gid INNER JOIN railway_routes as r ON t.route_id = r.gid INNER JOIN exposure_route_points as e ON p.gid=e.pointid;

CREATE VIEW exposure_railway_view as SELECT t.gid,t.km,t.geom,r.name,e.exposure FROM route_segments as t INNER JOIN railway_routes as r ON t.route_id = r.gid INNER JOIN exposure_routes as e ON t.gid=e.routeid;

CREATE VIEW exposure_stations_view as SELECT s.gid,s.geom,s.name,e.exposure FROM railway_stations as s INNER JOIN exposure_stations as e ON s.gid=e.building_gid
