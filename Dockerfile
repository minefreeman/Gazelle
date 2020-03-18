# escape=`

# The MIT License
#
#  Copyright (c) 2020, Alex Earl and other Jenkins Contributors
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

ARG JAVA_BASE_VERSION=11
ARG JAVA_VERSION=11.0.6-1
ARG JAVA_ZIP_VERSION=11.0.6.10-1
ARG JAVA_SHA256=011b9282cc2b64101a940c34f59106a1f376e98768292bd599aaf5536f03e1f7
ARG JAVA_HOME=C:\openjdk-${JAVA_VERSION}
ARG WINDOWS_DOCKER_TAG=1809
ARG POWERSHELL_VERSION=6.2.1

FROM microsoft/nanoserver:sac2016 as tool
FROM mcr.microsoft.com/powershell:$POWERSHELL_VERSION-nanoserver-$WINDOWS_DOCKER_TAG

USER Administrator

COPY --from=tool /Windows/System32/certoc.exe .
COPY mars.51vr.local.pfx c:\

RUN certoc.exe -ImportPFX -p loneliness Root c:\mars.51vr.local.pfx ;`
    Set-Location -Path cert:\LocalMachine\Root ;`
    Get-Certificate

SHELL ["pwsh.exe", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
 
ARG JAVA_VERSION
ARG JAVA_ZIP_VERSION
ARG JAVA_SHA256
ARG JAVA_HOME
ARG JAVA_BASE_VERSION
ARG BASIC_PAIR='Basic YWRtaW46bG9uZWxpbmVzcw=='

RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; `
    #$basicpair = 'Basic YWRtaW46bG9uZWxpbmVzcw==' ;`
    $header = @{ Authorization = $env:BASIC_PAIR } ;`
    $javaRoot = 'java-{0}-openjdk-{1}.windows.ojdkbuild.x86_64' -f $env:JAVA_BASE_VERSION, $env:JAVA_ZIP_VERSION ; `
    Write-Host "Try to retrieving the openjdk..." ; `
    $netpath = $('https://mars.51vr.local:8082/repository/raw-public/ojdkbuild/ojdkbuild/{0}.zip' -f $javaRoot) ;`
    Write-Host = "NetPath is: $netpath" ;`
    Invoke-WebRequest $netpath -OutFile 'openjdk.zip' -UseBasicParsing -Headers $header ; `
    if ((Get-FileHash openjdk.zip -Algorithm sha256).Hash -ne $env:JAVA_SHA256) { Write-Error 'Java SHA256 mismatch' ; exit 1} ; `
    Expand-Archive openjdk.zip -DestinationPath C:/ ; `
    Move-Item -Path $('C:/{0}' -f $javaRoot) -Destination $('C:/openjdk-{0}' -f $env:JAVA_VERSION) ; `
    Remove-Item -Path openjdk.zip

ARG JAVA_HOME

ARG GIT_VERSION=2.24.0
ARG GIT_PATCH_VERSION=2

RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; `
    $header = @{ Authorization = $env:BASIC_PAIR } ;`
    Invoke-WebRequest $('https://mars.51vr.local:8082/repository/raw-public/git-for-windows/git/MinGit-{0}.{1}-busybox-64-bit.zip' -f $env:GIT_VERSION, $env:GIT_PATCH_VERSION) -OutFile 'mingit.zip' -UseBasicParsing -Headers $header ; `
    Expand-Archive mingit.zip -DestinationPath c:\mingit ; `
    Remove-Item mingit.zip -Force
    #Write-Host $('c:\mingit\cmd;{0}' -f $env:PATH) ;`

ARG GITPATH=C:\mingit\cmd

ARG VERSION=4.0.1
ARG user=jenkins

ARG AGENT_FILENAME=agent.jar
ARG AGENT_HASH_FILENAME=$AGENT_FILENAME.sha1

RUN NET USER "$env:user" /add ;`
    mkdir C:/ProgramData/Jenkins | Out-Null ;`
    setx /M PATH $('%PATH%{0};%JAVA_HOME%\bin' -f $env:GITPATH) ;`
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $env:JAVA_HOME, 'Machine')


LABEL Description="This is a base image, which provides the Jenkins agent executable (agent.jar)" Vendor="Jenkins project" Version="${VERSION}"

ARG AGENT_ROOT=C:/Users/$user/Jenkins
ARG AGENT_WORKDIR=${AGENT_ROOT}/Agent

ENV AGENT_WORKDIR=${AGENT_WORKDIR}

# Get the Agent from the Jenkins Artifacts Repository
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; `
    $header = @{ Authorization = $env:BASIC_PAIR } ;`
    Invoke-WebRequest $('https://mars.51vr.local:8082/repository/raw-public/jenkins-ci/main/remoting/remoting-{0}.jar' -f $env:VERSION) -OutFile $(Join-Path C:/ProgramData/Jenkins $env:AGENT_FILENAME) -UseBasicParsing -Headers $header ;`
    Invoke-WebRequest $('https://mars.51vr.local:8082/repository/raw-public/jenkins-ci/main/remoting/remoting-{0}.jar.sha1' -f $env:VERSION) -OutFile (Join-Path C:/ProgramData/Jenkins $env:AGENT_HASH_FILENAME) -UseBasicParsing -Headers $header ;`
    if ((Get-FileHash (Join-Path C:/ProgramData/Jenkins $env:AGENT_FILENAME) -Algorithm SHA1).Hash -ne (Get-Content (Join-Path C:/ProgramData/Jenkins $env:AGENT_HASH_FILENAME))) {exit 1}

USER $user

RUN mkdir (Join-Path $env:AGENT_ROOT .jenkins) | Out-Null ; `
    mkdir "$env:AGENT_WORKDIR" | Out-Null

VOLUME ${AGENT_ROOT}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR ${AGENT_ROOT}
