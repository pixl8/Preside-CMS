---
title: Build
id: docs-build
---

## Prerequisites

The only dependency required is [CommandBox](http://www.ortussolutions.com/products/commandbox). Ensure that commandbox is installed and that the `box` command is in your path.

## Building the static documentation output

The purpose of the structure of the documentation is to allow a human readable and editable form of documentation that can be built into multiple output formats. At present, there is a single "HTML" builder, found at `./builders/html` that will build the documentation website.

To run the build and produce a static HTML version of the documentation website, execute the `build.sh` file found in the root of the project, i.e.

	documentation>./build.sh

Once this has finished, you should find a `./builds/html` directory with the website content.

## Running a server locally

We have provided a utility server whose purpose is to run locally to help while developing/writing the documentation. To start it up, execute the `serve.sh` file found in the root of the project, i.e.

    documentation>./serve.sh

This will spin up a server using CommandBox on port 4040 and open it in your browser. You should also see a tray icon that will allow you to stop the server. Changes to the source docs should trigger an internal rebuild of the documentation tree which may take a little longer than regular requests to the documentation.