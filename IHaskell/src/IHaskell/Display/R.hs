-- |
-- Module: IHaskell.Display.R
-- Copyright: 2015 (C) Tweag I/O
--
--
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
module IHaskell.Display.R
  ( initializeEmbeddedR
  , Config(..)
  , defaultConfig
  , h
  , hDisp
  , hPlot
  , Language.R.Instance.runRegion
  ) where

import           H.Prelude.Interactive as H -- we use provide instances to IO Monad
import           Language.R.QQ
import           Language.R.Instance

import           IHaskell.Display
import           IHaskell.Display.Blaze () -- to confirm it's installed
import qualified Text.Blaze.Html5 as BH
import qualified Text.Blaze.Html5.Attributes as BH

import           Control.Applicative
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as Char
import qualified Data.ByteString.Base64 as Base64
import           Data.Monoid
import           Language.Haskell.TH.Quote
import           System.Directory

hDisp :: QuasiQuoter
hDisp = QuasiQuoter { quoteExp = \s -> [| do result <- $(quoteExp r s)
                                             H.print result |] }

h :: QuasiQuoter
h = r

hPlot :: QuasiQuoter
hPlot = QuasiQuoter { quoteExp = \s ->
    [| do idx <- findMaxIndex 0
          let fname = mkName idx
          _ <- [r| png(filename=fname_hs, width=480, height=480, bg="white"); |]
          _ <- $(quoteExp r s)
          _ <- [r| dev.off() |]
          encoded <- Base64.encode <$> B.readFile fname
          display $ BH.img BH.! BH.src
                                 (BH.unsafeByteStringValue
                                    (Char.pack "data:image/png;base64," <> encoded))
     |] }

mkName :: Int -> FilePath
mkName i = "Rplots/auto" <> Prelude.show i <> ".png"

findMaxIndex :: Int -> IO Int
findMaxIndex i = do
  b <- doesFileExist $ mkName i
  if b then findMaxIndex (i+1)
       else return i

-- | Initialize Embedded R process and configure R
initializeEmbeddedR :: Config -> IO ()
initializeEmbeddedR config = do
  H.initialize config
  -- Configure plots output
  createDirectoryIfMissing False "Rplots"
