<cfscript>
	dirs = DirectoryList( path="integration/api", listinfo="name" );
	ArraySort( dirs, "text" );
</cfscript>
<style>
	body {
		font-family : system-ui, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
		padding     : 2em;
		max-width   : 40em;
		margin      : 0 auto;
	}
	a {
		color : #ef4036;
	}
	h1 {
		text-align : center;
		margin-bottom : 2em;
	}
	h1 img {
		margin : 2em 0;
	}
	section {
		border  : 1px solid #999;
		margin  : 2em 0;
		padding : 1em;
	}
	section > :first-child, section > :last-child {
		margin : 0;
	}
</style>

<html>
<head>
	<title>Preside Test Suite</title>
</head>
<body>
	<cfoutput> 
	<h1>
		<img src="preside-logo.png" alt="Preside" width="138" height="48"><br>
		Welcome to the Preside test suite<br>
		Lucee #server.lucee.version#, java #server.java.version#
	</h1>
	</cfoutput>
	<section>
		<h3>
			<a href="runtests.cfm">Run the full suite now</a>
		</h3>
	</section>

	<section>
		<h3>
			<a href="runtests.cfm?scope=quick">Run quick test</a>
		</h3>

		<p>Quick test excludes the following long-running tests. Click to run them individually:</p>
			<ul>
				<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.admin.AuditServiceTest">admin.AuditServiceTest</a></li>
				<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.admin.LoginServiceTest">admin.LoginServiceTest</a></li>
				<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.presideObjects.PresideObjectServiceTest">presideObjects.PresideObjectServiceTest</a></li>
				<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.security.CsrfProtectionServiceTest">security.CsrfProtectionServiceTest</a></li>
				<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.sitetree.SiteServiceTest">sitetree.SiteServiceTest</a></li>
			</ul>
		</p>
	</section>

	<section>
		<h3>Run tests from chosen directory:</h3>

		<form action="runtests.cfm" method="get">
			<cfoutput>
				<p>
					<select name="directory">
						<option value="">Choose a directory...</option>
						<cfloop array="#dirs#" index="dir">
						<option value="#dir#">#dir#</option>
						</cfloop>
					</select>
					<input type="submit" value="Run tests">
				</p>
			</cfoutput>
		</form>
	</section>


</body>

</html>