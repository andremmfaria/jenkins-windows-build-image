FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019
LABEL MAINTAINER="Andre Faria <andremarcalfaria@gmail.com>"

# Change default shell to CMD
SHELL ["cmd", "/S", "/C"]

# Install chocolatey
RUN powershell -Command \ 
    Set-ExecutionPolicy Bypass -Scope Process -Force ; \
    Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install packages
RUN powershell -Command \
    choco install -y git jdk8 openssh docker-cli              

# Configure openssh
RUN powershell -Command \
    $previousPath = $PWD.Path ; \
    $opensshPath = \"C:\Program Files\OpenSSH-Win64\" ; \
    $path = [System.Environment]::GetEnvironmentVariable(\"PATH\", \"Machine\") ; \
    [System.Environment]::SetEnvironmentVariable(\"PATH\", $path + \";$opensshPath;\", \"Machine\") ; \
    New-Item -Path $env:ProgramData\ssh -ItemType Directory >> temp ; \
    Set-Location -Path \"$opensshPath\" ; \
    Copy-Item -Path sshd_config_default -Destination $env:ProgramData\ssh\sshd_config ; \
    Invoke-Expression -Command \"ssh-keygen.exe -A\" ; \
    .\FixHostFilePermissions.ps1 -Confirm:$false ; \
    .\FixUserFilePermissions.ps1 -Confirm:$false ; \
    .\install-sshd.ps1 ; \
    Set-Location -Path \"$previousPath\"

# Install sonar scanner
RUN powershell -Command \
    $sonarScannerVersion=\"4.6.2.2108\" ; \
    $sonarScannerInstallPath=\"C:\sonar-scanner\" ; \
    New-Item -Path $sonarScannerInstallPath -ItemType Directory ; \
    Invoke-WebRequest -UseBasicParsing -Uri \"https://github.com/SonarSource/sonar-scanner-msbuild/releases/download/${sonarScannerVersion}/sonar-scanner-msbuild-${sonarScannerVersion}-net46.zip\" -OutFile \"${sonarScannerInstallPath}\sonar-scanner.zip\" ; \
    Expand-Archive -Path \"${sonarScannerInstallPath}\sonar-scanner.zip\" -DestinationPath $sonarScannerInstallPath -Force ; \
    Remove-Item -Path \"${sonarScannerInstallPath}\sonar-scanner.zip\" -Force ; \
    $path = [System.Environment]::GetEnvironmentVariable(\"PATH\", \"Machine\") ; \
    [System.Environment]::SetEnvironmentVariable(\"PATH\", $path + \";$sonarScannerInstallPath;\", \"Machine\")

# Copy entrypoint script
COPY ./entrypoint.ps1 .

# Add root user and set password
RUN powershell -Command \
    $psw = ConvertTo-SecureString -AsPlainText -Force -String \"lJe2u2P+iMk0lyCNHsEM39Sxe0+0R+x6Urkdhno5ffw=\" ; \
    New-LocalUser -Name \"root\" -Password $psw -FullName \"Root user\" -Description \"User for Jenkins pipeline automation\" -AccountNeverExpires -PasswordNeverExpires >> temp ; \
    Add-LocalGroupMember -Group \"Administrators\" -Member \"root\"

EXPOSE 22

ENTRYPOINT powershell -Command .\entrypoint.ps1
