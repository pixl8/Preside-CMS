<cfoutput>
	<p><small>#translateResource( "formcontrols.multiSelectPanel:selectedOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# to"
	        name="#inputName#_to"
	        id="#inputId#_to"
	        tabindex="#getNextTabIndex()#"
	        multiple="multiple"
	        size="#selectSize#"
	>
		<cfloop array="#values#" index="i" item="selectedValue">
			<cfset selected = ListFindNoCase( value, selectedValue ) />

			<cfif isTrue( selected )>
				<option value="#HtmlEditFormat( selectedValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>
		</cfloop>
	</select>
</cfoutput>