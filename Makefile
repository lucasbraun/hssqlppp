
# you can build the library using cabal configure && cabal build
# more info here: http://jakewheat.github.com/hssqlppp/devel.txt.html

# this makefile uses gnu make syntax, not sure what other makes it
# works with

# this makefile can be used:
# * when the .ag files are altered to rebuild the hs
# * to build/ run the tests
# * to build all the examples
# * to build/run other development utils

# the default make target is to build the automated tests exe

########################################################

# developing with the make file:

# to add new source folder, adjust the SRC_DIRS var below to add a new
# package, adjust the PACKAGES var below all compiles share the same
# package list and source folders atm

# to add a new binary to build, add it to EXE_FILES below

# if you change the local imports, or add a new binary you need to
# regenerate the dependencies manually: run 'make depend exe_depend'
# if the dependency files get mangled so you can't run this, try
# deleting .depend.mk and .exe_rules.mk then running 'make depend
# exe_depend'

# if you alter the catalog type or any other dependencies, you may
# need to regenerate the defaultTemplate1Catalog module, this is
# never automatic, use 'make regenDefaultTemplate1Catalog'

# the reason regenDefaultTemplate1Catalog and depend and exe_depend
# are manual only is because they are very slow

######################################################

# this makefile is probably written wrong since I don't know how to do
# makefiles

HC              = ghc
HC_BASIC_OPTS   = -Wall -threaded -rtsopts
#-O2

# add new source roots to this
SRC_DIRS = src src-extra/catalogReader src-extra/chaos \
src-extra/devel-util src-extra/docutil src-extra/examples \
src-extra/extensions src-extra/h7c src-extra/tests \
src-extra/chaos/extensions src-extra/utils

space :=
space +=
comma := ,
HC_INCLUDE_DIRS = -i$(subst $(space),:,$(SRC_DIRS))

# you can compile the lib and tests without the last line of packages
# (HDBC HDBC-postgresql pandoc xhtml)

PACKAGES = haskell-src-exts uniplate mtl base containers parsec pretty \
	syb transformers template-haskell test-framework groom \
	test-framework-hunit HUnit \
	datetime split Diff text filepath directory bytestring \
	HDBC HDBC-postgresql #pandoc xhtml \
	#illuminate


HC_PACKAGES = -hide-all-packages -package base $(patsubst %,-package %,$(PACKAGES))

HC_OPTS = $(HC_BASIC_OPTS) $(HC_INCLUDE_DIRS) $(HC_PACKAGES)

# this is the list of exe files which are all compiled to check
# nothing has been broken. It doesn't include some of the makefile
# utilities below
# the set of .o files for each exe, and the build rule are generated
# by a utility (use make exe_depend) since ghc -M doesn't provide
# the list of .o files which an .lhs for an exe needs to build
# (ghc -M is used for all the dependencies other than the exes)

EXE_FILES = src-extra/tests/Tests \
	src-extra/devel-util/MakeDefaultTemplate1Catalog \
	src-extra/examples/MakeSelect \
	src-extra/examples/Parse \
	src-extra/examples/Parse2 \
	src-extra/examples/Parse3 \
	src-extra/examples/Lex \
	src-extra/examples/TypeCheck3 \
	src-extra/examples/TypeCheck2 \
	src-extra/examples/TypeCheck \
	src-extra/examples/TypeCheckDB \
	src-extra/examples/PPPTest \
	src-extra/h7c/h7c \
	src-extra/examples/FixSqlServerTpchSyntax \
	src-extra/examples/QQ
#	src-extra/docutil/DevelTool

#	src-extra/examples/ShowCatalog \
#	src-extra/chaos/build.lhs

# used for dependency generation with ghc -M
# first all the modules which are public in the cabal package
# this is all the hs files directly in the src/Database/HsSqlPpp/ folder
# then it lists the lhs for all the exe files
LIB_MODULES = $(shell find src/Database/HsSqlPpp/ -maxdepth 1 -iname '*hs')
SRCS_ROOTS = $(LIB_MODULES) $(addsuffix .lhs,$(EXE_FILES))

AG_FILES = $(shell find src -iname '*ag')

# include the autogenerated rules for the exes
-include .exe_rules.mk

# all rule just rebuilds the library like cabal does
all : $(LIB_MODULES)

#special targets

# run the tests
tests : src-extra/tests/Tests
	src-extra/tests/Tests --hide-successes

# make the website
website : src-extra/docutil/DevelTool
	src-extra/docutil/DevelTool makewebsite +RTS -N

# make the haddock and put in the correct place in the generated
# website
website_haddock :
	cabal configure
	cabal haddock
	-mkdir hssqlppp
	-rm -Rf hssqlppp/haddock
	mv dist/doc/html/hssqlppp hssqlppp/haddock

