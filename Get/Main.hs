{-# LANGUAGE DeriveDataTypeable, RecordWildCards #-}
module Main where
 
import System.Console.CmdArgs
import System.Environment (getArgs, withArgs)
import System.Exit
import System.IO
import Control.Monad.Error
import qualified Paths_elm_get as This
import qualified Data.Maybe as Maybe
import Data.Version (showVersion)

import qualified Get.Install  as Install
import qualified Get.Registry as Registry
import qualified Get.Utils    as Utils


data Commands
    = Install { lib :: String, version :: Maybe String }
    | Update { libs_ :: [String] }
    | Publish { repo :: Maybe String }
      deriving (Data, Typeable, Show, Eq)

commands =
    [ Install { lib = def &= argPos 0 &= typ "LIBRARY"
              , version = Nothing &= args &= typ "VERSION"
              }
      &= help "Install libraries in the local project."
      &= details [ "Examples:"
                 , "  elm-get install            # install everything needed by build.json"
                 , "  elm-get install tom/Array  # install a specific github repo" ]
    , Update { libs_ = [] &= args &= typ "LIBRARY" }
      &= help "Check for updates to any local libraries, ask to upgrade."
      &= details [ "Examples:"
                 , "  elm-get update             # check for updates to local libraries"
                 , "  elm-get update tom/Array   # update from a specific github repo" ]
    , Publish { repo = Nothing &= args &= typ "REPO" }
      &= help "Publish project to the central repository."
      &= details []
    ]

myModes :: Mode (CmdArgs Commands)
myModes = cmdArgsMode $ modes commands
    &= versionArg [explicit, name "version", name "v", summary info]
    &= summary (info ++ ", (c) Evan Czaplicki 2013")
    &= help "install, update, and publish elm libraries"
    &= helpArg [explicit, name "help", name "h"]
    &= program "elm-get"
 
info = "elm-get " ++ showVersion This.version

main :: IO ()
main = do
  args <- getArgs
  -- If the user did not specify any arguments, pretend as "--help" was given
  opts <- (if null args then withArgs ["--help"] else id) $ cmdArgsRun myModes
  result <- runErrorT (handle opts)
  case result of
    Right _ -> return ()
    Left err -> hPutStr stderr ("Error: " ++ err ++ newline) >> exitFailure
        where newline = if last err == '\n' then "" else "\n"

handle options =
    case options of
      Install { lib=library, version=maybeVersion } ->
          do version <- Maybe.maybe (Registry.latest library) return maybeVersion
             (user, project) <- Utils.getUserAndProject library
             Install.install user project version
      _ -> liftIO $ print options
