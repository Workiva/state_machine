#!/bin/sh

# Prepends a license file to every source file in a directory.
# Works with dart, js, css and html files.
#
# Usage:
#     - ./copylic.sh LICENSE dir

LICENSE="$1"
LIB="$2"

sed 's/^/\/\/ /' ${LICENSE} > ${LICENSE}.dart.tmp
echo '' >> ${LICENSE}.dart.tmp

sed 's/^/\/\/ /' ${LICENSE} > ${LICENSE}.js.tmp
echo '' >> ${LICENSE}.js.tmp

echo "/*" | cat - "${LICENSE}" > ${LICENSE}.css.tmp
echo "*/\n" >> ${LICENSE}.css.tmp

echo "<!--" | cat - ${LICENSE} > ${LICENSE}.html.tmp
echo "-->\n" >> ${LICENSE}.html.tmp

for f in `find ${LIB} -type f`; do
    EXTENSION="${f##*.}"
    case ${EXTENSION} in
        dart | js | css | html)
            COPYRIGHT_LINE=`head -n 2 ${LICENSE}.${EXTENSION}.tmp`
            if [ "`head -n 2 ${f}`" != "$COPYRIGHT_LINE" ]; then
                cat ${LICENSE}.${EXTENSION}.tmp ${f} > ${f}.tmp
                mv ${f}.tmp ${f}
                echo "Wrote $LICENSE in $f"
            fi;;
    esac
done

rm ${LICENSE}.dart.tmp
rm ${LICENSE}.js.tmp
rm ${LICENSE}.css.tmp
rm ${LICENSE}.html.tmp