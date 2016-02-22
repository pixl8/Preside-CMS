---
id: "presideobject-password_policy"
title: "Password policy"
---

## Overview


A password policy for a given context includes simple rules around password requirements

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  password_policy</td></tr><tr><th>Table name</th><td>  psys_password_policy</td></tr><tr><th>Path</th><td>  /preside-objects/admin/security/password_policy.cfc</td></tr></table></div>

## Properties


```luceescript
property name="context"       type="string"  dbtype="varchar" required=true  maxlength="20" uniqueindexes="passwordpolicycontext";

property name="min_strength"  type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=100;
property name="min_length"    type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
property name="min_uppercase" type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
property name="min_numeric"   type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;
property name="min_symbols"   type="numeric" dbtype="int"     required=false default=0 minValue=0 maxValue=1000;

property name="message"       type="string"  dbtype="text"    required=false;

```