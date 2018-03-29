#!/bin/bash

# Your project (application) name here. (Does not include .xcodeproj)
NEW_APP_NAME="MyProject"
NEW_MOBILEPROVISION_NAME=""
NEW_MOBILEPROVISION_UUID=""
# Your Developmrnt Team ID here.
NEW_MOBILEPROVISION_TEAM_ID="XXXXXX"
NEW_CODE_SIGN_STYLE="Automatic"

ROOT_OBJECT_UUID=`/usr/libexec/PlistBuddy -c "Print rootObject" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
#echo ROOT_OBJECT_UUID=${ROOT_OBJECT_UUID}

# buildConfigurationList UUID
TARGET_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${ROOT_OBJECT_UUID}:targets:0" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
#echo TARGET_UUID=${TARGET_UUID}

# Configuration UUID
BUILD_CONFIGURATION_LIST_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${TARGET_UUID}:buildConfigurationList" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
#echo BUILD_CONFIGURATION_LIST_UUID=${BUILD_CONFIGURATION_LIST_UUID}

# Configuration UUID
BUILD_CONFIGURATION_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_LIST_UUID}:buildConfigurations:0" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
#echo BUILD_CONFIGURATION_UUID=${BUILD_CONFIGURATION_UUID}

# Mobile Provision Team ID
PRODUCT_BUNDLE_IDENTIFIER=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:PRODUCT_BUNDLE_IDENTIFIER" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
if [ $? -ne 0 ]; then
  INFOPLIST_FILE=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:INFOPLIST_FILE" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
  #echo INFOPLIST_FILE=${INFOPLIST_FILE}
  PRODUCT_BUNDLE_IDENTIFIER=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${INFOPLIST_FILE}" 2>/dev/null`
  if [ -z "${PRODUCT_BUNDLE_IDENTIFIER}" ]; then
    echo "Failed to get CFBundleIdentifier."
    exit -1
  fi
fi
#echo PRODUCT_BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER}
BUNDLE_SHORT_VERSION_STRING=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${NEW_APP_NAME}/Info.plist"`
#echo BUNDLE_SHORT_VERSION_STRING=${BUNDLE_SHORT_VERSION_STRING}

PROVISIONING_STYLE=`/usr/libexec/PlistBuddy -c "Print objects:${ROOT_OBJECT_UUID}:attributes:TargetAttributes:${TARGET_UUID}:ProvisioningStyle" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
if [ $? -ne 0 ]; then
  PROVISIONING_STYLE="UNSET"
fi
#echo PROVISIONING_STYLE=${PROVISIONING_STYLE}
if [ "${PROVISIONING_STYLE}" = "Manual" ]; then
  /usr/libexec/PlistBuddy -c "Set objects:${ROOT_OBJECT_UUID}:attributes:TargetAttributes:${TARGET_UUID}:ProvisioningStyle Automatic" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
  if [ $? -ne 0 ]; then
    echo "Could not set ProvisioningStyle of Xcode Project to Automatic."
    exit -1
  else
    echo "Succeeded to set ProvisioningStyle of Xcode Project to Automatic."
  fi
fi

# Process App, AppTests, AppUITests (Targets)
TARGETS=`/usr/libexec/PlistBuddy -c "Print objects:${ROOT_OBJECT_UUID}:targets" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" | xargs | sed -e 's/^Array { \(.*\) }$/\1/g'`
#echo TARGETS=${TARGETS}

