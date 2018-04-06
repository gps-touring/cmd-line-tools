
module GpsTouring
  module Geo
    TORADIANS = Math::PI / 180;
    R = 6371000; # Radius of Earth in metres
    def self.distance_in_metres(p, q)
      # assumes both p and q have methods lat and lon
      # Distance in metres
      # Uses Haversine - more accurate over short distances.
      qLatRad = q.lat * TORADIANS;
      pLatRad = p.lat * TORADIANS;
      latDiffRad = (p.lat - q.lat) * TORADIANS;
      lonDiffRad = (p.lon - q.lon) * TORADIANS;

      a = Math.sin(latDiffRad / 2) * Math.sin(latDiffRad / 2) +
	Math.cos(qLatRad) * Math.cos(pLatRad) *
	Math.sin(lonDiffRad / 2) * Math.sin(lonDiffRad / 2);
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      return R * c;
    end
  end
end


