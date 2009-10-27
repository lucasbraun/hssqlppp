Copyright 2009 Jake Wheat

Wrappers used in the command line program

> {-# LANGUAGE FlexibleContexts #-}

> module Database.HsSqlPpp.Commands.Commands where

> import Control.Monad.Error
> import System
> import Data.List

> import Text.Show.Pretty
> import System.Process.Pipe

> import Database.HsSqlPpp.Parsing.Parser
> import Database.HsSqlPpp.Parsing.Lexer

> import Database.HsSqlPpp.Ast.Annotator
> import Database.HsSqlPpp.Ast.Annotation
> import Database.HsSqlPpp.Ast.Environment
> import Database.HsSqlPpp.Ast.Ast
> import Database.HsSqlPpp.Ast.SqlTypes

> import Database.HsSqlPpp.PrettyPrinter.PrettyPrinter
> import Database.HsSqlPpp.PrettyPrinter.AnnotateSource

> import Database.HsSqlPpp.Dbms.DBAccess
> import Database.HsSqlPpp.Dbms.DatabaseLoader

> import Database.HsSqlPpp.Extensions.ChaosExtensions


================================================================================

read file as string - issues are:
not sure the return type should be string,string, put this in to pass
to loadsql so that it knows the source file

want to support reading from stdin, and reading from a string passed
as an argument to the exe

> readInput :: (Error e, MonadIO m) => String -> ErrorT e m (String,String)
> readInput f =
>   liftIO $ readFile f >>= \l -> return (f,l)

===============================================================================

parsing

> lexSql :: Monad m => String -> String -> ErrorT AllErrors m [Token]
> lexSql f s = return (lexSqlText f s) >>= throwEEEither

> parseSql1 :: Monad m => String -> String -> ErrorT AllErrors m StatementList
> parseSql1 f s = return (parseSql f s) >>= throwEEEither

================================================================================

> runExtensions :: (Monad m, Error e) => StatementList -> ErrorT e m StatementList
> runExtensions = return . extensionize

================================================================================

annotation ish

> stripAnn :: (Monad m, Error e) => StatementList -> ErrorT e m StatementList
> stripAnn s = return $ stripAnnotations s

still not sure what to call this command, maybe it should be type check?

> annotate :: (Monad m, Error e) => Environment -> StatementList
>          -> ErrorT e m (Environment, StatementList)
> annotate cat ast = return $ annotateAstEnvEnv cat ast

could probably make this more general, so can run an arbitrary filter
on annotations and get then back with source positions

> getTEs :: (Monad m, Error e) =>
>           StatementList -> ErrorT e m [(Maybe AnnotationElement,[TypeError])]
> getTEs ast = return $ getTypeErrors ast

> ppTypeErrors :: Monad m =>
>                 [(Maybe AnnotationElement, [TypeError])] -> m [String]
> ppTypeErrors tes =
>   return $ map showSpTe tes
>   where
>     showSpTe (Just (SourcePos fn l c), e) =
>         fn ++ ":" ++ show l ++ ":" ++ show c ++ ":\n" ++ show e
>     showSpTe (_,e) = "unknown:0:0:\n" ++ show e

================================================================================

pretty printing

todo: change the naming convention, so fns which produce haskell
syntax start with show, human readable stuff starts with pp, not sure
where printsql comes in system though

> ppSh :: (Monad m, Error e, Show a) => a -> ErrorT e m String
> ppSh = return . ppShow

> ppSql :: (Monad m, Error e) => StatementList -> ErrorT e m String
> ppSql = return . printSql

> ppAnnOrig :: (Monad m, Error e) => Bool -> String -> StatementList -> ErrorT e m String
> ppAnnOrig doErrs fn ast = return $ annotateSource doErrs fn ast

================================================================================

errort stuff

wrap all our errors in an algebraic data type, not sure if there is a
more elegant way of doing this but it does the job for now

> data AllErrors = AEExtendedError ExtendedError
>                | AETypeErrors [TypeError]
>                | AEMisc String
>                  deriving (Show)

> instance Error AllErrors where
>   noMsg = AEMisc "Unknown error"
>   strMsg str = AEMisc str

> throwEEEither :: (MonadError AllErrors m) => Either ExtendedError a -> m a
> throwEEEither (Left err) = throwError $ AEExtendedError err
> throwEEEither (Right val) = return val

> throwTESEither :: (MonadError AllErrors m) => Either [TypeError] a -> m a
> throwTESEither (Left err) = throwError $ AETypeErrors err
> throwTESEither (Right val) = return val

================================================================================

dbms utilities

> readCatalog :: MonadIO m => String -> ErrorT AllErrors m Environment
> readCatalog dbName =
>   liftIO (readEnvironmentFromDatabase dbName) >>=
>   throwTESEither . updateEnvironment defaultEnvironment

> loadSqlUsingPsql :: MonadIO m  => String -> String -> ErrorT AllErrors m String
> loadSqlUsingPsql dbName script = do
>   liftIO $ pipeString [("psql", [dbName
>                                 ,"-q"
>                                 ,"--set"
>                                 ,"ON_ERROR_STOP=on"
>                                 ,"--file=-"])] script

> loadSqlUsingPsqlFromFile :: MonadIO m  => String -> String -> ErrorT AllErrors m String
> loadSqlUsingPsqlFromFile dbName fn = do
>   ex <- liftIO $ system ("psql " ++ dbName ++
>                 " -q --set ON_ERROR_STOP=on" ++
>                 " --file=" ++ fn)
>   case ex of
>     ExitFailure e -> throwError $ AEMisc $ "psql failed with " ++ show e
>     ExitSuccess -> return ""

> loadAst :: (MonadIO m, Error e) => String -> String -> StatementList -> ErrorT e m ()
> loadAst db fn ast = liftIO $ loadIntoDatabase db fn ast

> clearDB :: MonadIO m => String -> ErrorT AllErrors m ()
> clearDB db =
>   liftIO $ withConn ("dbname=" ++ db) $ \conn ->
>     runSqlCommand conn "drop owned by jake cascade;"

> pgDump :: MonadIO m => String -> ErrorT AllErrors m String
> pgDump db = liftIO $ pipeString [("pg_dump", [db
>                                              ,"--schema-only"
>                                              ,"--no-owner"
>                                              ,"--no-privileges"])] ""


> {-runSqlScript :: String -> String -> IO ()
> runSqlScript dbName script = do
>   ex <- system ("psql " ++ dbName ++
>                 " -q --set ON_ERROR_STOP=on" ++
>                 " --file=" ++ script)
>   case ex of
>     ExitFailure e -> error $ "psql failed with " ++ show e
>     ExitSuccess -> return ()
>   return ()-}

================================================================================

catalog stuff - just a diff to compare two catalogs

> data CatDiff = CatDiff [EnvironmentUpdate] [EnvironmentUpdate]
>                deriving Show

> compareCatalogs :: (Monad m, Error e) => Environment -> Environment -> Environment -> ErrorT e m CatDiff
> compareCatalogs base start end =
>         let baseEnvBits = deconstructEnvironment base
>             startEnvBits = deconstructEnvironment start \\ baseEnvBits
>             endEnvBits = deconstructEnvironment end \\ baseEnvBits
>             missing = sort $ endEnvBits \\ startEnvBits
>             extras = sort $ startEnvBits \\ endEnvBits
>         in return $ CatDiff missing extras

> ppCatDiff :: (Monad m, Error e) => CatDiff -> ErrorT e m String
> ppCatDiff (CatDiff missing extra) =
>           return $ "\nmissing:\n"
>                    ++ intercalate "\n" (map ppEnvUpdate missing)
>                    ++ "\nextra:\n"
>                    ++ intercalate "\n" (map ppEnvUpdate extra)

================================================================================

Utilities

> message :: MonadIO m => String -> m ()
> message x = liftIO (putStrLn x)

run in errort monad
should think of something better to do here than just rethrow as io error1

> wrapET :: (Show e, Monad m) => ErrorT e m a -> m a
> wrapET c = runErrorT c >>= \x ->
>          case x of
>            Left er -> error $ show er
>            Right l -> return l

> throwEither :: (MonadError t m) => Either t a -> m a
> throwEither (Left err) = throwError err
> throwEither (Right val) = return val

print a list, using newlines instead of commas, no outer []

> printList :: (MonadIO m, Show a) => [a] -> m ()
> printList = mapM_ (liftIO . print)

> putStrLnList :: MonadIO m => [String]-> m ()
> putStrLnList = mapM_ (liftIO . putStrLn)

> lfst :: (Monad m, Error e) => (a,b) -> ErrorT e m a
> lfst = return . fst

> lsnd :: (Monad m, Error e) => (a,b) -> ErrorT e m b
> lsnd = return . snd

> lconcat :: (Monad m, Error e) => [[a]] -> ErrorT e m [a]
> lconcat as = return $ concat as
