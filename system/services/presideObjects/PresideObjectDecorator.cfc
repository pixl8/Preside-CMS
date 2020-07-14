component singleton=true {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public any function decorate(
		  required string objectName
		, required string dsn
		, required string tableName
		, required any    objectInstance
		, required any    presideObjectService
	) output=false {
		var decorated    = arguments.objectInstance;

		if ( not IsSimpleValue( arguments.objectInstance ) ) {
			decorated._presideObjectService = arguments.presideObjectService;
			decorated._objectName           = arguments.objectName;
			decorated._dsn                  = arguments.dsn;
			decorated._tableName            = arguments.tableName;

			decorated.$methodInjector = this.$methodInjector;

			decorated.$methodInjector( "getDsn"         , this.getDsn          );
			decorated.$methodInjector( "getTablename"   , this.getTablename    );
			decorated.$methodInjector( "getName"        , this.getName         );
			decorated.$methodInjector( "getDbAdapter"   , this.getDbAdapter    );
			decorated.$methodInjector( "onMissingMethod", this.onMissingMethod );

			StructDelete( decorated, "$methodInjector" );
		}

		return decorated;
	}

// METHODS WITH WHICH TO DECORATE
	public any function onMissingMethod( required string missingMethodName, required struct missingMethodArguments ) output=false {
		var proxyMethods = "dataExists,fieldExists,selectData,selectManyToManyData,insertData,insertDataFromSelect,updateData,deleteData,getObjectProperties,getIdField,getLabelField,getDateCreatedField,getDateModifiedField";
		var i            = 1;

		if ( ListFindNoCase( proxyMethods, missingMethodName ) ) {
			if ( StructKeyExists( missingMethodArguments, "1" ) ) {
				for( var i=StructCount( missingMethodArguments ); i gt 0; i-- ) {
					missingMethodArguments[ i+1 ] = missingMethodArguments[ i ];
				}
				missingMethodArguments[ 1 ] = this._objectName;
			} else {
				missingMethodArguments.objectName = this._objectName;
			}

			return this._presideObjectService[ missingMethodName ]( argumentCollection = missingMethodArguments );
		}

		throw( type="PresideObject.MissingMethod", message="The preside object, [#this._objectName#], has no method with name, [#missingMethodName#]" );
	}

	public string function getDsn() output=false {
		return this._dsn;
	}

	public string function getName() output=false {
		return this._objectName;
	}

	public string function getTablename() output=false {
		return this._tableName;
	}

	public any function getDbAdapter() {
		return this._presideObjectService.getDbAdapterForObject( this._objectName );
	}

	public void function $methodInjector( required string methodName, required any method ) output=false {
		// assign to both variables and this scopes - so as to be available privately without specifying the THIS scope! (a bit hackish wouldn't you say)
		this[ methodName ]      = method;
		variables[ methodName ] = method;
	}
}