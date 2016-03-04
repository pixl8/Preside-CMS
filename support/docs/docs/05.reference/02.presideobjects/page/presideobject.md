---
id: "presideobject-page"
title: "Sitetree Page"
---

## Overview


The page object represents the core data that is stored for all pages in the site tree, regardless of page type.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  page</td></tr><tr><th>Table name</th><td>  psys_page</td></tr><tr><th>Path</th><td>  /preside-objects/core/page.cfc</td></tr></table></div>

## Properties


```luceescript
property name="title"        type="string"  dbtype="varchar"  maxLength="200" required=true control="textinput";
property name="main_content" type="string"  dbtype="text"                     required=false;
property name="teaser"       type="string"  dbtype="varchar"  maxLength="500" required=false;
property name="slug"         type="string"  dbtype="varchar"  maxLength="50"  required=false uniqueindexes="slug|2" format="slug";
property name="page_type"    type="string"  dbtype="varchar"  maxLength="100" required=true                                             control="pageTypePicker" indexes="pagetype";
property name="layout"       type="string"  dbtype="varchar"  maxLength="100" required=false                                            control="pageLayoutPicker";
property name="sort_order"   type="numeric" dbtype="int"                      required=true                                             control="none";
property name="active"       type="boolean" dbtype="boolean"                  required=false default=false;
property name="trashed"      type="boolean" dbtype="boolean"                  required=false default=false control="none";
property name="old_slug"     type="string"  dbtype="varchar" maxLength="50"   required=false;

property name="main_image"  relationship="many-to-one" relatedTo="asset"                   required=false allowedTypes="image";
property name="parent_page" relationship="many-to-one" relatedTo="page"                    required=false                     uniqueindexes="slug|1" control="none";
property name="created_by"  relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId";
property name="updated_by"  relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId";

property name="internal_search_access"                  type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" format="regex:(inherit|allow|block)"        control="select"          values="inherit,allow,block" labels="preside-objects.page:internal_search_access.option.inherit,preside-objects.page:internal_search_access.option.allow,preside-objects.page:internal_search_access.option.deny";
property name="search_engine_access"                    type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" format="regex:(inherit|allow|block)"        control="select"          values="inherit,allow,block"       labels="preside-objects.page:search_engine_access.option.inherit,preside-objects.page:search_engine_access.option.allow,preside-objects.page:search_engine_access.option.deny";
property name="author"                                  type="string"  dbtype="varchar" maxLength="100"  required=false;
property name="browser_title"                           type="string"  dbtype="varchar" maxLength="100"  required=false;
property name="description"                             type="string"  dbtype="varchar" maxLength="255"  required=false;
property name="embargo_date"                            type="date"    dbtype="datetime"                 required=false                                                               control="datetimepicker";
property name="expiry_date"                             type="date"    dbtype="datetime"                 required=false                                                               control="datetimepicker";
property name="access_restriction"                      type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" format="regex:(inherit|none|full|partial)"  control="select"          values="inherit,none,full,partial" labels="preside-objects.page:access_restriction.option.inherit,preside-objects.page:access_restriction.option.none,preside-objects.page:access_restriction.option.full,preside-objects.page:access_restriction.option.partial";
property name="full_login_required"                     type="boolean" dbtype="boolean"                  required=false default=false;
property name="grantaccess_to_all_logged_in_users"      type="boolean" dbtype="boolean"                  required=false default=false;
property name="exclude_from_navigation"                 type="boolean" dbtype="boolean"                  required=false default=false;
property name="exclude_from_navigation_when_restricted" type="boolean" dbtype="boolean"                  required=false default=false;
property name="exclude_from_sub_navigation"             type="boolean" dbtype="boolean"                  required=false default=false;
property name="exclude_children_from_navigation"        type="boolean" dbtype="boolean"                  required=false default=false;
property name="exclude_from_sitemap"                    type="boolean" dbtype="boolean"                  required=false default=false;
property name="navigation_title"                        type="string"  dbtype="varchar" maxLength="200"  required=false;

property name="_hierarchy_id"                    type="numeric" dbtype="int"     maxLength="0"    required=true                                                            uniqueindexes="hierarchyId";
property name="_hierarchy_sort_order"            type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="sortOrder";
property name="_hierarchy_lineage"               type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="lineage";
property name="_hierarchy_child_selector"        type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none";
property name="_hierarchy_depth"                 type="numeric" dbtype="int"                      required=true                                             control="none" indexes="depth";
property name="_hierarchy_slug"                  type="string"  dbtype="varchar" maxLength="2000" required=true                                             control="none";

property name="child_pages" relationship="one-to-many" relatedTo="page" relationshipKey="parent_page";

```

## Public API Methods


* [[page-updatechildhierarchyhelpers]]