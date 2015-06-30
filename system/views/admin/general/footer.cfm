<cfparam name="args.currentVersion" type="string" />

<cfoutput>
	<footer class="footer">
		#TranslateResource( uri='cms:cms.version', data=[ args.currentVersion ] )#
	</footer>
</cfoutput>