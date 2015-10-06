# fn-dhis2
This is an adapter for DHIS2, intended to be used with OpenFn, but built to stand alone.

It follows the same basic pattern as [fn-salesforce](https://github.com/OpenFn/fn-salesforce):
  
  - allow user to fetch meta-data from DHIS2 in the form of [JSON-schema](JSON-schema.org)
  - receive JSON data from user and run inserts/updates/upserts on DHIS2, based a `credentials.json` file

Stu's Thoughts:
-------------------
1. Start with "fn-push" given some JSON, try to insert in DHIS2.
2. Then with "fn-describe" fetch JSON scema for a given object in DHIS2.
3. Finally, "fn-prepare" flattens the JSON push and maps the dependencies — this is ready to be inserted piece by piece.

Our API
-----------------------------------
must work with basic actions (as seen in [fn-salesforce/lib/salesforce.rb](https://github.com/OpenFn/fn-salesforce/blob/master/lib/fn/salesforce.rb))

1. fn-describe (takes credentials and an object name, returns a destination schema)
2. fn-prepare (takes a JSON payload and a destination schema, returns a "plan")
3. fn-push (takes a plan and credentials, inserts records into DHIS2)




Resources
----------------------
1. [live hosted DHIS2 demo](https://apps.dhis2.org/demo/dhis-web-dashboard-integration/index.action): un=admin,pw=district;
2. [DHIS2 metadata api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s06.html): this is needed to fetch JSON-schema compliant schemas for objects that we plan to create or update. Works similar to the "describe" method in [fn-salesforce](https://github.com/OpenFn/fn-salesforce#describe);
3. [DHIS2 data-values api](https://www.dhis2.org/doc/snapshot/en/developer/html/ch01s11.html);
 
***WIP...***


