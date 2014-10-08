Sitetree Page
=============

Overview
--------

The page object represents the core data that is stored for all pages in the site tree, regardless of page type.

**Object name:**
    page

**Table name:**
    psys_page

**Path:**
    /preside-objects/core/page.cfc

Properties
----------

.. code-block:: java

    property name="title"        type="string"  dbtype="varchar"  maxLength="200" required=true control="textinput";
    property name="main_content" type="string"  dbtype="text"                     required=false;
    property name="teaser"       type="string"  dbtype="varchar"  maxLength="500" required=false;
    property name="slug"         type="string"  dbtype="varchar"  maxLength="50"  required=false uniqueindexes="slug|2" format="slug";
    property name="page_type"    type="string"  dbtype="varchar"  maxLength="100" required=true                                             control="pageTypePicker";
    property name="layout"       type="string"  dbtype="varchar"  maxLength="100" required=false                                            control="pageLayoutPicker";
    property name="sort_order"   type="numeric" dbtype="int"                      required=true                                             control="none";
    property name="active"       type="boolean" dbtype="boolean"                  required=false default=false;
    property name="trashed"      type="boolean" dbtype="boolean"                  required=false default=false control="none";
    property name="old_slug"     type="string"  dbtype="varchar" maxLength="50"   required=false;

    property name="main_image"  relationship="many-to-one" relatedTo="asset"                   required=false allowedTypes="image";
    property name="parent_page" relationship="many-to-one" relatedTo="page"                    required=false                     uniqueindexes="slug|1" control="none";
    property name="created_by"  relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId";
    property name="updated_by"  relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId";

    property name="search_engine_access"             type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" format="regex:(inherit|allow|block)"        control="select"          values="inherit,allow,block"       labels="preside-objects.page:search_engine_access.option.inherit,preside-objects.page:search_engine_access.option.allow,preside-objects.page:search_engine_access.option.deny";
    property name="author"                           type="string"  dbtype="varchar" maxLength="100"  required=false;
    property name="browser_title"                    type="string"  dbtype="varchar" maxLength="100"  required=false;
    property name="description"                      type="string"  dbtype="varchar" maxLength="255"  required=false;
    property name="embargo_date"                     type="date"    dbtype="datetime"                 required=false                                                               control="datetimepicker";
    property name="expiry_date"                      type="date"    dbtype="datetime"                 required=false                                                               control="datetimepicker";
    property name="access_restriction"               type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" format="regex:(inherit|none|full|partial)"  control="select"          values="inherit,none,full,partial" labels="preside-objects.page:access_restriction.option.inherit,preside-objects.page:access_restriction.option.none,preside-objects.page:access_restriction.option.full,preside-objects.page:access_restriction.option.partial";
    property name="full_login_required"              type="boolean" dbtype="boolean"                  required=false default=false;
    property name="exclude_from_navigation"          type="boolean" dbtype="boolean"                  required=false default=false;
    property name="exclude_children_from_navigation" type="boolean" dbtype="boolean"                  required=false default=false;
    property name="navigation_title"                 type="string"  dbtype="varchar" maxLength="200"  required=false;

    property name="_hierarchy_id"                    type="numeric" dbtype="int"     maxLength="0"    required=true                                                            uniqueindexes="hierarchyId";
    property name="_hierarchy_sort_order"            type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="sortOrder";
    property name="_hierarchy_lineage"               type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="lineage";
    property name="_hierarchy_child_selector"        type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none";
    property name="_hierarchy_depth"                 type="numeric" dbtype="int"                      required=true                                             control="none" indexes="depth";
    property name="_hierarchy_slug"                  type="string"  dbtype="varchar" maxLength="2000" required=true                                             control="none";


Public API Methods
------------------

.. _page-updatechildhierarchyhelpers:

UpdateChildHierarchyHelpers()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function updateChildHierarchyHelpers( required query oldData, required struct newData )

This method is used internally by the Sitetree Service to ensure
that all child nodes of a page have the most up to date helper fields when the parent node
changes.
This is implemented using some funky SQL that was beyond the capabilities of the standard
Preside Object Service CRUD methods.

Arguments
.........

=======  ======  ========  =======================================================
Name     Type    Required  Description                                            
=======  ======  ========  =======================================================
oldData  query   Yes       Query record of the old parent node data               
newData  struct  Yes       Struct containing the changed fields on the parent node
=======  ======  ========  =======================================================
