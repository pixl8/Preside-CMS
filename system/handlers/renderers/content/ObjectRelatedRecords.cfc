component {

	property name="adminDataViewsService" inject="adminDataViewsService";
	property name="presideObjectService"  inject="presideObjectService";

	public string function adminView( event, rc, prc, args={} ){
		return renderViewlet( event="admin.dataHelpers.relatedRecordsDatatable", args=args );
	}

}