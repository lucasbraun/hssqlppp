Copyright 2010 Jake Wheat

Convert the Chaos 2010 example sql to html, and do some stuff with
hssqlppp to it and show the results.

> module Database.HsSqlPpp.DevelTools.DoChaosSql
>     (doChaosSql) where
>
> import System.FilePath.Find
> import System.FilePath
>
> import Database.HsSqlPpp.DevelTools.PandocUtils
>
> doChaosSql :: (PandocType
>                -> String
>                -> Input
>                -> String
>                -> IO ())
>            -> IO ()
> doChaosSql pf = do
>   -- create html versions
>   sourceFiles >>= mapM_ convFile
>   -- create short index
>   return ()
>   where
>     sourceFiles = do
>       find always sourceFileP "testfiles/chaos2010sql/"
>     sourceFileP = extension ==? ".sql" ||? extension ==? ".txt"
>     convFile f = do
>       pf (case takeExtension f of
>             ".txt" -> Txt
>             ".sql" -> Sql
>             _ -> error $ "unrecognised extension in dochaosql" ++ f)
>          (snd $splitFileName f)
>          (File f)
>          (f ++ ".html")

TODO:

use the new annotate, then we can present the original pristine
source, and the source that has been scribbled all over by hsssqlppp.

add a separate page to summarize the resulant catalog, use the modules
to split this into sections. When the export lists are done, use this
to divide each section into public, private.

add a separate page to list the type errors with links to the source
where they occur (both the original and mangled source)
