<!---+
	Like cfqueryparam but for Transfer.
	
	Attributes are implicitly mapped down to the transfer.tql.Query#setParam()
	method. So look at that to figure out what to specify.
	
	Do NOT provide the name. That's done for you.
	
	By: Elliott Sprehn
	Date: Jun 29, 2008
--->
<cfsetting enablecfoutputonly="true">

	<cfset tagData = getBaseTagData("cf_query")>
	<cfset arrayAppend( tagData.params, attributes )>
	<cfset attributes.name = arrayLen(tagData.params)>
	<cfset writeOutput( ":#attributes.name#" )>

<!--- cfexit skips end tag so we don't add params twice! --->
<cfsetting enablecfoutputonly="false"><cfexit>