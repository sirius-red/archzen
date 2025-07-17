#####################################################
## This is a self-generated script, don't edit it! ##
#####################################################

$cwd = $PWD.Path
$source = @{
	settings    = @{
		path = "${cwd}\resources\dotfiles\!.config\Code\User\settings.json"
		data = $null
	}
	keybindings = @{
		path = "${cwd}\resources\dotfiles\!.config\Code\User\keybindings.json"
		data = $null
	}
}
$target = @{
	settings    = @{
		path = "${env:APPDATA}\Code\User\settings.json"
		data = $null
	}
	keybindings = @{
		path = "${env:APPDATA}\Code\User\keybindings.json"
		data = $null
	}
}
$extensions = @(
	'SiriusRed.dev-essentials-pack'
	'miguelsolorio.fluent-icons'
	'streetsidesoftware.code-spell-checker-portuguese-brazilian'
	'be5invis.vscode-custom-css'
	'saoudrizwan.claude-dev'
	'starkweb-technologies.comment-code'
	'google.geminicodeassist'
	'Gerrnperl.outline-map'
	'TheHyDEProject.wallbash'
	'miguelsolorio.symbols'
)

# Install VS Code extensions
foreach ($ext in $extensions)
{
	code --install-extension $ext --force
}

# Apply VS Code settings
$source.settings.data = Get-Content -Path $source.settings.path | ConvertFrom-Json
$target.settings.data = Get-Content -Path $target.settings.path | ConvertFrom-Json
foreach ($key in $source.settings.data.PSObject.Properties.Name)
{
	if (-not $target.settings.data.PSObject.Properties.Name.Contains($key))
	{
		$target.settings.data | Add-Member -MemberType NoteProperty -Name $key -Value $source.settings.data.$key
	}
}
$target.settings.data | ConvertTo-Json -Depth 100 | Set-Content -Path $target.settings.path

# Load and parse keybindings (JSON array)
$source.keybindings.data = Get-Content -Raw -Path $source.keybindings.path | ConvertFrom-Json
$target.keybindings.data = Get-Content -Raw -Path $target.keybindings.path | ConvertFrom-Json

# Guarantees that both are arrays
if ($source.keybindings.data -isnot [System.Array])
{
	$source.keybindings.data = @($source.keybindings.data)
}
if ($target.keybindings.data -isnot [System.Array])
{
	$target.keybindings.data = @($target.keybindings.data)
}

# Merge without duplicating (based on key 'key' + 'Command')
$mergedKeybindings = @{}

foreach ($item in $source.keybindings.data + $target.keybindings.data)
{
	$id = "$($item.key)|$($item.command)"
	if (-not $mergedKeybindings.ContainsKey($id))
	{
		$mergedKeybindings[$id] = $item
	}
}

# Save as an array final
$mergedKeybindings.Values | ConvertTo-Json -Depth 100 | Set-Content -Path $target.keybindings.path
