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
	echo 'called Usage() ...'
}

# ============================ MAIN ROUTINE ===================================

#:GetVSCommonToolsDir
$env:VS140COMNTOOLS = $null
foreach ($platformPath in ('', 'Wow6432Node\')) {
	foreach($hive in ('HKLM', 'HKCU')) {
		$env:VS140COMNTOOLS = Get-ItemPropertyValue `
			-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VS7" `
			-Name '14.0' `
			-ErrorAction SilentlyContinue

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

# Call "${env:VS140COMNTOOLS}VCVarsQueryRegistry.ps1"
& "$PSScriptRoot\VCVarsQueryRegistry.ps1" -Platforms '32bit' -Store:$Store -VersionNumber $VersionNumber

if (! $env:VSINSTALLDIR) {
	# :error_no_VSINSTALLDIR
	Write-Error 'ERROR: Cannot determine the location of the VS installation.'

	break
}

if (! $env:VCINSTALLDIR) {
	# :error_no_VCINSTALLDIR
	Write-Error 'ERROR: Cannot determine the location of the VC installation.'

	break
}

if (! $env:FrameworkDir32) {
	# :error_no_FrameworkDIR32
	Write-Error 'ERROR: Cannot determine the location of the .NET Framework 32bit installation.'

	break
}

if (! $env:FrameworkVersion32) {
	# :error_no_FrameworkVer32
	Write-Error 'ERROR: Cannot determine the version of the .NET Framework 32bit installation.'

	break
}

if (! $env:Framework40Version) {
	# :error_no_Framework40Version
	Write-Error 'ERROR: Cannot determine the .NET Framework 4.0 version.'

	break
}

$env:FrameworkDir = $env:FrameworkDir32
$env:FrameworkVersion = $env:FrameworkVersion32

if ($env:WindowsSDK_ExecutablePath_x86) {
	$env:Path = "${env:WindowsSDK_ExecutablePath_x86};${env:Path}"
}

# Set Windows SDK include/lib path
if ($env:WindowsSdkDir) {
	$env:Path = "${env:WindowsSdkDir}bin\x86;${env:Path}"
	$env:INCLUDE =	"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}shared;" +`
					"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}um;" +`
					"${env:WindowsSdkDir}include\${env:WindowsSDKVersion}winrt;" +`
					"$env:INCLUDE"
	$env:LIB = "${env:WindowsSdkDir}lib\${env:WindowsSDKLibVersion}um\x86;${env:LIB}"
	$env:LIBPATH =	"${env:WindowsLibPath};" +`
					"${env:ExtensionSDKDir}\Microsoft.VCLibs\14.0\References\CommonConfiguration\neutral;" +`
					"${env:LIBPATH}"
}

# Set NETFXSDK include/lib path
if ($env:NETFXSDKDir) {
	$env:INCLUDE ="${env:NETFXSDKDir}include\um;${env:INCLUDE}"
	$env:LIB = "${env:NETFXSDKDir}lib\um\x86;${env:LIB}"
}

# Set UniversalCRT include/lib path, the default is the latest installed version.
if ($env:UCRTVersion) {
	$env:INCLUDE = "${env:UniversalCRTSdkDir}include\${env:UCRTVersion}\ucrt;${env:INCLUDE}"
	$env:LIB = "${env:UniversalCRTSdkDir}lib\${env:UCRTVersion}\ucrt\x86;${env:LIB}"
}

# Root of Visual Studio IDE installed files.
$env:DevEnvDir = "${env:VSINSTALLDIR}Common7\IDE\"

# PATH
# ----
if (Test-Path "${env:VSINSTALLDIR}Team Tools\Performance Tools") {
	$env:PATH = "${env:VSINSTALLDIR}Team Tools\Performance Tools;${env:PATH}"
}

if (Test-Path "${env:ProgramFiles(x86)}\HTML Help Workshop") {
	$env:PATH = "${env:ProgramFiles(x86)}\HTML Help Workshop;${env:PATH}"
}

if (Test-Path "${env:VCINSTALLDIR}VCPackages") {
	$env:PATH = "${env:VCINSTALLDIR}VCPackages;${env:PATH}"
}

if (Test-Path "${env:FrameworkDir}${env:Framework40Version}") {
	$env:PATH = "${env:FrameworkDir}${env:Framework40Version};${env:PATH}"
}

if (Test-Path "${env:FrameworkDir}${env:FrameworkVersion}") {
	$env:PATH = "${env:FrameworkDir}${env:FrameworkVersion};${env:PATH}"
}

if (Test-Path "${env:VSINSTALLDIR}Common7\Tools") {
	$env:PATH = "${env:VSINSTALLDIR}Common7\Tools;${env:PATH}"
}

if (Test-Path "${env:VCINSTALLDIR}BIN") {
	$env:PATH = "${env:VCINSTALLDIR}BIN;${env:PATH}"
}

$env:PATH = "${env:DevEnvDir};${env:PATH}"

# Add path to MSBuild Binaries
if (Test-Path "${env:ProgramFiles}\MSBuild\14.0\bin") {
	$env:PATH = "${env:ProgramFiles}\MSBuild\14.0\bin;${env:PATH}"
}
if (Test-Path "${env:ProgramFiles(x86)}\MSBuild\14.0\bin" ) {
	$env:PATH = "${env:ProgramFiles(x86)}\MSBuild\14.0\bin;${env:PATH}"
}

if (Test-Path "${env:VSINSTALLDIR}VSTSDB\Deploy") {
	$env:PATH = "${env:VSINSTALLDIR}VSTSDB\Deploy;${env:PATH}"
}

if ($env:FSHARPINSTALLDIR) {
	$env:PATH = "${env:FSHARPINSTALLDIR};${env:PATH}"
}

if (Test-Path "${env:DevEnvDir}CommonExtensions\Microsoft\TestWindow") {
	$env:PATH = "${env:DevEnvDir}CommonExtensions\Microsoft\TestWindow;${env:PATH}"
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
	if (Test-Path "${env:VCINSTALLDIR}LIB\store") {
		$env:LIB = "${env:VCINSTALLDIR}LIB\store;${env:LIB}"
	}
} else {
	if (Test-Path "${env:VCINSTALLDIR}ATLMFC\LIB") {
		$env:LIB = "${env:VCINSTALLDIR}ATLMFC\LIB;${env:LIB}"
	}
	if (Test-Path "${env:VCINSTALLDIR}LIB") {
		$env:LIB = "${env:VCINSTALLDIR}LIB;${env:LIB}"
	}
}

#:setlibpath
# LIBPATH
# -------
if ($Store) {
	#:setstorelibpath
	if (Test-Path "${env:VCINSTALLDIR}LIB\store") {
		$env:LIBPATH = "${env:VCINSTALLDIR}LIB\store;${env:LIBPATH}"
	}
} else {
	if (Test-Path "${env:VCINSTALLDIR}ATLMFC\LIB") {
		$env:LIBPATH = "${env:VCINSTALLDIR}ATLMFC\LIB;${env:LIBPATH}"
	}

	if (Test-Path "${env:VCINSTALLDIR}LIB") {
		$env:LIBPATH = "${env:VCINSTALLDIR}LIB;${env:LIBPATH}"
	}
}

#:appendlibpath
if (Test-Path "${env:FrameworkDir}${env:Framework40Version}") {
	$env:LIBPATH = "${env:FrameworkDir}${env:Framework40Version};${env:LIBPATH}"
}
$env:LIBPATH = "${env:FrameworkDir}${env:FrameworkVersion};${env:LIBPATH}"
