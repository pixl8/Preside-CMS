---
id: quickstart
title: Quick start guide
---

The quickest way to get started with PresideCMS is to take it for a spin with our [CommandBox commands](https://github.com/pixl8/Preside-CMS-CommandBox-Commands). These commands give you the ability to:

* Create a new skeleton PresideCMS application from the commandline 
* Spin up an ad-hoc PresideCMS server on your local dev machine that runs the PresideCMS application in the current directory

## Install commandbox and Preside Commands

Before starting, you will need CommandBox installed. Head to [http://www.ortussolutions.com/products/commandbox](http://www.ortussolutions.com/products/commandbox) for instructions on how to do so. You will need at least version 3.0.0.

Once you have CommandBox up and running, you'll need to issue the following command to install our PresideCMS specific commands:

```
CommandBox> install --force preside-commands
```
    
## Usage

### Create a new site

From within the CommandBox shell, CD into an empty directory in which you would like to create the new site and type:

```
CommandBox> preside new site
```
    
Follow any prompts that you receive.

### Start a server

From the webroot of your Preside site, enter the following command:

```
CommandBox> preside start
```
    
If it is the first time starting, you will be prompted to download Preside and also to enter your database information, **you will need an empty _MySQL_ database already setup**.

Once started, a browser should open and you should be presented with your homepage. To navigate to the administrator, browse to `/{site_id}_admin/`, where site id is the ID of the site you entered when creating the new site from the instructions above.

>>>>>> The admin path setting is editable in your site's `/application/config/Config.cfc` file.

