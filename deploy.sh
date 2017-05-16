cd 2.0;
mkdocs build;
cd ..;

cd 1.5;
couscous generate;
cd ..;

rm -rf build
mkdir -p build;

mv 2.0/site build/2.0;
mv 1.5/.couscous/generated build/1.5;

echo "<meta http-equiv=\"refresh\" content=\"0; url=/1.5/\">" > build/index.html;