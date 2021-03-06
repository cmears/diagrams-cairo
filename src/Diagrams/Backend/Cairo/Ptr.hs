{-# LANGUAGE CPP #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Diagrams.Backend.Cairo.Ptr
-- Copyright   :  (c) 2012 Diagrams-cairo team (see LICENSE)
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  diagrams-discuss@googlegroups.com
--
-- Render diagrams to buffers in memory.
--
-----------------------------------------------------------------------------

module Diagrams.Backend.Cairo.Ptr where

import           Data.Word                       (Word8)

import           Diagrams.Backend.Cairo
import           Diagrams.Backend.Cairo.Internal
import           Diagrams.Prelude                (Any, QDiagram, V2, dims2D,
                                                  renderDia)

import           Foreign.Marshal.Alloc           (finalizerFree)
import           Foreign.Marshal.Array           (mallocArray, pokeArray)
import           Foreign.Ptr                     (Ptr, castPtr)

import           Graphics.Rendering.Cairo        (Format (..),
                                                  formatStrideForWidth,
                                                  renderWith,
                                                  withImageSurfaceForData)

#if __GLASGOW_HASKELL__ < 710
import           Control.Applicative             ((<$>))
import           Foreign.ForeignPtr.Safe         (ForeignPtr, newForeignPtr)
#else
import           Foreign.ForeignPtr              (ForeignPtr, newForeignPtr)
#endif

-- | Render a diagram to a new buffer in memory, with the format ARGB32.

renderPtr :: Int -> Int -> Format -> QDiagram Cairo V2 Double Any -> IO (Ptr Word8)
renderPtr w h fmt d = do
  let stride = formatStrideForWidth fmt w
      size   = stride * h
      opt    = CairoOptions
        { _cairoSizeSpec     = fromIntegral <$> dims2D w h
        , _cairoOutputType   = RenderOnly
        , _cairoBypassAdjust = False
        , _cairoFileName     = ""
        }
      (_, r) = renderDia Cairo opt d

  b <- mallocArray size
  pokeArray b (replicate size 0)
  withImageSurfaceForData b fmt w h stride (`renderWith` r)

  return (castPtr b)

-- | Like 'renderPtr' but automatically garbage collected by Haskell.

renderForeignPtr :: Int -> Int -> QDiagram Cairo V2 Double Any -> IO (ForeignPtr Word8)
renderForeignPtr w h d = renderPtr w h FormatARGB32 d >>= newForeignPtr finalizerFree

renderForeignPtrOpaque :: Int -> Int -> QDiagram Cairo V2 Double Any -> IO (ForeignPtr Word8)
renderForeignPtrOpaque w h d = renderPtr w h FormatRGB24 d >>= newForeignPtr finalizerFree
