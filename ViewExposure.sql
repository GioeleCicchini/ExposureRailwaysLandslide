CREATE VIEW StationExposure AS
  SELECT id,name,exposure FROM exposure INNER JOIN railway_stations ON exposure.building_gid = railway_stations.gid ;
