
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
    def self.find_nearest_point(to_p, from_points)
      min_dist = Float::INFINITY
      nearest_point = nil
      from_points.each {|p|
	dist = p.distance_m(to_p)
	if dist < min_dist
	  nearest_point = p
	  min_dist = dist
	end
      }
      nearest_point
    end
  end
end


