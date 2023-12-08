#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.ps1 275 2023-12-08 02:42:29Z rhubarb-geek-nz $
#

$GRADLE_VERSION = "7.6"
$ZIPFILE = "gradle-$GRADLE_VERSION-bin.zip"
$URL = "https://services.gradle.org/distributions/$ZIPFILE"
$SRCDIR = "src/gradle-$GRADLE_VERSION"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

dotnet tool restore

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

$path = "src"

If(!(test-path -PathType container $path))
{
	$Null = New-Item -ItemType Directory -Path $path

	Write-Host "$URL"

	Invoke-WebRequest -Uri "$URL" -OutFile "$ZIPFILE"

	Expand-Archive -LiteralPath "$ZIPFILE" -DestinationPath "$path"
}

@'
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="Gradle 7.6" Language="1033" Version="7.6" Manufacturer="gradle.org" UpgradeCode="F0AEB720-5434-4801-8BC1-4BA35A6B7818">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" Platform="x64" Description="Gradle build tool" Comments="Gradle 7.6" />
    <MediaTemplate EmbedCab="yes" />
    <Feature Id="ProductFeature" Title="setup" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
    <Upgrade Id="{F0AEB720-5434-4801-8BC1-4BA35A6B7818}">
      <UpgradeVersion Maximum="7.6" Property="OLDPRODUCTFOUND" OnlyDetect="no" IncludeMinimum="yes" IncludeMaximum="no" />
    </Upgrade>
    <InstallExecuteSequence>
      <RemoveExistingProducts After="InstallInitialize" />
    </InstallExecuteSequence>
    <UIRef Id="WixUI_Minimal" />
    <WixVariable Id="WixUILicenseRtf" Value="license.rtf" /> 
  </Product>
  <Fragment>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLDIR" Name="Gradle 7.6">
        </Directory>
      </Directory>
    </Directory>
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents">
      <Component Id="gradle.bat" Guid="*" Directory="INSTALLDIR" Win64="yes" >
        <File Id="gradle.bat" KeyPath="yes" />
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
'@ | dotnet dir2wxs -o "gradle.wxs" -s "$SRCDIR"

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

Get-Content "$SRCDIR\LICENSE" | dotnet txt2rtf "\fs20" > "license.rtf" 

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& "$ENV:WIX/bin/candle.exe" -nologo "gradle.wxs" -ext WixUtilExtension 

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& "$ENV:WIX/bin/light.exe" -nologo -cultures:null -out "gradle-$GRADLE_VERSION.msi" "gradle.wixobj" -ext WixUtilExtension -ext WixUIExtension

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& signtool sign /a /sha1 601A8B683F791E51F647D34AD102C38DA4DDB65F /fd SHA256 /t http://timestamp.digicert.com "gradle-$GRADLE_VERSION.msi"

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}
