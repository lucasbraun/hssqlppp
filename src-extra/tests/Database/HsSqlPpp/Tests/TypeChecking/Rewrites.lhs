test adding qualifiers, tableref aliases, expanding *, adding select
item aliases

> module Database.HsSqlPpp.Tests.TypeChecking.Rewrites
>     (rewrites) where

> import Database.HsSqlPpp.Tests.TypeChecking.Utils
> --import Database.HsSqlPpp.Types
> import Database.HsSqlPpp.Catalog
> import Database.HsSqlPpp.TypeChecker



> rewrites :: Item
> rewrites =
>   Group "rewrites"
>   [RewriteQueryExpr defaultTypeCheckingFlags {tcfAddSelectItemAliases = True}
>          [CatCreateTable "t" [("a", "int4")
>                              ,("b", "text")]]
>    "select a,b from t"
>    "select a as a,b as b from t"

>   ,RewriteQueryExpr defaultTypeCheckingFlags {tcfExpandStars = True}
>          [CatCreateTable "t" [("a", "int4")
>                              ,("b", "text")]]
>    "select * from t"
>    "select t.a,t.b from t"

>   {-,RewriteQueryExpr defaultTypeCheckingFlags {tcfAddFullTablerefAliases = True}
>          [CatCreateTable "t" [("a", "int4")
>                              ,("b", "text")]]
>    "select * from t"
>    "select * from t as t(a,b)"-}

>   ,RewriteQueryExpr defaultTypeCheckingFlags {tcfAddQualifiers = True}
>          [CatCreateTable "t" [("a", "int4")
>                              ,("b", "text")]]
>    "select a,b from t"
>    "select t.a,t.b from t"

>   {-,RewriteQueryExpr defaultTypeCheckingFlags {tcfAddQualifiers = True
>                                              ,tcfAddSelectItemAliases = True
>                                              ,tcfExpandStars = True
>                                              ,tcfAddFullTablerefAliases = True}
>          [CatCreateTable "t" [("a", "int4")
>                              ,("b", "text")]]
>    "select * from t"
>    "select t.a as a,t.b as b from t as t(a,b)"-}

>   ]