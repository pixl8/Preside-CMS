/**
 * Provides logic for dealing with admin views of preside
 * object records such as calculating what renderer to use
 * for fields, locating renderer viewlets and record URLs.
 *
 * @singleton      true
 * @presideService true
 * @autodoc
 */
component {

// CONSTRUCTOR
	/**
	 * @contentRendererService.inject contentRendererService
	 * @dataManagerService.inject     dataManagerService
	 */
	public any function init( required any contentRendererService, required any dataManagerService ) {
		_setContentRendererService( arguments.contentRendererService );
		_setDataManagerService( arguments.dataManagerService );
		_setLocalCache( {} );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Renders a field in the context of an admin data view
	 *
	 * @autodoc true
	 * @autodoc           true
	 * @objectName.hint   Name of the object whose property for which you are rendering content
	 * @propertyName.hint Name of the property for which you are rendering content
	 * @recordId.hint     ID of the record to whose content this belongs
	 * @value.hint        Value to render (if any)
	 * @renderer.hint     Renderer to use (will default to calculating the renderer using [[admindataviewsservice-getrendererforfield]])
	 */
	public string function renderField(
		  required string objectName
		, required string propertyName
		, required string recordId
		,          any    value    = ""
		,          string renderer = getRendererForField( objectName=arguments.objectName, propertyName=arguments.propertyName )
	) {

		return _getContentRendererService().render(
			  renderer = arguments.renderer
			, context  = [ "adminview", "admin" ]
			, data     = arguments.value
			, args     = { objectName=arguments.objectName, propertyName=arguments.propertyName, recordId=arguments.recordId }
		);
	}

	/**
	 * Returns either the defined or default admin renderer for the given preside object
	 * property for rendering in an admin record view.
	 *
	 * @autodoc           true
	 * @objectName.hint   Name of the object whose property you wish to get the renderer for
	 * @propertyName.hint Name of the property you wish to get the renderer for
	 */
	public string function getRendererForField( required string objectName, required string propertyName ) {
		var args = arguments;

		return _simpleLocalCache( "getRendererForField_#arguments.objectName#_#arguments.propertyName#", function(){
			var prop = $getPresideObjectService().getObjectProperty(
				  objectName   = args.objectName
				, propertyName = args.propertyName
			);
			var adminRenderer   = prop.adminRenderer ?: "";
			var generalRenderer = prop.renderer      ?: "";
			var type            = prop.type          ?: "";
			var dbType          = prop.dbType        ?: "";
			var relationship    = prop.relationship  ?: "";

			if ( adminRenderer.trim().len() ) {
				return adminRenderer.trim();
			}

			if ( generalRenderer.trim().len() ) {
				return generalRenderer.trim();
			}

			switch( relationship ) {
				case "many-to-one":
					var relatedTo = prop.relatedTo ?: "";
					switch( relatedTo ) {
						case "asset":
						case "link":
							return relatedTo;
					}
					return "manyToOne";

				case "many-to-many":
				case "one-to-many":
					return "objectRelatedRecords";
			}

			if ( Len( Trim( prop.enum ?: "" ) ) ) {
				return "enumLabel";
			}

			switch( dbtype ) {
				case "text":
				case "mediumtext":
				case "longtext":
					return "richeditor";

				case "boolean":
				case "bit":
					return "boolean";

				case "date":
					return "date";

				case "datetime":
				case "timestamp":
					return "datetime";
			}


			return "plaintext";
		} );
	}


	/**
	 * Returns array of property names in expected order that
	 * can be rendered for a given object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose properties you wish to get
	 *
	 */
	public array function listRenderableObjectProperties( required string objectName ) {
		var allProps       = $getPresideObjectService().getObjectProperties( objectName=arguments.objectName );
		var availableProps = [];

		for( var propertyName in allProps ) {
			if ( getRendererForField( objectName=arguments.objectName, propertyName=propertyName ) !== "none" ) {
				availableProps.append( propertyName )
			}
		}

		return availableProps.sort( function( a, b ){
			var aSortOrder = Val( allProps[ a ].sortOrder ?: 100000000 );
			var bSortOrder = Val( allProps[ b ].sortOrder ?: 100000000 );

			return ( aSortOrder == bSortOrder ) ? 0 : ( aSortOrder > bSortOrder ? 1 : -1 );
		} );
	}

	/**
	 * Returns the view group for a property. View group will be used
	 * in the default rendering of an admin view for an object record
	 *
	 * @autodoc      true
	 * @objectName   Name of the object to which the property belongs
	 * @propertyName Name of the property whose group you wish to get
	 */
	public string function getViewGroupForProperty(
		  required string objectName
		, required string propertyName
	){
		var args = arguments;

		return _simpleLocalCache( "getViewGroupForProperty_#arguments.objectName#_#arguments.propertyName#", function(){
			var poService     = $getPresideObjectService();
			var definedAttrib = poService.getObjectPropertyAttribute(
				  objectName    = args.objectName
				, propertyName  = args.propertyName
				, attributeName = "adminViewGroup"
			);

			return definedAttrib.len() ? definedAttrib : getDefaultViewGroupForProperty( argumentCollection=args );
		} );
	}

	/**
	 * Returns the default view group for a property
	 *
	 * @autodoc      true
	 * @objectName   Name of the object to which the property belongs
	 * @propertyName Name of the property whose group you wish to get
	 */
	public string function getDefaultViewGroupForProperty(
		  required string objectName
		, required string propertyName
	){
		var args = arguments;

		return _simpleLocalCache( "getDefaultViewGroupForProperty_#arguments.objectName#_#arguments.propertyName#", function(){
			var poService   = $getPresideObjectService();
			var systemProps = [
				  poService.getIdField( args.objectName )
				, poService.getDateCreatedField( args.objectName )
				, poService.getDateModifiedField( args.objectName )
			];

			if ( systemProps.findNoCase( args.propertyName ) ) {
				return "system";
			}

			return "default";
		} );
	}

	/**
	 * Returns details of a given 'view group' for an object
	 *
	 * @autodoc true
	 * @objectName Name of the object that the view group belongs to
	 * @groupName  Name of the view group whose detail you wish to get
	 */

	public struct function getViewGroupDetail(
		  required string objectName
		, required string groupName
	) {
		var uriRoot = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		var defaults = {
			  title       = arguments.groupName
			, description = ""
			, iconClass   = ""
			, sortOrder   = 1000
			, column      = "left"
		};

		switch( arguments.groupName ) {
			case "default":
				defaults.title       = $translateResource( uri=uriRoot & "title.singular", defaultValue=arguments.objectName );
				defaults.description = $translateResource( uri=uriRoot & "description"   , defaultValue=""                   );
				defaults.iconClass   = $translateResource( uri=uriRoot & "iconClass"     , defaultValue=""                   );
				defaults.sortOrder   = 1;
				defaults.column      = "left";
			break;
			case "system":
				defaults.title       = $translateResource( uri="cms:admin.view.system.group.title"      , defaultValue=arguments.groupName  );
				defaults.description = $translateResource( uri="cms:admin.view.system.group.description", defaultValue=""                   );
				defaults.iconClass   = $translateResource( uri="cms:admin.view.system.group.iconclass"  , defaultValue=""                   );
				defaults.sortOrder   = 1;
				defaults.column      = "right";
			break;
		}

		var detail = {
			  id          = arguments.groupName
			, title       = $translateResource( uri=uriRoot & "viewgroup.#arguments.groupName#.title"      , defaultValue=defaults.title       )
			, description = $translateResource( uri=uriRoot & "viewgroup.#arguments.groupName#.description", defaultValue=defaults.description )
			, iconClass   = $translateResource( uri=uriRoot & "viewgroup.#arguments.groupName#.iconClass"  , defaultValue=defaults.iconClass   )
			, sortOrder   = $translateResource( uri=uriRoot & "viewgroup.#arguments.groupName#.sortOrder"  , defaultValue=defaults.sortOrder   )
			, column      = $translateResource( uri=uriRoot & "viewgroup.#arguments.groupName#.column"     , defaultValue=defaults.column      )
		};

		detail.column = detail.column == "right" ? detail.column : "left";

		return detail;
	}

	/**
	 * Returns an struct with keys 'left' and 'right'.
	 * Each key contains an ordered array of view groups with their
	 * renderable properties ready for rendering an admin view of an object
	 *
	 * @autodoc    true
	 * @objectName name of the object whose groups you wish to get
	 *
	 */
	public struct function listViewGroupsForObject( required string objectName ) {
		var args     = arguments;
		var cacheKey = "listViewGroupsForObject-" & arguments.objectName & "-" & $getI18nLocale();

		return _simpleLocalCache( cacheKey, function(){
			var properties   = listRenderableObjectProperties( args.objectName );
			var uniqueGroups = {};
			var listedGroups = { left=[], right=[] };

			for( var propertyName in properties ) {
				var groupName = getViewGroupForProperty( args.objectName, propertyName );
				uniqueGroups[ groupName ] = uniqueGroups[ groupName ] ?: [];
				uniqueGroups[ groupName ].append( propertyName );
			}

			for( var groupName in uniqueGroups ) {
				var group = getViewGroupDetail( args.objectName, groupName ).copy();
				group.properties = uniqueGroups[ groupName ];

				listedGroups[ group.column ].append( group );
			}

			for( var column in [ "left", "right" ] ) {
				listedGroups[ column ] = listedGroups[ column ].sort( function( a, b ){
					if ( a.sortOrder == b.sortOrder ) {
						return a.title > b.title ? 1 : -1;
					}

					return a.sortOrder > b.sortOrder ? 1 : -1;
				} );
			}

			return listedGroups;
		} );
	}

	/**
	 * Returns an array of grid fields to use for displaying a many-to-many, or one-to-many table
	 * for relationship property of an object
	 *
	 * @autodoc      true
	 * @objectName   The name of the object that has the relationship property
	 * @propertyName The name of the relationship property
	 * @expandPaths  Whether or not to prefix all the field names with the relationship property name (use case: displaying grid fields vs selecting them)
	 */
	public array function listGridFieldsForRelationshipPropertyTable(
		  required string  objectName
		, required string  propertyName
	) {
		var args = arguments;

		return _simpleLocalCache( "listGridFieldsForRelationshipPropertyTable#arguments.objectName##arguments.propertyName#", function(){
			var delim            = "";
			var field            = "";
			var attrib           = "";
			var gridFields    = "";
			var poService        = $getPresideObjectService();
			var gridFieldAttribs = [ "minimalGridFields", "gridFields", "datamanagerGridFields" ];
			var relatedObject    = poService.getObjectPropertyAttribute(
				  objectName    = args.objectName
				, propertyName  = args.propertyName
				, attributeName = "relatedTo"
			);

			for( attrib in gridFieldAttribs ) {
				gridFields = poService.getObjectAttribute(
					  objectName    = relatedObject
					, attributeName = attrib
				);

				if ( gridFields.len() ) {
					break;
				}
			}

			if ( !gridFields.len() ) {
				gridFields = poService.getLabelField( relatedObject );

				if ( !gridFields.len() ) {
					gridFields = poService.getIdField( relatedObject );
				}
			}

			return gridFields.listToArray();
		} );
	}

// PRIVATE HELPERS
	private any function _simpleLocalCache( required string cacheKey, required any generator ) {
		var cache = _getLocalCache();

		if ( !StructKeyExists( cache, cacheKey ) ) {
			cache[ cacheKey ] = generator();
		}

		return cache[ cacheKey ] ?: NullValue();
	}


// GETTERS/SETTERS
	private any function _getContentRendererService() {
		return _contentRendererService;
	}
	private void function _setContentRendererService( required any contentRendererService ) {
		_contentRendererService = arguments.contentRendererService;
	}

	private struct function _getLocalCache() {
		return _localCache;
	}
	private void function _setLocalCache( required struct localCache ) {
		_localCache = arguments.localCache;
	}

	private any function _getDataManagerService() {
		return _dataManagerService;
	}
	private void function _setDataManagerService( required any dataManagerService ) {
		_dataManagerService = arguments.dataManagerService;
	}
}