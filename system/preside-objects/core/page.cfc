<cfcomponent extends="preside.system.base.SystemPresideObject" labelfield="title" output="false">

<!--- properties --->
	<cfproperty name="title"                     type="string"  dbtype="varchar"  maxLength="200" required="true" control="textinput" />
	<cfproperty name="main_content"              type="string"  dbtype="text"                     required="false"  />
	<cfproperty name="teaser"                    type="string"  dbtype="varchar"  maxLength="500" required="false"  />
	<cfproperty name="slug"                      type="string"  dbtype="varchar"  maxLength="50"  required="false" uniqueindexes="slug|3" format="slug" />
	<cfproperty name="page_type"                 type="string"  dbtype="varchar"  maxLength="100" required="true"                                             control="pageTypePicker" />
	<cfproperty name="layout"                    type="string"  dbtype="varchar"  maxLength="100" required="false"                                            control="pageLayoutPicker" />

	<cfproperty name="sort_order"                type="numeric" dbtype="int"                      required="true"                                             control="none" />
	<cfproperty name="active"                    type="boolean" dbtype="bool"                     required="false" default="0" />
	<cfproperty name="trashed"                   type="boolean" dbtype="bool"                     required="false" default="0" control="none" />
	<cfproperty name="old_slug"                  type="string"  dbtype="varchar" maxLength="50"   required="false" />

	<cfproperty name="main_image"  relationship="many-to-one" relatedTo="asset"                   required="false" allowedTypes="image" />
	<cfproperty name="site"        relationship="many-to-one" relatedTo="site"                    required="true"                      uniqueindexes="slug|1" control="none" />
	<cfproperty name="parent_page" relationship="many-to-one" relatedTo="page"                    required="false"                     uniqueindexes="slug|2" control="none" />
	<cfproperty name="created_by"  relationship="many-to-one" relatedTo="security_user"           required="true"                                             control="none" generator="loggedInUserId" />
	<cfproperty name="updated_by"  relationship="many-to-one" relatedTo="security_user"           required="true"                                             control="none" generator="loggedInUserId" />

	<cfproperty name="author"                    type="string"  dbtype="varchar" maxLength="100"  required="false" />
	<cfproperty name="browser_title"             type="string"  dbtype="varchar" maxLength="100"  required="false" />
	<cfproperty name="keywords"                  type="string"  dbtype="varchar" maxLength="255"  required="false" />
	<cfproperty name="description"               type="string"  dbtype="varchar" maxLength="255"  required="false" />
	<cfproperty name="embargo_date"              type="date"    dbtype="datetime"                 required="false"                                            control="datetimepicker" />
	<cfproperty name="expiry_date"               type="date"    dbtype="datetime"                 required="false"                                            control="datetimepicker" />

	<cfproperty name="exclude_from_navigation"   type="boolean" dbtype="boolean"                  required="false" default="false" />
	<cfproperty name="navigation_title"          type="string"  dbtype="varchar" maxLength="200"  required="false"  />

	<cfproperty name="_hierarchy_id"             type="numeric" dbtype="int"     maxLength="0"    required="true"                                                            uniqueindexes="hierarchyId" />
	<cfproperty name="_hierarchy_sort_order"     type="string"  dbtype="varchar" maxLength="200"  required="true"                                             control="none" indexes="sortOrder" />
	<cfproperty name="_hierarchy_lineage"        type="string"  dbtype="varchar" maxLength="200"  required="true"                                             control="none" indexes="lineage" />
	<cfproperty name="_hierarchy_child_selector" type="string"  dbtype="varchar" maxLength="200"  required="true"                                             control="none" />
	<cfproperty name="_hierarchy_depth"          type="numeric" dbtype="int"                      required="true"                                             control="none" indexes="depth" />
	<cfproperty name="_hierarchy_slug"           type="string"  dbtype="varchar" maxLength="2000" required="true"                                             control="none" />


<!--- data methods --->
	<cffunction name="updateChildHierarchyHelpers" access="public" returntype="void" output="false">
		<cfargument name="oldData" type="query"  required="true" />
		<cfargument name="newData" type="struct" required="true" />

		<cfset var field  = "" />
		<cfset var oldLen = "" />

		<cfquery datasource="#getDsn()#">
			update #getTableName()#
			set    datemodified = <cfqueryparam value="#Now()#" cfsqltype="cf_sql_timestamp" />

			<cfloop list="_hierarchy_lineage,_hierarchy_slug,_hierarchy_depth,_hierarchy_sort_order,trashed" item="field">
				<cfif StructKeyExists( arguments.newData, field )>
					<cfswitch expression="#field#">
						<cfcase value="_hierarchy_lineage,_hierarchy_slug,_hierarchy_sort_order">
							, #field# = Concat( <cfqueryparam value="#arguments.newData[ field ]#" cfsqltype="cf_sql_varchar" />, Right( #field#, Length( #field# ) - <cfqueryparam value="#Len( arguments.oldData[ field ][1] )#" cfsqltype="cf_sql_integer" /> ) )
						</cfcase>
						<cfcase value="_hierarchy_depth">
							, #field# = #field# - <cfqueryparam value="#arguments.oldData[ field ][1] - arguments.newData[ field ]#" cfsqltype="cf_sql_integer" />
						</cfcase>
						<cfcase value="trashed">
							, #field# = <cfqueryparam value="#( arguments.newData.trashed ? 1 : 0 )#" cfsqltype="cf_sql_bit" />
						</cfcase>
					</cfswitch>
					<cfif field eq "_hierarchy_lineage">
						, _hierarchy_child_selector = Concat( <cfqueryparam value="#arguments.newData[ field ]#" cfsqltype="cf_sql_varchar" />, Right( _hierarchy_child_selector, Length( _hierarchy_child_selector ) - <cfqueryparam value="#Len( arguments.oldData[ field ][1] )#" cfsqltype="cf_sql_integer" /> ) )
					</cfif>
				</cfif>
			</cfloop>

			where  _hierarchy_lineage like <cfqueryparam value="#arguments.oldData._hierarchy_child_selector#" cfsqltype="cf_sql_varchar" />
		</cfquery>
	</cffunction>

</cfcomponent>