Param (
	[Parameter(Position=0)]
	[ValidateSet('32bit', '64bit')]
	[String[]]
	$Platforms,

	[Parameter(Position=1)]
	[Switch]
	$Store,

	[Parameter(Position=2)]
	[ValidateSet('', '8.1', '10.0.10150.0', '10.0.10240.0', '10.0.10586.0')]
	[String]
	$VersionNumber
)

# ============================== FUNCTIONS ====================================

#:GetWindowsSdkDir
function GetWindowsSdkDir {
	$env:WindowsSdkDir = $null
	$env:WindowsLibPath = $null
	$env:WindowsSDKVersion = $null
	$env:WindowsSDKLibVersion = 'winv6.3\'

	# If the user specifically requested a Windows SDK Version, then attempt to use it.
	if ('8.1' -eq $VersionNumber) {
		$succeeded = GetWin81SdkDir
		if (! $succeeded) {
			#:GetWin81SdkDirError
			Write-Error "Windows SDK 8.1 : '${env:WindowsSdkDir}include'"
			Set-Location "${env:WindowsSdkDir}include"
		}

		return # $succeeded
	}
	if ($VersionNumber) {
		$succeeded = GetWin10SdkDir
		if (! $succeeded) {
			#:GetWin10SdkDirError
			Write-Error "Windows SDK $VersionNumber : '${env:WindowsSdkDir}include\$VersionNumber\um'"
			Set-Location "${env:WindowsSdkDir}include\$VersionNumber\um"
		}

		return # $succeeded
	}

	# If a specific SDK was not requested, first check for the latest Windows 10 SDK
	# and if not found, fall back to the 8.1 SDK.
	if (! $env:WindowsSdkDir) {
		<#return #> $succeeded = GetWin10SdkDir
	}
	if (! $env:WindowsSdkDir) {
		<#return #> $succeeded = GetWin81SdkDir
	}

	return # $true
}

