function help() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- croot:   Changes directory to the top of the tree.
- m:       Makes from the top of the tree.
- mm:      Builds all of the modules in the current directory.
- mmm:     Builds all of the modules in the supplied directories.
- cgrep:   Greps on all local C/C++ files.
- jgrep:   Greps on all local Java files.
- resgrep: Greps on all local res/*.xml files.
- godir:   Go to the directory containing a file.

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^function /s/function \([a-z_]*\).*/\1/p" | sort`; do
      A="$A $i"
    done
    echo $A
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    (cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-abs-$1)
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
}

# check to see if the supplied product is one we can build
function check_product()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        TARGET_PRODUCT=$1 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

VARIANT_CHOICES=(user userdebug eng)

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

LCD_CHOICES=(BOOYI_NT35510 BOE_NT35510 YXD_NT35510 BOOYI_HX8369A)
function check_lcd()
{
    for v in ${LCD_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

# By Michael.Chan 2013.03.19 begin
LOGO_CHOICES=(NORMAL HONGKANG SAMSUNG)
# check to see if the supplied logo is valid
function check_logo()
{
    for v in ${LOGO_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}
# By Michael.Chan 2013.03.19 end


# By Scorpion.Huang 2012.08.22 begin
PROJECT_CHOICES=(F6185 HK6186)

# check to see if the supplied project is valid
function check_project()
{
    for v in ${PROJECT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}
# By Scorpion.Huang 2012.08.22 end

function setpaths()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi

    ##################################################################
    #                                                                #
    #              Read me before you modify this code               #
    #                                                                #
    #   This function sets ANDROID_BUILD_PATHS to what it is adding  #
    #   to PATH, and the next time it is run, it removes that from   #
    #   PATH.  This is required so lunch can be run more than once   #
    #   and still have working paths.                                #
    #                                                                #
    ##################################################################

    # Note: on windows/cygwin, ANDROID_BUILD_PATHS will contain spaces
    # due to "C:\Program Files" being in the path.

    # out with the old
    if [ -n "$ANDROID_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_BUILD_PATHS/}
    fi
    if [ -n "$ANDROID_PRE_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_PRE_BUILD_PATHS/}
        # strip trailing ':', if any
        export PATH=${PATH/%:/}
    fi

    # and in with the new
    CODE_REVIEWS=
    prebuiltdir=$(getprebuilt)

    # The gcc toolchain does not exists for windows/cygwin. In this case, do not reference it.
    export ANDROID_EABI_TOOLCHAIN=
    toolchaindir=toolchain/arm-linux-androideabi-4.4.x/bin
    if [ -d "$prebuiltdir/$toolchaindir" ]; then
        export ANDROID_EABI_TOOLCHAIN=$prebuiltdir/$toolchaindir
    fi

    export ARM_EABI_TOOLCHAIN=
    toolchaindir=toolchain/arm-eabi-4.4.3/bin
    if [ -d "$prebuiltdir/$toolchaindir" ]; then
        export ARM_EABI_TOOLCHAIN=$prebuiltdir/$toolchaindir
    fi

    export ANDROID_TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN
    export ANDROID_QTOOLS=$T/development/emulator/qtools
    export ANDROID_BUILD_PATHS=:$(get_build_var ANDROID_BUILD_PATHS):$ANDROID_QTOOLS:$ANDROID_TOOLCHAIN:$ARM_EABI_TOOLCHAIN$CODE_REVIEWS
    export PATH=$PATH$ANDROID_BUILD_PATHS

    unset ANDROID_JAVA_TOOLCHAIN
    unset ANDROID_PRE_BUILD_PATHS
    if [ -n "$JAVA_HOME" ]; then
        export ANDROID_JAVA_TOOLCHAIN=$JAVA_HOME/bin
        export ANDROID_PRE_BUILD_PATHS=$ANDROID_JAVA_TOOLCHAIN:
        export PATH=$ANDROID_PRE_BUILD_PATHS$PATH
    fi

    unset ANDROID_PRODUCT_OUT
    export ANDROID_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
    export OUT=$ANDROID_PRODUCT_OUT

    unset ANDROID_HOST_OUT
    export ANDROID_HOST_OUT=$(get_abs_build_var HOST_OUT)

    # needed for building linux on MacOS
    # TODO: fix the path
    #export HOST_EXTRACFLAGS="-I "$T/system/kernel_headers/host_include
}

function printconfig()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    get_build_var report_config
}

function set_stuff_for_environment()
{
    settitle
    set_java_home
    setpaths
    set_sequence_number

    export ANDROID_BUILD_TOP=$(gettop)
}

function set_sequence_number()
{
    export BUILD_ENV_SEQUENCE_NUMBER=10
}

function settitle()
{
    if [ "$STAY_OFF_MY_LAWN" = "" ]; then
        local product=$TARGET_PRODUCT
        local variant=$TARGET_BUILD_VARIANT
        local apps=$TARGET_BUILD_APPS
        if [ -z "$apps" ]; then
            export PROMPT_COMMAND="echo -ne \"\033]0;[${product}-${variant}] ${USER}@${HOSTNAME}: ${PWD}\007\""
        else
            export PROMPT_COMMAND="echo -ne \"\033]0;[$apps $variant] ${USER}@${HOSTNAME}: ${PWD}\007\""
        fi
    fi
}

function addcompletions()
{
    local T dir f

    # Keep us from trying to run in something that isn't bash.
    if [ -z "${BASH_VERSION}" ]; then
        return
    fi

    # Keep us from trying to run in bash that's too old.
    if [ ${BASH_VERSINFO[0]} -lt 3 ]; then
        return
    fi

    dir="sdk/bash_completion"
    if [ -d ${dir} ]; then
        for f in `/bin/ls ${dir}/[a-z]*.bash 2> /dev/null`; do
            echo "including $f"
            . $f
        done
    fi
}

function choosetype()
{
    echo "Build type choices are:"
    echo "     1. release"
    echo "     2. debug"
    echo

    local DEFAULT_NUM DEFAULT_VALUE
    DEFAULT_NUM=1
    DEFAULT_VALUE=release

    export TARGET_BUILD_TYPE=
    local ANSWER
    while [ -z $TARGET_BUILD_TYPE ]
    do
        echo -n "Which would you like? ["$DEFAULT_NUM"] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi
        case $ANSWER in
        "")
            export TARGET_BUILD_TYPE=$DEFAULT_VALUE
            ;;
        1)
            export TARGET_BUILD_TYPE=release
            ;;
        release)
            export TARGET_BUILD_TYPE=release
            ;;
        2)
            export TARGET_BUILD_TYPE=debug
            ;;
        debug)
            export TARGET_BUILD_TYPE=debug
            ;;
        *)
            echo
            echo "I didn't understand your response.  Please try again."
            echo
            ;;
        esac
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}


