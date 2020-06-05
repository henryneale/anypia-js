# this script requires yq and mac? sed / pip3 install yq
for i in `yq '.matrix.include[] | .name' .travis.yml | tr -d '"'`
do
    filename="./installbuild-$i"

    # write the pre-script case-by-case
    if test "$i" = 'windows'; then
        extension="bat"
        echo ":: ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension" 
        echo "SET MSBUILD_PATH=C:\Program Files (x86)\MSBuild\14.0\Bin;C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin" >> "$filename.$extension" 
        echo "SET PATH=%PATH%;%MSBUILD_PATH%" >> "$filename.$extension"
        echo "choco install wget" >> "$filename.$extension"
        echo "choco install 7zip" >> "$filename.$extension"
    elif test "$i" = 'emscripten-anypiab-windows'; then
        extension="bat"
        echo ":: ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension" 
        echo "SET MSBUILD_PATH=C:\Program Files (x86)\MSBuild\14.0\Bin;C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin;C:\Program Files\CMake\bin" >> "$filename.$extension" 
        echo "SET PATH=%PATH%;%MSBUILD_PATH%" >> "$filename.$extension"
        echo "choco install wget" >> "$filename.$extension"
        echo "choco install 7zip" >> "$filename.$extension"
        echo "choco install cmake" >> "$filename.$extension"
    elif test "$i" = 'mac-anypiab'; then
        extension="sh"
        echo "# ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension"
        echo "brew install " `yq -c --raw-output ".matrix.include[] | select(.name == \"mac-anypiab\") | .addons.homebrew.packages | @sh" .travis.yml | tr -d "\'"` >> "$filename.$extension"
    elif test "$i" = 'emscripten-anypiab-mac'; then
        extension="sh"
        echo "# ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension"
        echo "brew install " `yq -c --raw-output ".matrix.include[] | select(.name == \"emscripten-anypiab-mac\") | .addons.homebrew.packages | @sh" .travis.yml | tr -d "\'"` >> "$filename.$extension"
    elif test "$i" = 'linux-anypiab'; then
        extension="sh"
        echo "# ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension"
        echo "apt install " `yq -c --raw-output ".matrix.include[] | select(.name == \"linux-anypiab\") | .addons.apt.packages | @sh" .travis.yml` >> "$filename.$extension"
    else
        extension="sh"
        echo "# ** This file was automatically generated by generate_buildscripts.sh **" > "$filename.$extension"
        echo "" >> "$filename.$extension"
    fi

    # write the rest of the script
    yq -c --raw-output ".matrix.include[] | select(.name == \"$i\") | .script[]" .travis.yml >> "$filename.$extension"

    # make modifications for batch files from the travis-ci environment
    if test "$i" = 'windows'; then
        # If you don't use call, the batch file stops after the other batch file.
        sed 's/\.\/bootstrap.bat/call bootstrap.bat/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"

    elif test "$i" = 'emscripten-anypiab-windows'; then
        # If you don't use call, the batch file stops after the other batch file.
        sed 's/\.\/bootstrap.bat/call bootstrap.bat/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"
        
        # If you don't use call, the batch file stops after the other batch file.
        sed 's/\.\/emsdk.bat/call emsdk.bat/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"

        #emsdk wipes out our MSBUILD_PATH from PATH
        sed 's/export PATH=$MSBUILD_PATH:$PATH/SET PATH=%PATH%;%MSBUILD_PATH%/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"

        #fix boost paths
        sed 's/export BOOST_INCL="`pwd`"/SET BOOST_INCL="%cd%"/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"  
        sed 's/export BOOST_LIB="`pwd`\\stage\\lib"/SET BOOST_LIB="%cd%\\stage\\lib"/g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension"

        #fix emcmake
        sed 's/..\/..\/emsdk\/upstream\/emscripten\/emcmake cmake -DBOOST_ROOT=$BOOST_INCL -DBOOST_LIBRARYDIR=$BOOST_LIB -G "NMake Makefiles" ../call emcmake cmake -DBOOST_ROOT=%BOOST_INCL% -DBOOST_LIBRARYDIR=%BOOST_LIB%  -G "NMake Makefiles" ../g' "$filename.$extension" > "$filename.$extension.tmp"
        mv "$filename.$extension.tmp" "$filename.$extension" 
    fi

    # make executable
    chmod +x "$filename.$extension"
done