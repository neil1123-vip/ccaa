docker run --name="ccaa11" -d -p 6080:6080 -p 6081:6081 -p 6800:6800 -p 51413:51413 \
    -v /root/ccaaDown:/data/ccaaDown \
    -e PASS="solo1.win" \
    ccaa11 \
    sh -c "dccaa pass && dccaa start"
