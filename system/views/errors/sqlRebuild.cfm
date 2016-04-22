<!DOCTYPE html>
<html>
	<head>
		<title>PresideCMS: SQL Schema Synchronisation Required</title>
		<meta charset="utf-8">
		<meta name="robots" content="noindex,nofollow" />
		<style type="text/css">
			body {
				background  : #fff;
				font-family : arial;
				font-size   : 14px;
				padding     : 0;
				margin      : 0;
				color       : #333;
			}

			#main {
				margin : 0 10%;
			}

			#main ~ * {
				display : none; /* hack for BlueDragon.net that insists on injecting error info at the end of the page - this hides that content */
			}

			h1, h2 {
				margin      : 30px 0;
				font-weight : normal;
			}

			h1 span {
				color : #808080;
			}

			h2 {
				color       : #808080;
				font-size   : 1.4em;
			}

			h3{
				color:#434343;
				padding: 15px 0;
				border-bottom: 1px dotted #d2d2d2;
			}

			ul li {
				margin:0;
			}

			p {
				font-size: 12px;
				margin: 20px 0;
			}

			pre {
				background  : #f6f6f6;
				padding     : 1em;
				overflow-x  : scroll;
				font-family : "Lucida Console", Monaco, monospace, "Courier New", Courier;
				font-size   : 10px;
			}
		</style>
	</head>
	<body>
		<div id="main">
			<h1><span>503</span> The application encountered an error on load</h1>
			<h2>Initialisation did not complete</h2>

			<p>The latest application changes require a change to the database structure and the site is configured to not automatically synchronize the database.</p>

			<cfif IsBoolean( showScript ?: "" ) and showScript>
				<p>The script required to run can be seen below. Please <strong>check that the script is as expected</strong> before directly executing on your database. Once complete, reload the application. The script has also been saved to your installation's <code>/logs</code> directory.</p>

				<pre><code><cfoutput>#Trim( exception.detail ?: "" )#</cfoutput></code></pre>
			<cfelse>
				<p>Please check your installation's <code>/logs</code> directory for generated upgrade scripts. Once the upgrade has completed, you will need to reload the application.</p>
			</cfif>
		</div>
	</body>
</html>