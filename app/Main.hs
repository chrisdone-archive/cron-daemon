{-# LANGUAGE ScopedTypeVariables #-}
-- | Program runner.

module Main where

import Control.Exception
import Control.Monad
import Data.Semigroup ((<>))
import Options.Applicative
import System.Directory
import System.IO
import System.Posix.Signals
import System.Posix.Types
import System.Process
import Text.Read

data Config = Config
  { configProgram :: FilePath
  , configPid :: FilePath
  , configLog :: FilePath
  , configStderr :: FilePath
  , configStdout :: FilePath
  , configEnv :: [(String, String)]
  , configPwd :: FilePath
  , configArgs :: [String]
  , configLogEnv :: Bool
  } deriving (Show)

sample :: Parser Config
sample =
  Config <$>
  strOption (long "program" <> metavar "PROGRAM" <> help "Run this program") <*>
  strOption
    (long "pid" <> metavar "FILEPATH" <>
     help "Write the process ID to this file") <*>
  strOption (long "log" <> metavar "FILEPATH" <> help "Log file") <*>
  strOption (long "stderr" <> metavar "FILEPATH" <> help "Process stderr file") <*>
  strOption (long "stdout" <> metavar "FILEPATH" <> help "Process stdout file") <*>
  many
    (option
       (maybeReader (parseEnv))
       (long "env" <> short 'e' <> metavar "NAME=value" <>
        help "Environment variable")) <*>
  strOption (long "pwd" <> metavar "DIR" <> help "Working directory") <*>
  many
    (strArgument (metavar "ARGUMENT" <> help "Argument for the child process")) <*>
  flag
    False
    True
    (help "Log environment variables in log file (default: false)" <>
     long "debug-log-env")

parseEnv :: String -> Maybe (String, String)
parseEnv =
  \s ->
    case break (== '=') s of
      (name, val)
        | not (null val) && not (null name) -> Just (name, drop 1 val)
        | otherwise -> Nothing

main :: IO ()
main = do
  config <- execParser opts
  start config
  where
    opts =
      info
        (sample <**> helper)
        (fullDesc <> progDesc "Run a program as a daemon with cron" <>
         header "cron-daemon - Run a program as a daemon with cron")

start :: Config -> IO ()
start config = do
  pidFileExists <- doesFileExist (configPid config)
  if pidFileExists
    then do
      pidbytes <- readFile (configPid config)
      case readMaybe pidbytes of
        Just u32 -> do
          catch
            (signalProcess 0 (CPid u32))
            (\(_ :: SomeException) -> do
               logInfo ("Process ID " ++ show u32 ++ " not running.")
               launch)
        Nothing -> logError "Failed to read process ID as a 32-bit integer!"
    else do
      logInfo ("PID file does not exist: " ++ configPid config)
      launch
  where
    logInfo line = appendFile (configLog config) ("INFO: " ++ line ++ "\n")
    logError line = appendFile (configLog config) ("ERROR: " ++ line ++ "\n")
    launch = do
      logInfo ("Launching " ++ configProgram config)
      logInfo ("Arguments: " ++ show (configArgs config))
      when
        (configLogEnv config)
        (logInfo ("Environment: " ++ show (configEnv config)))
      errfile <- openFile (configStderr config) AppendMode
      outfile <- openFile (configStdout config) AppendMode
      (_, _, _, ph) <-
        catch
          (createProcess
             (proc (configProgram config) (configArgs config))
               { env = Just (configEnv config)
               , std_in = NoStream
               , std_out = UseHandle outfile
               , std_err = UseHandle errfile
               , cwd = Just (configPwd config)
               })
          (\(e :: SomeException) ->
             logError "Failed to launch process." >> throw e)
      mpid <- getPid ph
      case mpid of
        Just (CPid pid) -> do
          writeFile (configPid config) (show pid)
          logInfo ("Successfully launched PID: " ++ show pid)
        Nothing -> logError "Failed to get process ID!"
