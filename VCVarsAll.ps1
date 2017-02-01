Param (
	[Parameter(Position=0, Mandatory=$true)]
	[ValidateSet(
		'x86',
		'amd64',
		'x64',
		'arm',
		'x86_arm',
		'x86_amd64',
		'amd64_x86'
		)]
	[String]
	$Platform = 'x86',

	[Parameter(Position=1)]
	[Switch]
	$Store,

	[Parameter(Position=2)]
	[ValidateSet('', '8.1', '10.0.10150.0', '10.0.10240.0', '10.0.10586.0')]
	[String]
	$VersionNumber = '',

	[String]
	$VsInstallDir = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0'
)

$platformMap = @{
	'x86'		= 'VCVars32.ps1';
	'amd64'		= 'VCVars64.ps1';
	'x64'		= 'VCVars64.ps1';
	'arm'		= 'VCVarsArm.ps1';
	'x86_arm'	= 'x86_arm';
	'x86_amd64'	= 'x86_amd64';
	'amd64_x86'	= 'amd64_x86';
	'amd64_arm'	= 'amd64_arm';
}

# ============================ MAIN ROUTINE ===================================

if (Test-Path $VsInstallDir) {
	$vsInstallDir = $VsInstallDir
} elseif ($env:VCINSTALLDIR) {
	$vsInstallDir = Split-Path $env:VCINSTALLDIR
}
# Cehck for current path
#$vcInstallDir = Split-Path -Path (Get-Location)

# Use default install path
if (!$vsInstallDir -or !(Test-Path $vsInstallDir)) {
	Write-Error 'Visual Studio installation path not found.'
	break
}

if (Test-Path $vsInstallDir\common7\IDE\devenv.exe ) {
	# Call platform-specific setup script.
	$script = "$PSScriptRoot\$($platformMap[$Platform])"

	#:check_platform
	if (Test-Path $script) {
		& $script -Store:$Store -VersionNumber $VersionNumber
	} else {
		Write-Host "The specified configuration type is missing.  The tools for the"
		Write-host "echo configuration might not be installed."

		break
	}

	#:SetVisualStudioVersion
	$env:VisualStudioVersion = '14.0'
} elseif (! (Test-Path $vsInstallDir\common7\IDE\wdexpress.exe)) {
	#:setup_buildsku
	$progFiles = Split-Path $vsInstallDir
	if (! (Test-Path "$progFiles\Microsoft Visual C++ Build Tools\vcbuildtools.bat")) {
		Usage
	}

	#CALL "$progFiles\Microsoft Visual C++ Build Tools\vcbuildtools.bat" $Platform $VersionNumber
	
	Set-Location $PSScriptRoot
}

# ============================== FUNCTIONS ====================================

function Usage {
	echo 'Called Usage()...'
	break
}
