for i in $(ls *.tar.gz)
do
    sha256sum $i > "$i.sha256"
done
