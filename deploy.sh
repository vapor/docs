cd 2.0;
mkdocs build;
cd ..;

cd 3.0;
mkdocs build;
cd ..;

cd 1.5;
couscous generate;
cd ..;

rm -rf build
mkdir -p build;

cd leaf-pygment && ./compile.sh
cd .. && sudo pip install leaf-pygment/dist/leaf-0.1.0-dev.tar.gz

mv 2.0/site build/2.0;
mv 3.0/site build/3.0;
mv 1.5/.couscous/generated build/1.5;

echo "<meta http-equiv=\"refresh\" content=\"0; url=/3.0/\">" > build/index.html;
git add .
git commit -am "deploy"
git push
vapor cloud deploy --env=production --build=incremental -y
