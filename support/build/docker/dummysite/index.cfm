<cfoutput><!DOCTYPE html>
<html>
	<head>
		<title>PresideCMS Docker Image</title>
	</head>
	<body>
		<h1>PresideCMS Docker Image</h1>
		<p>This is a stub page for the PresideCMS Docker image. If you're seeing this, its most likely because
		   you've successfully spun up a container based on the <a href="https://hub.docker.com/r/pixl8/preside-cms/">pixl8/preside-cms</a>
		   docker image.</p>

		<h2>System info</h2>
		<dl>
			<dt>Preside</dt>
			<dd>#systemInfo.presideVersion#</dd>
			<dt>CFML Engine</dt>
			<dd>#systemInfo.productName# #systemInfo.productVersion#</dd>
			<dt>Java</dt>
			<dd>#systemInfo.javaVersion#</dd>
			<dt>Operating System</dt>
			<dd>#systemInfo.osName# #systemInfo.osVersion#</dd>
		</dl>

		<h2>Next steps</h2>
		<p>For a meaninful site, you'll want to create your own docker image (with a Dockerfile), using the instructions on
		   <a href="https://hub.docker.com/r/pixl8/preside-cms/">our docker image page</a>. From there, you can setup an
		   entire environment, with database, search engine, etc. all configured and ready to deploy.</p>
	</body>
</html></cfoutput>