#:GetWin10SdkDir
function GetWin10SdkDir {
	$success = $false
	foreach ($hive in ('HKLM', 'HKCU')) {
		foreach ($platformFolder in ('Wow6432Node\', '')) {
			$keyPath = [String]::Format('SOFTWARE\{0}\Microsoft\Microsoft SDKs\Windows\v10.0', $platformFolder)
			$env:WindowsSdkDir = Get-ItemPropertyValue -Path "${Hive}:\${keyPath}" -Name 'InstallationFolder' -ErrorAction SilentlyContinue

			$success = GetWin10SdkDirHelper
			if ($success) {
				return # $true
			}
		}
	}

	return # $false
}

function GetWin10SdkDirHelper {
	# Get Windows 10 SDK version number
	if ($env:WindowsSdkDir) {
		foreach ($version in Get-ChildItem $env:WindowsSdkDir\include -Name -Include '10.*' | Sort-Object -Descending) {
			if (Test-Path "${env:WindowsSdkDir}\include\${version}\um\Windows.h") {
				if ($version -eq $VersionNumber -or !$VersionNumber) {
					$env:WindowsSDKVersion = "$version\"
					break
				}
			}
		}
	}

	$WindowsSDKNotFound = $false
	if ($VersionNumber) {
		# if the user specified a version of the SDK and it wasn't found, then use the
		# user-specified version to set environment variables.
		if (! "$VersionNumber\" -ne $env:WindowsSDKVersion) {
			$env:WindowsSDKVersion = "$VersionNumber\"
			$WindowsSDKNotFound = $true
		}
	} else {
		# if no full Windows 10 SDKs were found, unset WindowsSDKDir and exit with error.
		if ('\' -eq $env:WindowsSDKVersion) {
			$WindowsSDKNotFound = $true
			$env:WindowsSdkDir = $null
		}
	}

	if ('\' -ne $env:WindowsSDKVersion) {
		$env:WindowsSDKLibVersion = $env:WindowsSDKVersion
	}
	if ($env:WindowsSdkDir)  {
		$env:WindowsLibPath = "${env:WindowsSdkDir}UnionMetadata;${env:WindowsSdkDir}References"
	}

	return ! $WindowsSDKNotFound
}

#:GetWin81SdkDir
function GetWin81SdkDir {
	$success = $false
	foreach ($hive in ('HKLM', 'HKCU')) {
		foreach ($platformFolder in ('Wow6432Node\', '')) {
			$keyPath = [String]::Format('SOFTWARE\{0}\Microsoft\Microsoft SDKs\Windows\v8.1', $platformFolder)
			$env:WindowsSdkDir = Get-ItemPropertyValue -ErrorAction SilentlyContinue -Path "${Hive}:\${keyPath}" -Name 'InstallationFolder'

			$success = GetWin81SdkDirHelper
			if ($success) {
				return $true
			}
		}
	}

	return $false
}

#:GetWin81SdkDirHelper
function GetWin81SdkDirHelper {
	# Get Windows 8.1 SDK installed folder, if Windows 10 SDK is not installed or user specified to use 8.1 SDK
	$env:WindowsSDKLibVersion = 'winv6.3\'
	$env:WindowsLibPath = $null

	if (! $env:WindowsLibPath) {
		$env:WindowsLibPath = "${env:WindowsSdkDir}References\CommonConfiguration\Neutral"
	}
	if (! $env:WindowsLibPath) {
		return $false
	}

	return $true
}

function GetWindowsSdkExecutablePath {
	$env:WindowsSDK_ExecutablePath_x86 = $null
	$env:WindowsSDK_ExecutablePath_x64 = $null
	$env:NETFXSDKDir = $null

	foreach ($platformFolder in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			if (GetWindowsSdkExePathHelper -Hive "${hive}:\SOFTWARE\${platformFolder}") {
				return #$true
			}
		}
	}

	#return $false #SURE?
}

#:GetWindowsSdkExePathHelper
function GetWindowsSdkExePathHelper {
	Param(
		[String]
		$Hive
	)

	# Get .NET 4.6.1 SDK tools and libs include path
	$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools-x86"
	$env:WindowsSDK_ExecutablePath_x86 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'

	$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools-x64"
	$env:WindowsSDK_ExecutablePath_x64 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'

	$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6.1"
	$env:NETFXSDKDir = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name KitsInstallationFolder

	# Falls back to get .NET 4.6 SDK tools and libs include path
	if (! $env:NETFXSDKDir) {
		$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools-x86"
		$env:WindowsSDK_ExecutablePath_x86 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'
	}

	if (! $env:NETFXSDKDir) {
		$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools-x64"
		$env:WindowsSDK_ExecutablePath_x64 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'
	}

	if (! $env:NETFXSDKDir) {
		$path = $Hive + "Microsoft\Microsoft SDKs\NETFXSDK\4.6"
		$env:NETFXSDKDir = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'KitsInstallationFolder'
	}

	# Falls back to use .NET 4.5.1 SDK
	if (! $env:WindowsSDK_ExecutablePath_x86) {
		$path = $Hive + "Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools-x86"
		$env:WindowsSDK_ExecutablePath_x86 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'
	}

	if (! $env:WindowsSDK_ExecutablePath_x64) {
		$path = $Hive + "Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools-x64"
		$env:WindowsSDK_ExecutablePath_x64 = Get-ItemPropertyValue -Path $path -ErrorAction SilentlyContinue -Name 'InstallationFolder'
	}

	# Return false if both x86 and x64 are null.
	return $env:WindowsSDK_ExecutablePath_x86 -or $env:WindowsSDK_ExecutablePath_x64
}

#:GetExtensionSkdDir
function GetExtensionSdkDir {
	$env:ExtensionSdkDir = $null

	# Windows 8.1 Extension SDK
	if (Test-Path "${env:ProgramFiles}\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\Microsoft.VCLibs\14.0\SDKManifest.xml") {
		$env:ExtensionSdkDir = "${env:ProgramFiles}\Microsoft SDKs\Windows\v8.1\ExtensionSDKs"
	}
	if (Test-Path "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\Microsoft.VCLibs\14.0\SDKManifest.xml") {
		$env:ExtensionSdkDir = "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v8.1\ExtensionSDKs"
	}

	# Windows 10 Extension SDK, this will replace the Windows 8.1 "ExtensionSdkDir" if Windows 10 SDK is installed
	if (Test-Path "${env:ProgramFiles}\Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs\14.0\SDKManifest.xml") {
		$env:ExtensionSdkDir = "${env:ProgramFiles}\Microsoft SDKs\Windows Kits\10\ExtensionSDKs"
	}
	if (Test-Path "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs\14.0\SDKManifest.xml") {
		$env:ExtensionSdkDir = "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows Kits\10\ExtensionSDKs"
	}

	#return !! $env:ExtensionSdkDir
}

#:GetVSInstallDir
function GetVSInstallDir {
	$env:VSINSTALLDIR = $null

	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:VSINSTALLDIR = Get-ItemPropertyValue -Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VS7" -Name '14.0'

			if ($env:VSINSTALLDIR) {
				return #$true
			}
		}
	}

	#return $false #SURE?
}

