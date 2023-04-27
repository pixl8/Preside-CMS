<h1>Welcome to Preside test suite</h1>

<h3>
	<a href="runtests.cfm">Run the full suite now</a>
</h3>
<h3>
	<a href="runtests.cfm?scope=quick">Run quick test</a>
</h3>

<p>Quick test excludes the following long-running tests. Click to run them individually:</p>
	<ul>
		<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.presideObjects.PresideObjectServiceTest">PresideObjectServiceTest</a></li>
		<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.security.CsrfProtectionServiceTest">CsrfProtectionServiceTest</a></li>
		<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.admin.LoginServiceTest">LoginServiceTest</a></li>
		<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.admin.AuditServiceTest">AuditServiceTest</a></li>
		<li><a href="runtests.cfm?method=runRemote&directory=&testBundles=integration.api.sitetree.SiteServiceTest">SiteServiceTest</a></li>
	</ul>
</p>