# task to build the chaos sql, which takes the source sql
# transforms it and produces something which postgres understands
CHAOS_SQL_SRC = $(shell find src-extra/chaos/sql/ -iname '*.sql')

chaos.sql : $(CHAOS_SQL_SRC) src-extra/h7c/h7c
	src-extra/h7c/h7c > chaos.sql

# a simple check of the chaos process, if the chaos.sql is produced
# without error:
# in postgresql: create an empty database called chaos
# run: psql chaos -q --set ON_ERROR_STOP=on --file=chaos.sql
# the chaos project comes with automated tests which will be fixed
# so that they run (so the test code is broken, expecting all
# the tests to still pass).


# targets mainly used to check everything builds ok
all_exes : $(EXE_FILES)

more_all : all all_exes website website_haddock tests

# generic rules

%.hi : %.o
	@:

%.o : %.lhs
	$(HC) $(HC_OPTS) -c $<

%.o : %.hs
	$(HC) $(HC_OPTS) -c $<

# dependency and rules for exe autogeneration:

src-extra/devel-util/GenerateExeRules : src-extra/devel-util/GenerateExeRules.lhs src-extra/devel-util/GetImports.lhs
	ghc -isrc-extra/devel-util src-extra/devel-util/GenerateExeRules.lhs
exe_depend : src-extra/devel-util/GenerateExeRules Makefile src/Database/HsSqlPpp/Internals/AstInternal.hs
	src-extra/devel-util/GenerateExeRules .exe_rules.mk HC HC_OPTS \
	$(SRC_DIRS) EXES $(EXE_FILES)

depend : src/Database/HsSqlPpp/Internals/AstInternal.hs
	ghc -M $(HC_OPTS) $(SRCS_ROOTS) -dep-makefile .depend.mk

# specific rules for generated file astinternal.hs
# the latest version of uuagc which I know works is 0.9.39.1
# if you get errors like this:
# error: Undefined local variable or field ...
# then try downgrading your version of uuagc (or fix the .ag code!)
src/Database/HsSqlPpp/Internals/AstInternal.hs : $(AG_FILES) src-extra/devel-util/PostprocessUuagc
	uuagc -dcfspwm -P src/Database/HsSqlPpp/Internals/ \
		--lckeywords --doublecolons --genlinepragmas \
		src/Database/HsSqlPpp/Internals/AstInternal.ag
	src-extra/devel-util/PostprocessUuagc

# custom rule for this build exe to avoid loop if uses usual exe rule,
# then have loop where 'make depend' depends on AstInternal.hs, but
# AstInternal.hs depends on this exe, which depends on 'make depend'
# running correctly

src-extra/devel-util/PostprocessUuagc : src-extra/devel-util/UUAGCHaddocks.lhs src-extra/devel-util/UUAGCHaddocks.hi src-extra/devel-util/UUAGCHaddocks.o src-extra/devel-util/PostprocessUuagc.lhs src-extra/devel-util/PostprocessUuagc.hi src-extra/devel-util/PostprocessUuagc.o
	$(HC) $(HC_OPTS) src-extra/devel-util/PostprocessUuagc

src-extra/devel-util/UUAGCHaddocks.o : src-extra/devel-util/UUAGCHaddocks.lhs
src-extra/devel-util/PostprocessUuagc.o : src-extra/devel-util/PostprocessUuagc.lhs
src-extra/devel-util/PostprocessUuagc.o : src-extra/devel-util/UUAGCHaddocks.hi


#-dcfspwm --cycle -O
# rule for the generated file
# src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs
# don't want to automatically keep this up to date, only regenerate it
# manually

regenDefaultTemplate1Catalog : src-extra/devel-util/MakeDefaultTemplate1Catalog
	src-extra/devel-util/MakeDefaultTemplate1Catalog > \
		src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs_new
	mv src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs_new \
		src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs

# not really sure what .PHONY is for, whether it is needed here
# or whether it is needed in other places in the makefile

.PHONY : clean
clean :
	-rm -Rf dist
	find . -iname '*.o' -delete
	find . -iname '*.hi' -delete
	-rm chaos.sql
	-rm $(EXE_FILES)
	-rm -Rf hssqlppp
	-rm src-extra/devel-util/GenerateExeRules

maintainer-clean : clean
	-rm src/Database/HsSqlPpp/Internals/AstInternal.hs


# include the ghc -M dependencies
-include .depend.mk


# stuff to add:
# build the lib using cabal from here
# do stuff with chaos:
#   build the 'compiler' exe only
#   produce the transformed sql
#   load the sql into pg
#   output stuff: typecheck, documentation#
# h7c stuff: needs some thought
# get the chaos sql transformation documentation working again

# want to avoid editing source or the commands to try different things
# in development
# how can have better control over conditionally compiling in different
#   test modules?

# todo: don't write the .o, .hi and exes in the source tree
# todo: transition to not storing astinternal.hs in repo?

# todo: find something better than make

