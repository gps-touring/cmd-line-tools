module GpsTouring
  module SVG
    GradientColours = [
      # blues - light to dark
      "71c7ec",
      "1ebbd7",
      "189ad3",
      "107dac",
      "005073",

      # greens - light to dark

      "cbeea8",
      "9dde9a",
      "349e7a",
      "3c7475",
      "2c6866",

	# yellows - light to dark
      "fff100",
      "ffdf00",
      "ffce00",
      "ffac00",
      "ff9b00",

      # reds - light to dark
      "f22323",
      "d61313",
      "b00e0e",
      "8d0606",
      "6d0202"

      # These values were copied from http://www.perbang.dk/rgbgradient/
      # with RGB hax value colour 1: 0600FF, and
      #      RGB hex value colour 2: EB00C8, and
      #      Steps: 24
      #"0500FF",
      #"002FFE",
      #"0065FD",
      #"009AFC",
      #"00CFFB",
      #"00FAF1",
      #"00F9BB",
      #"00F886",
      #"00F851",
      #"00F71C",
      #"17F600",
      #"4BF500",
      #"7FF400",
      #"B2F300",
      #"E5F200",
      #"F1CC00",
      #"F19800",
      #"F06500",
      #"EF3100",
      #"EE0000",
      #"ED0033",
      #"EC0065",
      #"EB0096",
      #"EB00C8"
    ]
    def SVG.gradient_rgb(dx, dy)
      # Any gradient bigger than this will be given the last colour:
      out_of_range_gradient = 0.2
      begin
      gradient = (dy.to_f/dx).abs
      index = GradientColours.size*gradient/out_of_range_gradient
      index = GradientColours.size - 1 if index >= GradientColours.size
      '#' + GradientColours[index]
      rescue
	"black"
      end
    end
  end
end