#:GetVCInstallDir
function GetVCInstallDir {
	$env:VCINSTALLDIR = $null

	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:VCINSTALLDIR = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VC7" `
				-Name '14.0' `
				-ErrorAction SilentlyContinue

			if ($env:VCINSTALLDIR) {
				return #$true
			}
		}
	}

	#return $false #SURE?
}

#:GetFSharpInstallDir
function GetFSharpInstallDir {
	$env:FSHARPINSTALLDIR = $null

	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:FSHARPINSTALLDIR = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\14.0\Setup\F#" `
				-Name 'ProductDir' `
				-ErrorAction SilentlyContinue

			if ($env:FSHARPINSTALLDIR) {
				return #$true
			}
		}
	}

	#return $false #SURE?
}

#:GetUniversalCRTSdkDir
function GetUniversalCRTSdkDir {
	foreach ($platformPath in ('Wow6432Node\', '')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:UniversalCRTSdkDir = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\Windows Kits\Installed Roots" `
				-Name 'KitsRoot10' `
				-ErrorAction SilentlyContinue

			if (! $env:UniversalCRTSdkDir) {
				continue
			}

			# Select input UCRT version, or default to highest available.
			foreach($version in (Get-ChildItem $env:UniversalCRTSdkDir\include -Name -Include '10.*' | Sort-Object -Descending)) {
				if ($version -eq $VersionNumber) {
					$env:UCRTVersion = $version
					return # $true
				} elseif (! $VersionNumber) {
					$env:UCRTVersion = $version
					return # $true
				}
			}
		}
	}

#	return $false #SURE?
}

#:GetFrameworkDir32
function GetFrameworkDir32 {
	$env:FrameworkDir32 = $null
	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:FrameworkDIR32 = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VC7" `
				-Name 'FrameworkDir32' `
				-ErrorAction SilentlyContinue

			if ($env:FrameworkDIR32) {
				return # $true
			}
		}
	}

	#return $false #SURE?
}

#:GetFrameworkDir64
function GetFrameworkDir64 {
	$env:FrameworkDir64 = $null
	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:FrameworkDIR64 = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VC7" `
				-Name 'FrameworkDir64' `
				-ErrorAction SilentlyContinue

			if ($env:FrameworkDIR64) {
				return # $true
			}
		}
	}

	return # $false #SURE?
}

#:GetFrameworkVer32
function GetFrameworkVer32 {
	$env:FrameworkVersion32 = $null

	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:FrameworkVersion32 = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VC7" `
				-Name 'FrameworkVer32' `
				-ErrorAction SilentlyContinue

			if ($env:FrameworkVersion32) {
				return # $true
			}
		}
	}

	return # $false
}

#:GetFrameworkVer64
function GetFrameworkVer64 {
	$env:FrameworkVersion64 = $null

	foreach ($platformPath in ('', 'Wow6432Node\')) {
		foreach ($hive in ('HKLM', 'HKCU')) {
			$env:FrameworkVersion64 = Get-ItemPropertyValue `
				-Path "${hive}:\SOFTWARE\${platformPath}\Microsoft\VisualStudio\SxS\VC7" `
				-Name 'FrameworkVer64' `
				-ErrorAction SilentlyContinue

			if ($env:FrameworkVersion64) {
				return # $true
			}
		}
	}

	return # $false
}

# ============================ MAIN ROUTINE ===================================
GetWindowsSdkDir

GetWindowsSdkExecutablePath

GetExtensionSdkDir

GetVSInstallDir

GetVCInstallDir

GetFSharpInstallDir

GetUniversalCRTSdkDir

if (2 -eq $Platforms.Count -or '64bit' -eq $Platforms[0]) {
	GetFrameworkDir64
	GetFrameworkVer64
} elseif('32bit' -eq $Platforms[0]) {
	GetFrameworkDir32
	GetFrameworkVer32
}

$env:Framework40Version = 'v4.0'

# -----------------------------------------------------------------------
# Used by MsBuild to determine where to look in the registry for VCTargetsPath
# -----------------------------------------------------------------------
$env:VisualStudioVersion = '14.0'
