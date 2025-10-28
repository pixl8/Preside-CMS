/**
 * @feature        webflow
 * @singleton      true
 * @presideService true
 */
component {

	public any function init() {
		return this;
	}

	public string function prettyPrintSavedState(
		  required struct savedState
		,          array  ignoreKeys = [ "_rurl", "_wid" ]
	) {
		var args     = Duplicate( arguments );
		var nl       = Chr( 10 );
		var tabChar  = Chr( 9 );

		var processComplexData = function(
			  required struct content
			,          string tabs = ""
		) {
			var processed   = "";
			var contentTabs = arguments.tabs & tabChar;

			processed &= arguments.tabs & "{" & nl;

			for ( var key in arguments.content ) {
				if ( ArrayFindNoCase( args.ignoreKeys, key ) ) {
					continue;
				}

				if ( IsStruct( arguments.content[ key ] ) ) {
					processed &= contentTabs & key & ": " & processComplexData(
						  content = arguments.content[ key ]
						, tabs    = contentTabs
					);
				} else {
					processed &= contentTabs & key & ": " & ( IsSimpleValue( arguments.content[ key ] ) ? arguments.content[ key ] : SerializeJSON( arguments.content[ key ] ) ) & "," & nl;
				}
			}

			processed &= arguments.tabs & "}," & nl;

			return processed;
		};

		var rendered = processComplexData( content=arguments.savedState );

		return Left( rendered, Len( rendered ) - 2 );
	}

	public any function getWebflowInstances(
		  required string  recordId
		,          boolean archived     = false
		,          boolean countOnly    = false
		,          array   extraFilters = []
	) {
		var objectName    = arguments.archived ? "cfflow_workflow_archived_instance" : "cfflow_workflow_instance";
		var webflowDetail = _getWebflowConfigDetail( recordId=arguments.recordId );
		var queryFilter   = "";
		var queryParams   = {};

		if ( $helpers.isTrue( webflowDetail.is_singleton ?: "" ) ) {
			queryFilter           = "reference = :reference";
			queryParams.reference = webflowDetail.webflow_id;
		} else {
			queryFilter               = "reference = :reference AND sub_reference = :sub_reference";
			queryParams.reference     = webflowDetail.webflow_id;
			queryParams.sub_reference = webflowDetail.instance_ref;
		}

		return $getPresideObject( objectName ).selectData(
			  recordCountOnly = arguments.countOnly
			, extraFilters    = arguments.extraFilters
			, filter          = queryFilter
			, filterParams    = queryParams
		);
	}

// PRIVATE HELPERs
	private struct function _getWebflowConfigDetail( required string recordId ) {
		return $getPresideObject( "webflow_configuration" ).selectData(
			  id           = arguments.recordId
			, returntype   = "singleRecordStruct"
			, selectFields = [
				  "id"
				, "webflow_id"
				, "instance_ref"
				, "is_singleton"
			]
		);
	}
}