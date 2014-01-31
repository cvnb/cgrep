--
-- Copyright (c) 2013 Bonelli Nicola <bonelli@antifork.org>
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--

{-# LANGUAGE FlexibleContexts #-}

module CGrep.Strategy.Regex (search) where

import qualified Data.ByteString.Char8 as C

import Text.Regex.Posix
import Data.Array

import CGrep.Common
import CGrep.Output
import CGrep.Filter
import CGrep.Lang

import Options
import Debug


search :: CgrepFunction
search opt ps f = do

    let filename = getFileName f

    text <- getText f

    -- transform text

    let text' = expandMultiline opt . ignoreCase opt $ text

    -- quick search...

    let found = quickSearch opt ps text'

    -- put banners...

    putStrLevel1 (debug opt) $ "strategy  : running regex search on " ++ filename ++ "..."

    if maybe False not found
        then return $ mkOutput opt filename text []
        else do

            let text'' = contextFilter (getLang opt filename) (mkContextFilter opt) text'

            -- search for matching tokens

            let tokens = map (\(str, (off,_)) -> (off, C.unpack str) ) $  concatMap elems $ ps >>= (\p -> elems (getAllTextMatches $ text'' =~ p :: (Array Int) (MatchText Text8)) )

            putStrLevel2 (debug opt) $ "tokens    : " ++ show tokens
            putStrLevel3 (debug opt) $ "---\n" ++ C.unpack text'' ++ "\n---"

            return $ mkOutput opt filename text tokens

