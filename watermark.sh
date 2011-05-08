 convert -font helvetica  -size 140x80 xc:none -fill grey \
          -gravity NorthWest -draw "text 10,10 'Art Gallery Sample'" \
          -gravity SouthEast -draw "text 5,15 'Art Gallery Sample'" \
          miff:- |\
    composite -tile - $*
