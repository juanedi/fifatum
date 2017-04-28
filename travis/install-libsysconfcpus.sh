# epic build time improvement - see https://github.com/elm-lang/elm-compiler/issues/1473#issuecomment-245704142

if [ ! -d sysconfcpus/bin ];
then
    git clone https://github.com/obmarg/libsysconfcpus.git;
    cd libsysconfcpus;
    ./configure --prefix=$TRAVIS_BUILD_DIR/sysconfcpus;
    make && make install;
    cd ..;
fi
