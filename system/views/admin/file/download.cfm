<cfscript>
	requestedFile = prc.requestedFile ?: "";
</cfscript>

<cfoutput>
	<cfif Len( requestedFile )>
		<cfhtmlhead text='<meta http-equiv="refresh" content="2; url=#requestedFile#" />'>

		<h2>#translateResource( "cms:file.download.downloading" )#</h2>
		<p>#translateResource( uri="cms:file.download.downloading.text", data=[ requestedFile ] )#</p>
	<cfelse>
		<h2>#translateResource( "cms:file.download.error" )#</h2>
		<p>#translateResource( uri="cms:file.download.error.text" )#</p>
	</cfif>
</cfoutput>