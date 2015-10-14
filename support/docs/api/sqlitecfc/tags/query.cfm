<!---+
	Like cfquery but for SqliteCFC Sqlite dbs
	
	By: Shawn Grigson	
	From Transfer ORMs query tags,
		Originally By: Elliott Sprehn
	Date: Dec 8, 2009
---><cfsilent>
	
	<cfif not thisTag.hasEndTag>
		<cfthrow 
			type="SqliteCFC.SyntaxError" 
			message="The SqliteCFC query tag requires an end tag.">
	</cfif>

	<cfif thisTag.executionMode eq "start">	
		<cfparam name="attributes.name" type="string">
		<cfparam name="attributes.dbName" type="string">
		<cfparam name="attributes.action" type="string" default="read">
		<cfparam name="attributes.variable" type="string" default="sqlite">
		<cfparam name="attributes.variableScope" type="string" default="application">
		
		<cfif not StructKeyExists(attributes,"cfc") AND ((attributes.variableScope EQ "application" AND not StructKeyExists(application,attributes.variable)) OR (attributes.variableScope EQ "server" AND not StructKeyExists(SERVER,attributes.variable)))>
			<cfthrow 
				type="SqliteCFC.NotDefined.CFC" 
				message="Attribute validation error for the SqliteCFC Query tag."
				detail="The instantiated CFC was not passed via the CFC parameter, and does not exist in the variable #attributes.variableScope#[""#attributes.variable#""]">
		</cfif>
		<cfif not listFindNoCase("read,update",attributes.action)>
			<cfthrow 
				type="SqliteCFC.SyntaxError" 
				message="Attribute validation error for the SqliteCFC Query tag."
				detail="The value of the action attribute must be one of 'list' or 'read'.">
		</cfif>
		
		<cfif StructKeyExists(attributes,"cfc")>
			<cfset SQLite = attributes.cfc />
		<cfelseif attributes.variableScope EQ "application" AND StructKeyExists(application,attributes.variable)>
			<cfset SQLite = application["#attributes.variable#"] />
		<cfelseif attributes.variableScope EQ "server" AND StructKeyExists(SERVER,attributes.variable)>
			<cfset SQLite = SERVER["#attributes.variable#"] />
		</cfif>
		
		<!--- Used by query param tags to store arguments for setParam() --->
		<cfset params = arrayNew(1)>
	<cfelse>
		<cfif Left(thisTag.generatedContent,6) EQ "SELECT">
			<cfset attributes.action = "read">
		<cfelse>
			<cfset attributes.action = "update">
		</cfif>
		
		<cfset query = thisTag.generatedContent />
		<!--- Set each parameter for the query --->
		<cfloop from="1" to="#arrayLen(params)#" index="i">
			<cfset query = ReplaceNoCase(query,":" & params[i].name,"""#params[i].value#""","ALL")>
		</cfloop>
		
		<cfset query = SQLite.executeSql(SQLite.getDBFilePath(attributes.dbName),query) />

		<!--- Must reset this so the generated TQL doesn't end up in the page --->
		<cfset thisTag.generatedContent = "">
		
		
		<cfif attributes.action eq "read">
			<cfset caller[attributes.name] = query>
		<cfelse>
			<cfset caller[attributes.name] = query>
		</cfif>
	</cfif>
</cfsilent>