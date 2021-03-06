
> {-# LANGUAGE OverloadedStrings #-}
> module Database.HsSqlPpp.Tests.Parsing.Dml (dml) where
>
> import Database.HsSqlPpp.Syntax

> import Database.HsSqlPpp.Tests.Parsing.Utils
> import Database.HsSqlPpp.Tests.TestTypes

TODO:

from in update, using in delete (+ type check these)

> dml:: Item
> dml =
>    Group "dml" [
>      Group "insert" [
>       s "insert into testtable\n\
>         \(columna,columnb)\n\
>         \values (1,2);\n"
>        [Insert ea
>         (name "testtable")
>         [Nmc "columna", Nmc "columnb"]
>         (Values ea [[num "1", num "2"]])
>         Nothing]

multi row insert, test the stand alone values statement first, maybe
that should be in the select section?

>      ,s "values (1,2), (3,4);"
>      [QueryStatement ea $ Values ea [[num "1", num "2"]
>                                     ,[num "3", num "4"]]]
>
>      ,s "insert into testtable\n\
>         \(columna,columnb)\n\
>         \values (1,2), (3,4);\n"
>       [Insert ea
>         (name "testtable")
>         [Nmc "columna", Nmc "columnb"]
>         (Values ea [[num "1", num "2"]
>                    ,[num "3", num "4"]])
>         Nothing]

insert from select

>      ,s "insert into a\n\
>          \    select b from c;"
>       [Insert ea (name "a") []
>        (makeSelect
>         {selSelectList = sl [si $ ei "b"]
>         ,selTref = [tref "c"]})
>        Nothing]
>
>      ,s "insert into testtable\n\
>         \(columna,columnb)\n\
>         \values (1,2) returning id;\n"
>       [Insert ea
>         (name "testtable")
>         [Nmc "columna", Nmc "columnb"]
>         (Values ea [[num "1", num "2"]])
>         (Just $ sl [si $ ei "id"])]
>      ]
>
>     ,Group "update" [
>       s "update tb\n\
>         \  set x = 1, y = 2;"
>       [Update ea (name "tb") [set "x" $ num "1"
>                             ,set "y" $ num "2"]
>        [] Nothing Nothing]
>      ,s "update tb\n\
>         \  set x = 1, y = 2 where z = true;"
>       [Update ea (name "tb") [set "x" $ num "1"
>                             ,set "y" $ num "2"]
>        []
>        (Just $ binop "=" (ei "z") lTrue)
>        Nothing]
>      ,s "update tb\n\
>         \  set x = 1, y = 2 returning id;"
>       [Update ea (name "tb") [set "x" $ num "1"
>                             ,set "y" $ num "2"]
>        [] Nothing (Just $ sl [si $ ei "id"])]
>      ,s "update tb\n\
>         \  set (x,y) = (1,2);"
>       [Update ea (name "tb")
>        [MultiSetClause ea [Nmc "x",Nmc "y"]
>         $ specop "rowctor" [num "1"
>                             ,num "2"]]
>        []
>        Nothing Nothing]
>      ]

App ea "=" [App ea "rowctor" [Identifier ea "x",Identifier ea "y"],App ea "rowctor" [num "1",num "2"]])


>
>     ,Group "delete" [
>       s "delete from tbl1 where x = true;"
>       [Delete ea (name "tbl1") [] (Just $ binop "=" (ei "x") lTrue)
>        Nothing]
>      ,s "delete from tbl1 where x = true returning id;"
>       [Delete ea (name "tbl1") [] (Just $ binop "=" (ei "x") lTrue)
>        (Just $ sl [si $ ei "id"])]
>      ]
>
>     ,Group "truncate" [
>       s "truncate test;"
>        [Truncate ea [name "test"] ContinueIdentity Restrict]
>
>      ,s "truncate table test, test2 restart identity cascade;"
>        [Truncate ea [name "test",name "test2"] RestartIdentity Cascade]
>      ]

copy, bit crap at the moment

>     ,Group "copy" [
>       s "copy tbl(a,b) from stdin;\n\
>         \bat\tt\n\
>         \bear\tf\n\
>         \\\.\n"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"] Stdin []
>        ,CopyData ea "\
>         \bat\tt\n\
>         \bear\tf\n"]
>      ,s "copy tbl (a,b) from 'filename' with delimiter '|';"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"]
>       (CopyFilename "filename")
>        [CopyDelimiter "|"]]
>      ,s "copy tbl (a,b) from 'filename' with delimiter '|' parsers 'b=oracle';"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"]
>       (CopyFilename "filename")
>        [CopyDelimiter "|",CopyParsers "b=oracle"]]
>      ,s "copy tbl (a,b) from 'filename' with delimiter '|' error_log 'errors.log';"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"]
>       (CopyFilename "filename")
>        [CopyDelimiter "|", CopyErrorLog "errors.log"]]
>      ,s "copy tbl (a,b) from 'filename' with delimiter '|' error_log 'errors.log' error_verbosity 1;"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"]
>       (CopyFilename "filename")
>        [CopyDelimiter "|", CopyErrorLog "errors.log", CopyErrorVerbosity 1]]
>      ,s "copy tbl (a,b) from 'filename' with delimiter '|' error_log 'errors.log' error_verbosity 1 parsers 'b=oracle';"
>       [CopyFrom ea (name "tbl") [Nmc "a", Nmc "b"]
>       (CopyFilename "filename")
>        [CopyDelimiter "|", CopyErrorLog "errors.log", CopyErrorVerbosity 1,CopyParsers "b=oracle"]]
>      ,s "copy tbl to 'file';"
>       [CopyTo ea (CopyTable (name "tbl") []) "file" []]
>      ,s "copy tbl(a,b) to 'file';"
>       [CopyTo ea (CopyTable (name "tbl") [Nmc "a", Nmc "b"]) "file" []]
>      ,s "copy (select * from tbl) to 'file' with format binary;"
>       [CopyTo ea (CopyQuery $ makeSelect {selSelectList = sl [si $ Star ea]
>                                          ,selTref = [tref "tbl"]})
>        "file" [CopyFormat "binary"]]
>      ]]
>  where
>    s = ParseStmts defaultParseFlags
