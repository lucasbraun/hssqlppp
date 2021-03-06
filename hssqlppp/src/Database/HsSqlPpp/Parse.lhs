
Forward the public part of ParserInternal

> -- | Functions to parse SQL.

> module Database.HsSqlPpp.Parse
>     (-- * Main
>      parseStatements
>     ,parseProcSQL
>     ,parseQueryExpr
>     ,parseScalarExpr
>      -- * Parsing options
>     ,ParseFlags(..)
>     ,defaultParseFlags
>     ,Dialect(..)
>     ,ansiDialect
>      -- * errors
>     ,ParseErrorExtra(..)
>      -- * internals
>     ,parseName
>     ,parseNameComponent
>
>      -- * added by lucasbraun in order to extend API
>     ,Statement(..)
>     ,QueryExpr(..)
>     ,SelectList(..)
>     ,SelectItem(..)
>     ,SelectItemList
>     ,Distinct(..)
>     ,ScalarExpr(..)
>     ,TableRef(..)
>     ,TableRefList
>     ,Name(..)
>     ,NameComponent(..)
>     ,ScalarExprList
>     ,ScalarExprDirectionPair
>     ,ScalarExprDirectionPairList
>     ,CaseScalarExprListScalarExprPairList
>     ,InList(..)
>     ,JoinExpr(..)
>     -- * end of extended API by lucasbraun 
>
>     ) where
>
> import Database.HsSqlPpp.Internals.ParseInternal
> import Database.HsSqlPpp.Internals.ParseErrors
> import Database.HsSqlPpp.Dialects.Ansi
> import Database.HsSqlPpp.Internals.Dialect
> import Database.HsSqlPpp.Internals.AstInternal

> defaultParseFlags :: ParseFlags
> defaultParseFlags = ParseFlags {pfDialect = ansiDialect}
