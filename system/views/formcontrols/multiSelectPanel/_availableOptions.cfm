<cfoutput>
	<p><small>#translateResource( "formcontrols.multiSelectPanel:availableOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# from"
	        name="#inputName#_from"
	        id="#inputId#_from"
	        tabindex="#getNextTabIndex()#"
	        multiple="multiple"
	        size="#selectSize#"
	>
		<cfloop array="#values#" index="i" item="availableValue">
			<cfset selected = ListFindNoCase( value, availableValue ) />

			<cfif isFalse( selected )>
				<option value="#HtmlEditFormat( availableValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>
		</cfloop>
	</select>
</cfoutput>