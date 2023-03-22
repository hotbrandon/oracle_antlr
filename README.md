## DBA_DEPENDENCY_COLUMNS

## http://rwijk.blogspot.com/2008/10/dbadependencycolumns.html

```sql

  CREATE OR REPLACE FORCE VIEW "ARGOERP"."DBA_DEPENDENCY_COLUMNS" ("OWNER", "NAME", "TYPE", "REFERENCED_OWNER", "REFERENCED_NAME", "REFERENCED_TYPE", "REFERENCED_LINK_NAME", "REFERENCED_COLUMN", "DEPENDENCY_TYPE") AS
  SELECT
        d.u_name                                                        owner,
        d.o_name                                                        name,
        decode(d.o_type#, 0, 'NEXT OBJECT', 1, 'INDEX',
               2, 'TABLE', 3, 'CLUSTER', 4,
               'VIEW', 5, 'SYNONYM', 6, 'SEQUENCE',
               7, 'PROCEDURE', 8, 'FUNCTION', 9,
               'PACKAGE', 10, 'NON-EXISTENT', 11, 'PACKAGE BODY',
               12, 'TRIGGER', 13, 'TYPE', 14,
               'TYPE BODY', 22, 'LIBRARY', 28, 'JAVA SOURCE',
               29, 'JAVA CLASS', 32, 'INDEXTYPE', 33,
               'OPERATOR', 42, 'MATERIALIZED VIEW', 43, 'DIMENSION',
               46, 'RULE SET', 55, 'XML SCHEMA', 56,
               'JAVA DATA', 59, 'RULE', 62, 'EVALUATION CONTXT',
               92, 'CUBE DIMENSION', 93, 'CUBE', 94,
               'MEASURE FOLDER', 95, 'CUBE BUILD PROCESS', 'UNDEFINED') type,
        nvl2(d.po_linkname, d.po_remoteowner, d.pu_name)                referenced_owner,
        d.po_name                                                       referenced_name,
        decode(d.po_type#, 0, 'NEXT OBJECT', 1, 'INDEX',
               2, 'TABLE', 3, 'CLUSTER', 4,
               'VIEW', 5, 'SYNONYM', 6, 'SEQUENCE',
               7, 'PROCEDURE', 8, 'FUNCTION', 9,
               'PACKAGE', 10, 'NON-EXISTENT', 11, 'PACKAGE BODY',
               12, 'TRIGGER', 13, 'TYPE', 14,
               'TYPE BODY', 22, 'LIBRARY', 28, 'JAVA SOURCE',
               29, 'JAVA CLASS', 32, 'INDEXTYPE', 33,
               'OPERATOR', 42, 'MATERIALIZED VIEW', 43, 'DIMENSION',
               46, 'RULE SET', 55, 'XML SCHEMA', 56,
               'JAVA DATA', 59, 'RULE', 62, 'EVALUATION CONTXT',
               92, 'CUBE DIMENSION', 93, 'CUBE', 94,
               'MEASURE FOLDER', 95, 'CUBE BUILD PROCESS', 'UNDEFINED') referenced_type,
        d.po_linkname                                                   referenced_link_name,
        c.name                                                          referenced_column,
        decode(bitand(d.d_property, 3),
               2,
               'REF',
               'HARD')                                                  dependency_type
    FROM
        (
            SELECT
                obj#,
                u_name,
                o_name,
                o_type#,
                pu_name,
                po_name,
                po_type#,
                po_remoteowner,
                po_linkname,
                d_property,
                colpos
            FROM
                sys."_CURRENT_EDITION_OBJ" o,
                sys.disk_and_fixed_objects po,
                sys.dependency$            d,
                sys.user$                  u,
                sys.user$                  pu
            WHERE
                    o.obj# = d.d_obj#
                AND o.owner# = u.user#
                AND po.obj# = d.p_obj#
                AND po.owner# = pu.user#
                AND d.d_attrs IS NOT NULL
            MODEL RETURN UPDATED ROWS
                PARTITION BY ( po.obj# obj#, u.name u_name, o.name o_name, o.type# o_type#, po.linkname po_linkname, pu.name pu_name,
                po.remoteowner po_remoteowner, po.name po_name, po.type# po_type#, d.property d_property ) DIMENSION BY ( 0 i )
                MEASURES ( 0 colpos, substr(d.d_attrs, 9) attrs )
                RULES ITERATE(1000) UNTIL(iteration_number = 4 * length(attrs[0]) - 2) ( colpos[iteration_number + 1]=
                    CASE bitand(TO_NUMBER(substr(attrs[0],
                                                 1 + 2 * trunc((iteration_number + 1) / 8),
                                                 2),
          'XX'),
                                power(2,
                                      mod(iteration_number + 1, 8)))
                        WHEN 0 THEN
                            NULL
                        ELSE
                            iteration_number + 1
                    END
                )
        )        d,
        sys.col$ c
    WHERE
            d.obj# = c.obj#
        AND d.colpos = c.col#;
```

## using DBA_DEPENDENCY_COLUMNS view

```sql
SELECT
    *
FROM
    dba_dependency_columns
WHERE
        owner = 'ARGOERP'
    AND type = 'FUNCTION' -- OR PROCEDURE, PACKAGE BODY, VIEW, TRIGGER
    AND name = 'F_CTAF008_2'
ORDER BY
    referenced_name,
    referenced_column;
```
