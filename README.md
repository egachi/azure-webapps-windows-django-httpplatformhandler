# Django Hello World with HttpPlatformHandler using Azure Web App (Windows)

This repository contains the deployment scripts and web.config to use Python and run Django installing requirements.txt, for more information about HttpPlatformHandler with Python check this reference: [Configure the HttpPlatform handler](https://docs.microsoft.com/en-us/visualstudio/python/managing-python-on-azure-app-service?view=vs-2017#configure-the-httpplatform-handler) for Azure App Service.

# Installing and Using this example

You need to install first a Site Extension with the desired Python version. To install a Site Extension into an Azure App service instance, you can use the portal at [portal.azure.com](https://portal.azure.com). Go to the Web App and search for Extensions. Check this reference: [Choose a Python version through the Azure portal](https://docs.microsoft.com/en-us/visualstudio/python/managing-python-on-azure-app-service?view=vs-2017#choose-a-python-version-through-the-azure-portal)

Ensure that you don't have any Python version inside Application Settings for your Web App, you need to set Python version to Off in that blade and use the site extension.

To deploy as part of an ARM template, include a site extension resource in your site. For example, the below resource will install Python 3.6.4 x86 as part of deploying your site.

```json
{
  "resources": [
    {
      "apiVersion": "2015-08-01",
      "name": "[parameters('siteName')]",
      "type": "Microsoft.Web/sites",
      ...
      "resources": [
        {
          "apiVersion": "2015-08-01",
          "name": "azureappservice-python364x86",
          "type": "siteextensions",
          "properties": { },
          "dependsOn": [
            "[resourceId('Microsoft.Web/sites', parameters('siteName'))]"
          ]
        },
      ...
```

Once the site extension has been installed, you need to activate Python through your `web.config` file using either the FastCGI module or the HttpPlatform module. In this example we are using HttpPlatformHandler.

## Using HttpPlatform

The [HttpPlatform](http://www.iis.net/learn/extensions/httpplatformhandler/httpplatformhandler-configuration-reference) module forwards socket connections directly to a standalone Python process, so you will require a startup script that runs a local web server. 

You need to change the Python Path in web.config. 
To find the path check this reference: [Find the path to python.exe after installing a site extension](https://docs.microsoft.com/en-us/visualstudio/python/managing-python-on-azure-app-service?view=vs-2017#find-the-path-to-pythonexe)

And update web.config with the python path.

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="PythonHandler" path="*" verb="*" modules="httpPlatformHandler" resourceType="Unspecified"/>
    </handlers>
    <httpPlatform processPath="D:\home\python364x86\python.exe"
                  arguments="D:\home\site\wwwroot\manage.py runserver %HTTP_PLATFORM_PORT%"
                  stdoutLogEnabled="true"
                  stdoutLogFile="D:\home\LogFiles\python.log"
                  startupTimeLimit="60"
                  processesPerApplication="16">
      <environmentVariables>
        <environmentVariable name="PORT" value="%HTTP_PLATFORM_PORT%" />
      </environmentVariables>
    </httpPlatform>
  </system.webServer>
</configuration>
```

The path to `python.exe` may need to be customized depending on the version of Python you are using. See the description of the site extension to find out where it will be installed and update these paths accordingly.

Arguments may be freely customized for your app. The `HTTP_PLATFORM_PORT` environment variable contains the port your local server should listen on for connections from `localhost`.

## Static Files

For static directories, we recommend using another `web.config` to remove the Python handler and allow the default static file handler to take over. Such a `static/web.config` may look like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <remove name="PythonHandler" />
    </handlers>
  </system.webServer>
</configuration>
```
In this example we are not using static directories.

# Deployment script

As part of the deployment process you have two options, use a custom deployment script to install your dependencies in the python site extension or install your libraries using Kudu console or Kudu REST API.

1. In the first option you need to include .deployment and deploy.cmd file (already included in this repository) with a requirements.txt with all your libraries then change the following part inside deploy.cmd with the python path described below.

```bash
:: 2. Install packages
echo Pip install requirements.
D:\home\python364x86\python.exe -m pip install --upgrade -r requirements.txt
IF !ERRORLEVEL! NEQ 0 goto error
```

In this scenario you can use Github, LocalGit or Bitbucket options to deploy your python code using custom deployment option.

2. If you want to use another deploy process like ftp, you can just upload your code and then install your dependencies manually, check this reference: 
- [Installing libraries using Azure App Service Kudu console](https://docs.microsoft.com/en-us/visualstudio/python/managing-python-on-azure-app-service?view=vs-2017#azure-app-service-kudu-console )
- [Installing libraries using Kudu REST API](https://docs.microsoft.com/en-us/visualstudio/python/managing-python-on-azure-app-service?view=vs-2017#kudu-rest-api)

