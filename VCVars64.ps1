Param(
	[Parameter(Position=0)]
	[Switch]
	$Store,

	[Parameter(Position=1)]
	[ValidateSet('', '8.1', '10.0.10150.0', '10.0.10240.0', '10.0.10586.0')]
	[String]
	$VersionNumber
)

# ============================== FUNCTIONS ====================================

function Usage {
	#:usage
	Write-Host 'called usage...'
}

# ============================ MAIN ROUTINE ===================================

#:GetVSCommonToolsDir
$env:VS140COMNTOOLS = $null
foreach ($platformPath in ('', 'Wow6432Node\')) {
	foreach ($hive in ('HKLM', 'HKCU')) {
		$env:VS140COMNTOOLS = Get-ItemPropertyValue `
			-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VS7" `
			-Name '14.0'

		if ($env:VS140COMNTOOLS) {
			$env:VS140COMNTOOLS = "${env:VS140COMNTOOLS}Common7\Tools\"
			break
		}
	}
}

if (! $env:VS140COMNTOOLS) {
	#:error_no_VS140COMNTOOLSDIR
	Write-Error 'ERROR: Cannot determine the location of the VS Common Tools folder.'

	break
}

# Call ${env:VS140COMNTOOLS}VCVarsQueryRegistry.ps1 
& "$PSScriptRoot\VCVarsQueryRegistry.ps1" -Platforms '64bit' -Store:$Store -VersionNumber $VersionNumber

if (! $env:VSINSTALLDIR) {
	#:error_no_VSINSTALLDIR
	Write-Error 'ERROR: Cannot determine the location of the VS installation.'

	break
}

if (! $env:VCINSTALLDIR) {
	#:error_no_VCINSTALLDIR
	Write-Error 'ERROR: Cannot determine the location of the VC installation.'

	break
}

if (! $env:FrameworkDir64) {
	#:error_no_FrameworkDIR64
	Write-Error 'ERROR: Cannot determine the location of the .NET Framework 64bit installation.'

	break
}

if (! $env:FrameworkVersion64) {
	#:error_no_FrameworkVer64
	Write-Error 'ERROR: Cannot determine the version of the .NET Framework 64bit installation.'

	break
}

if (! $env:Framework40Version) {
	#:error_no_Framework40Version
	Write-Error 'ERROR: Cannot determine the .NET Framework 4.0 version.'

	break
}

$env:FrameworkDir = $env:FrameworkDir64
$env:FrameworkVersion = $env:FrameworkVersion64

if ($env:WindowsSDK_ExecutablePath_x64) {
	$env:Path = "${env:WindowsSDK_ExecutablePath_x64};${env:Path}"
}

# Set Windows SDK include/lib path
if ($env:WindowsSdkDir) {
	$env:PATH = "${env:WindowsSdkDir}bin\x64;${env:WindowsSdkDir}bin\x86;${env:PATH}"
}
if ($env:WindowsSdkDir) {
	$env:INCLUDE = `
		"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}shared;" + `
		"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}um;" + `
		"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}winrt;" + `
		"${env:INCLUDE}"
}
if ($env:WindowsSdkDir) {
	$env:LIB = "${env:WindowsSdkDir}lib\${env:WindowsSDKLibVersion}um\x64;${env:LIB}"
}
if ($env:WindowsSdkDir) {
	$env:LIBPATH = "${env:WindowsLibPath};${env:ExtensionSDKDir}\Microsoft.VCLibs\14.0\References\CommonConfiguration\neutral;${env:LIBPATH}"
}

# Set NETFXSDK include/lib path
if ($env:NETFXSDKDir) {
	$env:INCLUDE = "${env:NETFXSDKDir}include\um;${env:INCLUDE}"
	$env:LIB = "${env:NETFXSDKDir}lib\um\x64;${env:LIB}"
}

# Set UniversalCRT include/lib path, the default is the latest installed version.
if ($env:UCRTVersion) {
	$env:INCLUDE = "${env:UniversalCRTSdkDir}include\${env:UCRTVersion}\ucrt;${env:INCLUDE}"
	$env:LIB = "${env:UniversalCRTSdkDir}lib\${env:UCRTVersion}\ucrt\x64;${env:LIB}"
}

# PATH
# ----
if (Test-Path "${env:VSINSTALLDIR}Team Tools\Performance Tools\x64") {
	$env:PATH = "${env:VSINSTALLDIR}Team Tools\Performance Tools\x64;${env:VSINSTALLDIR}Team Tools\Performance Tools;${env:PATH}"
}

if (Test-Path "${env:ProgramFiles}\HTML Help Workshop") {
	$env:PATH = "${env:ProgramFiles}\HTML Help Workshop;${env:PATH}"
}
if (Test-Path "${env:ProgramFiles(x86)}\HTML Help Workshop") {
	$env:PATH = "${env:ProgramFiles(x86)}\HTML Help Workshop;${env:PATH}"
}
if (Test-Path "${env:VSINSTALLDIR}Common7\Tools") {
	$env:PATH = "${env:VSINSTALLDIR}Common7\Tools;${env:PATH}"
}
if (Test-Path "${env:VSINSTALLDIR}Common7\IDE") {
	$env:PATH = "${env:VSINSTALLDIR}Common7\IDE;${env:PATH}"
}
if (Test-Path "${env:VCINSTALLDIR}VCPackages") {
	$env:PATH = "${env:VCINSTALLDIR}VCPackages;${env:PATH}"
}
if (Test-Path "${env:FrameworkDir}\${env:Framework40Version}") {
	$env:PATH = "${env:FrameworkDir}\${env:Framework40Version};${env:PATH}"
}
if (Test-Path "${env:FrameworkDir}\${env:FrameworkVersion}") {
	$env:PATH = "${env:FrameworkDir}\${env:FrameworkVersion};${env:PATH}"
}
if (Test-Path "${env:VCINSTALLDIR}BIN\amd64") {
	$env:PATH = "${env:VCINSTALLDIR}BIN\amd64;${env:PATH}"
}

# Add path to MSBuild Binaries
if (Test-Path "${env:ProgramFiles}\MSBuild\14.0\bin\amd64") {
	$env:PATH = "${env:ProgramFiles}\MSBuild\14.0\bin\amd64;${env:PATH}"
}
if (Test-Path "${env:ProgramFiles(x86)}\MSBuild\14.0\bin\amd64") {
	$env:PATH = "${env:ProgramFiles(x86)}\MSBuild\14.0\bin\amd64;${env:PATH}"
}

if (Test-Path "${env:VSINSTALLDIR}Common7\IDE\CommonExtensions\Microsoft\TestWindow") {
	$env:PATH = "${env:VSINSTALLDIR}Common7\IDE\CommonExtensions\Microsoft\TestWindow;${env:PATH}"
}

# INCLUDE
# -------
if (Test-Path "${env:VCINSTALLDIR}ATLMFC\INCLUDE") {
	$env:INCLUDE = "${env:VCINSTALLDIR}ATLMFC\INCLUDE;${env:INCLUDE}"
}
if (Test-Path "${env:VCINSTALLDIR}INCLUDE") {
	$env:INCLUDE = "${env:VCINSTALLDIR}INCLUDE;${env:INCLUDE}"
}

# LIB
# ---
if ($Store) {
	#:setstorelib
	if (Test-Path "${env:VCINSTALLDIR}LIB\store\amd64") {
		$env:LIB = "${env:VCINSTALLDIR}LIB\store\amd64;${env:LIB}"
	}
} else {
	if (Test-Path "${env:VCINSTALLDIR}ATLMFC\LIB\amd64") {
		$env:LIB = "${env:VCINSTALLDIR}ATLMFC\LIB\amd64;${env:LIB}"
	}
	if (Test-Path "${env:VCINSTALLDIR}LIB\amd64") {
		$env:LIB = "${env:VCINSTALLDIR}LIB\amd64;${env:LIB}"
	}
}

#:setlibpath
# LIBPATH
# -------
if ($Store) {
	#:setstorelibpath
	if (Test-Path "${env:VCINSTALLDIR}LIB\store\amd64") {
		$env:LIBPATH = "${env:VCINSTALLDIR}LIB\store\amd64;${env:VCINSTALLDIR}LIB\store\references;${env:LIBPATH}"
	}
} else {
	if (Test-Path "${env:VCINSTALLDIR}ATLMFC\LIB\amd64") {
		$env:LIBPATH = "${env:VCINSTALLDIR}ATLMFC\LIB\amd64;${env:LIBPATH}"
	}
	if (Test-Path "${env:VCINSTALLDIR}LIB\amd64") {
		$env:LIBPATH = "${env:VCINSTALLDIR}LIB\amd64;${env:LIBPATH}"
	}
}
#:appendlibpath
if (Test-Path "${env:FrameworkDir}\${env:Framework40Version}") {
	$env:LIBPATH = "${env:FrameworkDir}\${env:Framework40Version};${env:LIBPATH}"
}
if (Test-Path "${env:FrameworkDir}\${env:FrameworkVersion}") {
	$env:LIBPATH = "${env:FrameworkDir}\${env:FrameworkVersion};${env:LIBPATH}"
}

$env:Platform = 'X64'
$env:CommandPromptType = 'Native'
