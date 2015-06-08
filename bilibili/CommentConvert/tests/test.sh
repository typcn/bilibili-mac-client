./danmaku2ass_native -in=../tests/testdata.xml -out=./test.out -w=1280 -h=720 -font="Heiti SC" -fontsize=25 -alpha=0.8 -dm=5 -ds=5
lcov --directory . --capture --output-file coverage.info
lcov --remove coverage.info 'tests/*' '/usr/*' 'rapid*' --output-file coverage.info
lcov --list coverage.info
coveralls-lcov --repo-token $COVERALLS_TOKEN coverage.info