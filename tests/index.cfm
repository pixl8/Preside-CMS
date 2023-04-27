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
	h1 {
		text-align : center;
		margin-bottom : 2em;
	}
	h1 img {
		margin-bottom : .5em;
	}
	div {
		border  : 1px solid #999;
		margin  : 2em 0;
		padding : 1em;
	}
	div > :first-child, div > :last-child {
		margin : 0;
	}
</style>

<html>

<body>

	<h1>
		<img src="preside-logo.png" alt="Preside" width="138" height="48"><br>
		Welcome to the Preside test suite
	</h1>

	<div>
		<h3>
			<a href="runtests.cfm">Run the full suite now</a>
		</h3>
	</div>

	<div>
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
	</div>

	<div>
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
	</div>


</body>

</html>