#####################################################
## This is a self-generated script, don't edit it! ##
#####################################################

$source = @{
	settings    = @{
		path = "${PSScriptRoot}\resources\dotfiles\!.config\Code\User\settings.json"
		data = $null
	}
	keybindings = @{
		path = "${PSScriptRoot}\resources\dotfiles\!.config\Code\User\keybindings.json"
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
	SiriusRed.dev-essentials-pack
	miguelsolorio.fluent-icons
	streetsidesoftware.code-spell-checker-portuguese-brazilian
	be5invis.vscode-custom-css
	saoudrizwan.claude-dev
	starkweb-technologies.comment-code
	google.geminicodeassist
	TheHyDEProject.wallbash
	miguelsolorio.symbolsn)

# Install VS Code extensions
foreach ($ext in $extensions)
{
	code --install-extension $ext --force
}

# Apply VS Code settings
$source.settings.data = Get-Content -Path $source.settings.path | ConvertFrom-Json
$target.settings.data = Get-Content -Path $target.settings.path | ConvertFrom-Json
$target.settings.data = $source.settings.data + $target.settings.data | Select-Object -Unique
$target.settings.data | ConvertTo-Json -Depth 100 | Set-Content -Path $target.settings.path

# Apply VS Code keybindings
$source.keybindings.data = Get-Content -Path $source.keybindings.path | ConvertFrom-Json
$target.keybindings.data = Get-Content -Path $target.keybindings.path | ConvertFrom-Json
$target.keybindings.data = $source.keybindings.data + $target.keybindings.data | Select-Object -Unique
$target.keybindings.data | ConvertTo-Json -Depth 100 | Set-Content -Path $target.keybindings.path