for TARGET_UUID in ${TARGETS}; do
  #TARGET_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${ROOT_OBJECT_UUID}:targets:${profile_no}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
  #echo TARGET_UUID=${TARGET_UUID}
  if [ ! -z "${TARGET_UUID}" ]; then
    PRODUCT_TYPE=`/usr/libexec/PlistBuddy -c "Print objects:${TARGET_UUID}:productType" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
    #echo PRODUCT_TYPE=${PRODUCT_TYPE}
    if [ "${PRODUCT_TYPE}" = "com.apple.product-type.application" ]; then
      BUILD_CONFIGURATION_LIST_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${TARGET_UUID}:buildConfigurationList" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
      #echo BUILD_CONFIGURATION_LIST_UUID=${BUILD_CONFIGURATION_LIST_UUID}
      BUILD_CONFIGURATIONS=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_LIST_UUID}:buildConfigurations" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null | xargs | sed -e 's/^Array { \(.*\) }$/\1/g'`
      #echo "BUILD_CONFIGURATIONS=${BUILD_CONFIGURATIONS}"
      # Release, Debug, AdHoc
      for BUILD_CONFIGURATION_UUID in ${BUILD_CONFIGURATIONS}; do
        #BUILD_CONFIGURATION_UUID=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_LIST_UUID}:buildConfigurations:${configuration_no}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
        #echo BUILD_CONFIGURATION_UUID=${BUILD_CONFIGURATION_UUID}
        if [ ! -z "${BUILD_CONFIGURATION_UUID}" ]; then
          BUILD_CONFIGURATION_NAME=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:name" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
          #echo BUILD_CONFIGURATION_NAME=${BUILD_CONFIGURATION_NAME}
          # When Automatic signing always "iPhone Developer"
          #if [ "$BUILD_CONFIGURATION_NAME" = "Debug" ]; then
            NEW_CODE_SIGN_IDENTITY="iPhone Developer"
          #else
          #  NEW_CODE_SIGN_IDENTITY="iPhone Distribution"
          #fi
          #BUILD_SETTINGS=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"`
          #echo BUILD_SETTINGS=${BUILD_SETTINGS}
          OLD_DEVELOPMENT_TEAM=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:DEVELOPMENT_TEAM" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
          if [ $? -ne 0 ]; then
            OLD_DEVELOPMENT_TEAM="UNSET"
          fi
          #echo OLD_DEVELOPMENT_TEAM=${OLD_DEVELOPMENT_TEAM}
          method=Set
          dataType=
          if [ "${OLD_DEVELOPMENT_TEAM}" = "UNSET" ]; then
            method=Add
            dataType=String
          fi
          /usr/libexec/PlistBuddy -c "${method} objects:${BUILD_CONFIGURATION_UUID}:buildSettings:DEVELOPMENT_TEAM ${dataType} ${NEW_MOBILEPROVISION_TEAM_ID}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
          if [ $? -ne 0 ]; then
            echo "Failed to change Developer Team ID of Xcode Project."
            exit -1
          else
            echo "Succeeded to change Developer Team ID of Xcode Project."
          fi

          OLD_CODE_SIGN_STYLE=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:CODE_SIGN_STYLE" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
          if [ $? -ne 0 ]; then
            OLD_CODE_SIGN_STYLE="UNSET"
          fi
          method=Set
          dataType=
          if [ "${OLD_CODE_SIGN_STYLE}" = "UNSET" ]; then
            method=Add
            dataType=String
          fi
          /usr/libexec/PlistBuddy -c "${method} objects:${BUILD_CONFIGURATION_UUID}:buildSettings:CODE_SIGN_STYLE ${dataType} ${NEW_CODE_SIGN_STYLE}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
          if [ $? -ne 0 ]; then
            echo "Failed to change CODE_SIGN_STYLE of Xcode Project." > build_ios_error.txt
          else
            echo "Succeeded to change CODE_SIGN_STYLE of Xcode Project."
          fi

          OLD_CODE_SIGN_IDENTITY=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:CODE_SIGN_IDENTITY[sdk=iphoneos*]" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
          if [ $? -ne 0 ]; then
            OLD_CODE_SIGN_IDENTITY="UNSET"
          fi
          method=Set
          dataType=
          if [ "${OLD_CODE_SIGN_IDENTITY}" = "UNSET" ]; then
            method=Add
            dataType=String
          fi
          /usr/libexec/PlistBuddy -c "${method} objects:${BUILD_CONFIGURATION_UUID}:buildSettings:CODE_SIGN_IDENTITY[sdk=iphoneos*] ${dataType} ${NEW_CODE_SIGN_IDENTITY}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
          if [ $? -ne 0 ]; then
            echo "Failed to change CODE_SIGN_IDENTITY of Xcode Project."
          else
            echo "Succeeded to change CODE_SIGN_IDENTITY of Xcode Project."
          fi

          OLD_PROVISIONING_PROFILE=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:PROVISIONING_PROFILE" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
          if [ $? -ne 0 ]; then
            OLD_PROVISIONING_PROFILE="UNSET"
          fi
          #echo OLD_PROVISIONING_PROFILE=${OLD_PROVISIONING_PROFILE}
          if [ "${OLD_PROVISIONING_PROFILE}" != "${NEW_MOBILEPROVISION_UUID}" ]; then
            method=Set
            dataType=
            if [ "${OLD_PROVISIONING_PROFILE}" = "UNSET" ]; then
              method=Add
              dataType=String
            fi
            /usr/libexec/PlistBuddy -c "${method} objects:${BUILD_CONFIGURATION_UUID}:buildSettings:PROVISIONING_PROFILE ${dataType} ${NEW_MOBILEPROVISION_UUID}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
            if [ $? -ne 0 ]; then
              echo "Failed to change PROVISIONING_PROFILE of Xcode Project."
              exit -1
            else
              echo "Succeeded to change PROVISIONING_PROFILE of Xcode Project."
            fi
          fi

          OLD_PROVISIONING_PROFILE_SPECIFIER=`/usr/libexec/PlistBuddy -c "Print objects:${BUILD_CONFIGURATION_UUID}:buildSettings:PROVISIONING_PROFILE_SPECIFIER" "${NEW_APP_NAME}.xcodeproj/project.pbxproj" 2>/dev/null`
          if [ $? -ne 0 ]; then
            OLD_PROVISIONING_PROFILE_SPECIFIER="UNSET"
          fi
          #echo OLD_PROVISIONING_PROFILE_SPECIFIER=${OLD_PROVISIONING_PROFILE_SPECIFIER}
          if [ "${OLD_PROVISIONING_PROFILE_SPECIFIER}" != "${NEW_MOBILEPROVISION_NAME}" ]; then
            method=Set
            dataType=
            if [ "${OLD_PROVISIONING_PROFILE_SPECIFIER}" = "UNSET" ]; then
              method=Add
              dataType=String
            fi
            /usr/libexec/PlistBuddy -c "${method} objects:${BUILD_CONFIGURATION_UUID}:buildSettings:PROVISIONING_PROFILE_SPECIFIER ${dataType} ${NEW_MOBILEPROVISION_NAME}" "${NEW_APP_NAME}.xcodeproj/project.pbxproj"
            if [ $? -ne 0 ]; then
              echo "Failed to change PROVISIONING_PROFILE_SPECIFIER of Xcode Project."
              exit -1
            else
              echo "Succeeded to change PROVISIONING_PROFILE_SPECIFIER of Xcode Project."
            fi
          fi
        fi
      done
    fi
  fi
done