#
# This function set the default used build spec in case of user using tranditional choosecombo.
#
function initbuildspec()
{
    local -a GEN_QRDPLUS_ENV_RET
    GEN_QRDPLUS_ENV_PL=build/buildplus/tool/qrdplus_target_gen.pl
    INIT_BUILD_SPEC=cu

    if [ "$INIT_BUILD_SPEC" != "default" ] ; then
        GEN_QRDPLUS_ENV_RET=(`perl $GEN_QRDPLUS_ENV_PL $INIT_BUILD_SPEC`)
    else
        GEN_QRDPLUS_ENV_RET=(`perl $GEN_QRDPLUS_ENV_PL`)
    fi

    if [ "$GEN_QRDPLUS_ENV_RET" != "GEN_SUCCESS" ] ; then
        echo "target build Env generate failed, your should abort continuous make procedure!"
    fi
}


#
# This function chooses a TARGET_QRD_BUILD_SPEC by picking a buildspec.
#
function choosebuildspec()
{
    local -a speclist
    speclist=(`/usr/bin/find build/buildplus/buildspec -name *.spec 2>/dev/null|cut -d'/' -f4|cut -d'.' -f1`)    
    local index=1
    local p
    echo "BuildSpec choices are:"
    echo "     0. default"
    for p in ${speclist[@]}
    do
        echo "     $index. $p"
        let "index = $index + 1"
    done

    default_value=cu

    export TARGET_QRD_BUILD_SPEC=
    local ANSWER
    while [ -z "$TARGET_QRD_BUILD_SPEC" ]
    do
        echo -n "Which build spec would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            export TARGET_QRD_BUILD_SPEC=$default_value
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_QRD_BUILD_SPEC=$default_value
        elif [ "$ANSWER" == "0" ] ; then
            export TARGET_QRD_BUILD_SPEC=default
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            local poo=`echo -n $ANSWER`
            if [ $poo -le ${#speclist[@]} ] ; then
                export TARGET_QRD_BUILD_SPEC=${speclist[$(($ANSWER-1))]}
            else
                echo "** Bad buildspec selection: $ANSWER"
            fi
        else
            if [ -f "build/buildplus/buildspec/"$ANSWER".spec" ] ; then
                export TARGET_QRD_BUILD_SPEC=$ANSWER
            else
                echo "** Not a valid build spec: $ANSWER"
            fi

        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

    local -a GEN_QRDPLUS_ENV_RET
    GEN_QRDPLUS_ENV_PL=build/buildplus/tool/qrdplus_target_gen.pl
    if [ "$TARGET_QRD_BUILD_SPEC" != "default" ] ; then
        GEN_QRDPLUS_ENV_RET=(`perl $GEN_QRDPLUS_ENV_PL $TARGET_QRD_BUILD_SPEC`)
    else
        GEN_QRDPLUS_ENV_RET=(`perl $GEN_QRDPLUS_ENV_PL`)
    fi

    if [ "$GEN_QRDPLUS_ENV_RET" != "GEN_SUCCESS" ] ; then
        echo "target build Env generate failed, your should abort continuous make procedure!"
    fi    
}


#
# This function chooses a TARGET_PRODUCT by picking a product by name.
# It finds the list of products by finding all the AndroidProducts.mk
# files and looking for the product specific filenames in them.
#
function chooseproduct()
{
# Find the list of all products by looking for all AndroidProducts.mk files under the
# device/, vendor/ and build/target/product/ directories and look for the format
# LOCAL_DIR/<ProductSpecificFile.mk> and extract the name ProductSpecificFile from it.
# This will give the list of all products that can be built using choosecombo

    local -a prodlist

# Find all AndroidProducts.mk files under the dirs device/, build/target/ and vendor/
# Extract lines containing .mk from them
# Extract lines containing LOCAL_DIR
# Extract the name of the product specific file

    prodlist=(`/usr/bin/find device/ build/target/ vendor/ -name AndroidProducts.mk 2>/dev/null|
    xargs grep -h \.mk|
    grep LOCAL_DIR|
    cut -d'/' -f2|cut -d' ' -f1|sort|uniq|cut -d'.' -f1`)

    local index=1
    local p
    echo "Product choices are:"
    for p in ${prodlist[@]}
    do
        echo "     $index. $p"
        let "index = $index + 1"
    done

    if [ "x$TARGET_PRODUCT" != x ] ; then
        default_value=$TARGET_PRODUCT
    else
        default_value=full
    fi

    export TARGET_PRODUCT=
    local ANSWER
    while [ -z "$TARGET_PRODUCT" ]
    do
        echo "You can also type the name of a product if you know it."
        echo -n "Which product would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_PRODUCT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            local poo=`echo -n $ANSWER`
            if [ $poo -le ${#prodlist[@]} ] ; then
                export TARGET_PRODUCT=${prodlist[$(($ANSWER-1))]}
            else
                echo "** Bad product selection: $ANSWER"
            fi
        else
            if check_product $ANSWER
            then
                export TARGET_PRODUCT=$ANSWER
            else
                echo "** Not a valid product: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

function choosevariant()
{
    echo "Variant choices are:"
    local index=1
    local v
    for v in ${VARIANT_CHOICES[@]}
    do
        # The product name is the name of the directory containing
        # the makefile we found, above.
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=eng
    local ANSWER

    export TARGET_BUILD_VARIANT=
    while [ -z "$TARGET_BUILD_VARIANT" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_BUILD_VARIANT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#VARIANT_CHOICES[@]}" ] ; then
                export TARGET_BUILD_VARIANT=${VARIANT_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_variant $ANSWER
            then
                export TARGET_BUILD_VARIANT=$ANSWER
            else
                echo "** Not a valid variant: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done
}


# By Michael.Chan 2013.03.19 
#
# This function chooses a BootLogo by compiler.
function chooseLogo()
{
    echo "BootLogo choices are:"
    local index=1
    local v
    for v in ${LOGO_CHOICES[@]}
    do
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=NORMAL
    local ANSWER

    export USES_LOGO=
    while [ -z "$USES_LOGO" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export USES_LOGO=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#LOGO_CHOICES[@]}" ] ; then
                export USES_LOGO=${LOGO_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_logo $ANSWER
            then
                export USES_LOGO=$ANSWER
            else
                echo "** Not a valid logo file: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

# replace reference files
    echo
    echo " LOGO=$USES_LOGO"
    echo
    echo "Replace logo reference files:"
    if [ "$USES_LOGO" = "NORMAL" ]; then
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_cu.h_normal  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_cu.h
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_qrd.h_normal  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_qrd.h
            cp -f -v  device/qcom/common/initlogo/initlogo.rle_480x800_up_normal  device/qcom/common/initlogo.rle_480x800_up
            rm -f  device/qcom/common/bootanimation.zip
    elif [ "$USES_LOGO" = "HONGKANG" ]; then
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_cu.h_hongkang  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_cu.h
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_qrd.h_hongkang  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_qrd.h
            cp -f -v  device/qcom/common/initlogo/initlogo.rle_480x800_up_hongkang  device/qcom/common/initlogo.rle_480x800_up
            cp -f -v  device/qcom/common/bootanimation/bootanimation.zip_hongkang  device/qcom/common/bootanimation.zip
    elif [ "$USES_LOGO" = "SAMSUNG" ]; then
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_cu.h_normal  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_cu.h
            cp -f -v  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash/splash_qrd.h_normal  vendor/qcom/opensource/qrdplus/QRDExtensions/DynamicComponents/res/Splash_QRD/splash_qrd.h
            cp -f -v  device/qcom/common/initlogo/initlogo.rle_480x800_up_normal  device/qcom/common/initlogo.rle_480x800_up
            cp -f -v  device/qcom/common/bootanimation/bootanimation.zip_samsung  device/qcom/common/bootanimation.zip      
    else
        echo "logo files error"
        return
    fi
#    set_stuff_for_environment

}





# By Scorpion.Huang 2012.08.22 begin
#
# This function chooses a TARGET_BUILD_PROJECT by picking a project by name.
# It finds the list of projects by finding all the AndroidProducts.mk
# files and looking for the product specific filenames in them.
#
function chooseproject()
{
    echo "Project choices are:"
    local index=1
    local v
    for v in ${PROJECT_CHOICES[@]}
    do
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=F6185
    local ANSWER

    export TARGET_BUILD_PROJECT=
    while [ -z "$TARGET_BUILD_PROJECT" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_BUILD_PROJECT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#PROJECT_CHOICES[@]}" ] ; then
                export TARGET_BUILD_PROJECT=${PROJECT_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_project $ANSWER
            then
                export TARGET_BUILD_PROJECT=$ANSWER
            else
                echo "** Not a valid project: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

#    set_stuff_for_environment
}
# By Scorpion.Huang 2012.08.22 end

# choose lcd from BOOYI_NT35510 BOE_NT35510 YXD_NT35510 BOOYI_HX8369A
function chooselcd()
{
    echo "LCD choices are:"
    local index=1
    local v
    for v in ${LCD_CHOICES[@]}
    do
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=BOOYI_NT35510
    local ANSWER

    export USES_LCD=
    while [ -z "$USES_LCD" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export USES_LCD=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#LCD_CHOICES[@]}" ] ; then
                export USES_LCD=${LCD_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_lcd $ANSWER
            then
                export USES_LCD=$ANSWER
            else
                echo "** Not a valid lcd type: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

# replace reference files
    echo
    echo "Project=$TARGET_BUILD_PROJECT LCD=$USES_LCD"
    echo
    echo "Replace lcd reference config files:"
    if [ "$USES_LCD" = "BOOYI_NT35510" ]; then
        if [ "$TARGET_BUILD_PROJECT" = "HK6186" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6186_LCD_NT35510_BOOYI  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_BOOYI.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        elif [ $TARGET_BUILD_PROJECT = "F6185" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6185_LCD_NT35510_BOOYI  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_BOOYI.mk  bootable/bootloader/lk/target/msm7627a/rules.mk       
        else
            echo "pls check error"
        fi
    elif [ "$USES_LCD" = "BOE_NT35510" ]; then
        if [ "$TARGET_BUILD_PROJECT" = "HK6186" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6186_LCD_NT35510_BOE  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_BOE.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        elif [ "$TARGET_BUILD_PROJECT" = "F6185" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6185_LCD_NT35510_BOE  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_BOE.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
       else    
            echo "pls check error"
        fi
    elif [ "$USES_LCD" = "YXD_NT35510" ]; then
        if [ "$TARGET_BUILD_PROJECT" = "HK6186" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6186_LCD_NT35510_YXD  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_YXD.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        elif [ "$TARGET_BUILD_PROJECT" = "F6185" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6185_LCD_NT35510_YXD  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_NT35510_YXD.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        else
            echo "pls check error"        
        fi
    elif [ "$USES_LCD" = "BOOYI_HX8369A" ]; then
        if [ "$TARGET_BUILD_PROJECT" = "HK6186" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6186_LCD_HX8369A_BOOYI  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_HX8369A_BOOYI.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        elif [ "$TARGET_BUILD_PROJECT" = "F6185" ]; then
            cp -f -v  kernel/arch/arm/configs/msm7627a-perf_defconfig_HK6185_LCD_HX8369A_BOOYI  kernel/arch/arm/configs/msm7627a-perf_defconfig
            cp -f -v  bootable/bootloader/lk/target/msm7627a/rules_HK618x_LCD_HX8369A_BOOYI.mk  bootable/bootloader/lk/target/msm7627a/rules.mk
        else
            echo "pls check error"               
        fi
    else
        echo "lcd type error"
        return
    fi
#    set_stuff_for_environment
}
#
#this is the QRD extended choosecombo, it support first select the build spec. then choose other vars
function choosecomboext()
{
    choosebuildspec $1
    shift

    echo
    echo
    choosecombo $*
}





function choosecombo()
{
    choosetype $1

    echo
    echo
    chooseproduct $2

    echo
    echo
    choosevariant $3

# By Scorpion.Huang 2012.08.22 begin
    echo
    echo
    chooseproject $4
# By Scorpion.Huang 2012.08.22 end

    echo
    echo
    chooselcd $5

# By Michael.Chan 2013.03.19 begin
    echo
    echo
    chooseLogo $6
# By Michael.Chan 2013.03.19 end

    echo
    set_stuff_for_environment
    printconfig
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# add the default one here
add_lunch_combo full-eng
add_lunch_combo full_x86-eng
add_lunch_combo vbox_x86-eng

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    echo
    echo "Lunch menu... pick a combo:"

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]}
    do
        echo "     $i. $choice"
        i=$(($i+1))
    done

    echo
}

function lunch()
{
    local answer

    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like? [full-eng] "
        read answer
    fi

    local selection=

    if [ -z "$answer" ]
    then
        selection=full-eng
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
    then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
        then
            selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
    then
        selection=$answer
    fi

    if [ -z "$selection" ]
    then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    export TARGET_BUILD_APPS=

    local product=$(echo -n $selection | sed -e "s/-.*$//")
    check_product $product
    if [ $? -ne 0 ]
    then
        echo
        echo "** Don't have a product spec for: '$product'"
        echo "** Do you have the right repo manifest?"
        product=
    fi

    local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
    check_variant $variant
    if [ $? -ne 0 ]
    then
        echo
        echo "** Invalid variant: '$variant'"
        echo "** Must be one of ${VARIANT_CHOICES[@]}"
        variant=
    fi

    if [ -z "$product" -o -z "$variant" ]
    then
        echo
        return 1
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release

    echo

    set_stuff_for_environment
    printconfig
}

# Tab completion for lunch.
function _lunch()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=( $(compgen -W "${LUNCH_MENU_CHOICES[*]}" -- ${cur}) )
    return 0
}
complete -F _lunch lunch

# Configures the build to build unbundled apps.
# Run tapas with one ore more app names (from LOCAL_PACKAGE_NAME)
function tapas()
{
    local variant=$(echo -n $(echo $* | xargs -n 1 echo | grep -E '^(user|userdebug|eng)$'))
    local apps=$(echo -n $(echo $* | xargs -n 1 echo | grep -E -v '^(user|userdebug|eng)$'))

    if [ $(echo $variant | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build variants supplied: $variant"
        return
    fi
    if [ -z "$variant" ]; then
        variant=eng
    fi
    if [ -z "$apps" ]; then
        apps=all
    fi

    export TARGET_PRODUCT=full
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release
    export TARGET_BUILD_APPS=$apps

    set_stuff_for_environment
    printconfig
}

function gettop
{
    local TOPFILE=build/core/envsetup.mk
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        echo $TOP
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            # We redirect cd to /dev/null in case it's aliased to
            # a command that prints something as a side-effect
            # (like pushd)
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                cd .. > /dev/null
                T=`PWD= /bin/pwd`
            done
            cd $HERE > /dev/null
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function m()
{
    T=$(gettop)
    if [ "$T" ]; then
        make -C $T $@
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function findmakefile()
{
    TOPFILE=build/core/envsetup.mk
    # We redirect cd to /dev/null in case it's aliased to
    # a command that prints something as a side-effect
    # (like pushd)
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            echo $T/Android.mk
            cd $HERE > /dev/null
            return
        fi
        cd .. > /dev/null
    done
    cd $HERE > /dev/null
}

function mm()
{
    # If we're sitting in the root of the build tree, just do a
    # normal make.
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        make $@
    else
        # Find the closest Android.mk file.
        T=$(gettop)
        local M=$(findmakefile)
        # Remove the path to top as the makefilepath needs to be relative
        local M=`echo $M|sed 's:'$T'/::'`
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        elif [ ! "$M" ]; then
            echo "Couldn't locate a makefile from the current directory."
        else
            ONE_SHOT_MAKEFILE=$M make -C $T all_modules $@
        fi
    fi
}

function mmm()
{
    T=$(gettop)
    if [ "$T" ]; then
        local MAKEFILE=
        local ARGS=
        local DIR TO_CHOP
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        for DIR in $DIRS ; do
            DIR=`echo $DIR | sed -e 's:/$::'`
            if [ -f $DIR/Android.mk ]; then
                TO_CHOP=`(cd -P -- $T && pwd -P) | wc -c | tr -d ' '`
                TO_CHOP=`expr $TO_CHOP + 1`
                START=`PWD= /bin/pwd`
                MFILE=`echo $START | cut -c${TO_CHOP}-`
                if [ "$MFILE" = "" ] ; then
                    MFILE=$DIR/Android.mk
                else
                    MFILE=$MFILE/$DIR/Android.mk
                fi
                MAKEFILE="$MAKEFILE $MFILE"
            else
                if [ "$DIR" = snod ]; then
                    ARGS="$ARGS snod"
                elif [ "$DIR" = showcommands ]; then
                    ARGS="$ARGS showcommands"
                elif [ "$DIR" = dist ]; then
                    ARGS="$ARGS dist"
                elif [ "$DIR" = incrementaljavac ]; then
                    ARGS="$ARGS incrementaljavac"
                else
                    echo "No Android.mk in $DIR."
                    return 1
                fi
            fi
        done
        ONE_SHOT_MAKEFILE="$MAKEFILE" make -C $T $DASH_ARGS all_modules $ARGS
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cproj()
{
    TOPFILE=build/core/envsetup.mk
    # We redirect cd to /dev/null in case it's aliased to
    # a command that prints something as a side-effect
    # (like pushd)
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            cd $T
            return
        fi
        cd .. > /dev/null
    done
    cd $HERE > /dev/null
    echo "can't find Android.mk"
}

function pid()
{
   local EXE="$1"
   if [ "$EXE" ] ; then
       local PID=`adb shell ps | fgrep $1 | sed -e 's/[^ ]* *\([0-9]*\).*/\1/'`
       echo "$PID"
   else
       echo "usage: pid name"
   fi
}

# systemstack - dump the current stack trace of all threads in the system process
# to the usual ANR traces file
function systemstack()
{
    adb shell echo '""' '>>' /data/anr/traces.txt && adb shell chmod 776 /data/anr/traces.txt && adb shell kill -3 $(pid system_server)
}

function gdbclient()
{
   local OUT_ROOT=$(get_abs_build_var PRODUCT_OUT)
   local OUT_SYMBOLS=$(get_abs_build_var TARGET_OUT_UNSTRIPPED)
   local OUT_SO_SYMBOLS=$(get_abs_build_var TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)
   local OUT_EXE_SYMBOLS=$(get_abs_build_var TARGET_OUT_EXECUTABLES_UNSTRIPPED)
   local PREBUILTS=$(get_abs_build_var ANDROID_PREBUILTS)
   if [ "$OUT_ROOT" -a "$PREBUILTS" ]; then
       local EXE="$1"
       if [ "$EXE" ] ; then
           EXE=$1
       else
           EXE="app_process"
       fi

       local PORT="$2"
       if [ "$PORT" ] ; then
           PORT=$2
       else
           PORT=":5039"
       fi

       local PID
       local PROG="$3"
       if [ "$PROG" ] ; then
           if [[ "$PROG" =~ ^[0-9]+$ ]] ; then
               PID="$3"
           else
               PID=`pid $3`
           fi
           adb forward "tcp$PORT" "tcp$PORT"
           adb shell gdbserver $PORT --attach $PID &
           sleep 2
       else
               echo ""
               echo "If you haven't done so already, do this first on the device:"
               echo "    gdbserver $PORT /system/bin/$EXE"
                   echo " or"
               echo "    gdbserver $PORT --attach $PID"
               echo ""
       fi

       echo >|"$OUT_ROOT/gdbclient.cmds" "set solib-absolute-prefix $OUT_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "set solib-search-path $OUT_SO_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "target remote $PORT"
       echo >>"$OUT_ROOT/gdbclient.cmds" ""

       arm-linux-androideabi-gdb -x "$OUT_ROOT/gdbclient.cmds" "$OUT_EXE_SYMBOLS/$EXE"
  else
       echo "Unable to determine build system output dir."
   fi

}

case `uname -s` in
    Darwin)
        function sgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.(c|h|cpp|S|java|xml|sh|mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        ;;
    *)
        function sgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.\(c\|h\|cpp\|S\|java\|xml\|sh\|mk\)' -print0 | xargs -0 grep --color -n "$@"
        }
        ;;
esac

function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o  -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function resgrep()
{
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
}

case `uname -s` in
    Darwin)
        function mgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*/(Makefile|Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o -type f -iregex '.*\.(c|h|cpp|S|java|xml)' -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
    *)
        function mgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
esac

function getprebuilt
{
    get_abs_build_var ANDROID_PREBUILTS
}

function tracedmdump()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi
    local prebuiltdir=$(getprebuilt)
    local KERNEL=$T/prebuilt/android-arm/kernel/vmlinux-qemu

    local TRACE=$1
    if [ ! "$TRACE" ] ; then
        echo "usage:  tracedmdump  tracename"
        return
    fi

    if [ ! -r "$KERNEL" ] ; then
        echo "Error: cannot find kernel: '$KERNEL'"
        return
    fi

    local BASETRACE=$(basename $TRACE)
    if [ "$BASETRACE" = "$TRACE" ] ; then
        TRACE=$ANDROID_PRODUCT_OUT/traces/$TRACE
    fi

    echo "post-processing traces..."
    rm -f $TRACE/qtrace.dexlist
    post_trace $TRACE
    if [ $? -ne 0 ]; then
        echo "***"
        echo "*** Error: malformed trace.  Did you remember to exit the emulator?"
        echo "***"
        return
    fi
    echo "generating dexlist output..."
    /bin/ls $ANDROID_PRODUCT_OUT/system/framework/*.jar $ANDROID_PRODUCT_OUT/system/app/*.apk $ANDROID_PRODUCT_OUT/data/app/*.apk 2>/dev/null | xargs dexlist > $TRACE/qtrace.dexlist
    echo "generating dmtrace data..."
    q2dm -r $ANDROID_PRODUCT_OUT/symbols $TRACE $KERNEL $TRACE/dmtrace || return
    echo "generating html file..."
    dmtracedump -h $TRACE/dmtrace >| $TRACE/dmtrace.html || return
    echo "done, see $TRACE/dmtrace.html for details"
    echo "or run:"
    echo "    traceview $TRACE/dmtrace"
}

# communicate with a running device or emulator, set up necessary state,
# and run the hat command.
function runhat()
{
    # process standard adb options
    local adbTarget=""
    if [ "$1" = "-d" -o "$1" = "-e" ]; then
        adbTarget=$1
        shift 1
    elif [ "$1" = "-s" ]; then
        adbTarget="$1 $2"
        shift 2
    fi
    local adbOptions=${adbTarget}
    echo adbOptions = ${adbOptions}

    # runhat options
    local targetPid=$1

    if [ "$targetPid" = "" ]; then
        echo "Usage: runhat [ -d | -e | -s serial ] target-pid"
        return
    fi

    # confirm hat is available
    if [ -z $(which hat) ]; then
        echo "hat is not available in this configuration."
        return
    fi

    # issue "am" command to cause the hprof dump
    local devFile=/sdcard/hprof-$targetPid
    echo "Poking $targetPid and waiting for data..."
    adb ${adbOptions} shell am dumpheap $targetPid $devFile
    echo "Press enter when logcat shows \"hprof: heap dump completed\""
    echo -n "> "
    read

    local localFile=/tmp/$$-hprof

    echo "Retrieving file $devFile..."
    adb ${adbOptions} pull $devFile $localFile

    adb ${adbOptions} shell rm $devFile

    echo "Running hat on $localFile"
    echo "View the output by pointing your browser at http://localhost:7000/"
    echo ""
    hat $localFile
}

function getbugreports()
{
    local reports=(`adb shell ls /sdcard/bugreports | tr -d '\r'`)

    if [ ! "$reports" ]; then
        echo "Could not locate any bugreports."
        return
    fi

    local report
    for report in ${reports[@]}
    do
        echo "/sdcard/bugreports/${report}"
        adb pull /sdcard/bugreports/${report} ${report}
        gunzip ${report}
    done
}

function startviewserver()
{
    local port=4939
    if [ $# -gt 0 ]; then
            port=$1
    fi
    adb shell service call window 1 i32 $port
}

function stopviewserver()
{
    adb shell service call window 2
}

function isviewserverstarted()
{
    adb shell service call window 3
}

function key_home()
{
    adb shell input keyevent 3
}

function key_back()
{
    adb shell input keyevent 4
}

function key_menu()
{
    adb shell input keyevent 82
}

function smoketest()
{
    if [ ! "$ANDROID_PRODUCT_OUT" ]; then
        echo "Couldn't locate output files.  Try running 'lunch' first." >&2
        return
    fi
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    (cd "$T" && mmm tests/SmokeTest) &&
      adb uninstall com.android.smoketest > /dev/null &&
      adb uninstall com.android.smoketest.tests > /dev/null &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTestApp.apk &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTest.apk &&
      adb shell am instrument -w com.android.smoketest.tests/android.test.InstrumentationTestRunner
}

# simple shortcut to the runtest command
function runtest()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    ("$T"/development/testrunner/runtest.py $@)
}

function godir () {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    cd $T/$pathname
}

# Force JAVA_HOME to point to java 1.6 if it isn't already set
function set_java_home() {
    if [ ! "$JAVA_HOME" ]; then
        case `uname -s` in
            Darwin)
                export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
                ;;
            *)
                export JAVA_HOME=/usr/lib/jvm/java-6-sun
                ;;
        esac
    fi
}

if [ "x$SHELL" != "x/bin/bash" ]; then
    case `ps -o command -p $$` in
        *bash*)
            ;;
        *)
            echo "WARNING: Only bash is supported, use of other shell would lead to erroneous results"
            ;;
    esac
fi

# Execute the contents of any vendorsetup.sh files we can find.
for f in `/bin/ls vendor/*/vendorsetup.sh vendor/*/*/vendorsetup.sh device/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f

addcompletions
initbuildspec
