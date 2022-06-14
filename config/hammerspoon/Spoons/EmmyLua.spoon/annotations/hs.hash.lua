--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Various hashing algorithms
---@class hs.hash
local M = {}
hs.hash = M

-- Calculates an HMAC using a key and an MD5 hash
--
-- Parameters:
--  * key - A string containing a secret key to use
--  * data - A string containing the data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.hmacMD5(key, data, ...) end

-- Calculates an HMAC using a key and a SHA1 hash
--
-- Parameters:
--  * key - A string containing a secret key to use
--  * data - A string containing the data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.hmacSHA1(key, data, ...) end

-- Calculates an HMAC using a key and a SHA256 hash
--
-- Parameters:
--  * key - A string containing a secret key to use
--  * data - A string containing the data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.hmacSHA256(key, data, ...) end

-- Calculates an HMAC using a key and a SHA512 hash
--
-- Parameters:
--  * key - A string containing a secret key to use
--  * data - A string containing the data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.hmacSHA512(key, data, ...) end

-- Calculates an MD5 hash
--
-- Parameters:
--  * data - A string containing some data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.MD5(data, ...) end

-- Calculates an SHA1 hash
--
-- Parameters:
--  * data - A string containing some data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.SHA1(data, ...) end

-- Calculates an SHA256 hash
--
-- Parameters:
--  * data - A string containing some data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.SHA256(data, ...) end

-- Calculates an SHA512 hash
--
-- Parameters:
--  * data - A string containing some data to hash
--
-- Returns:
--  * A string containing the hash of the supplied data
---@return string
function M.SHA512(data, ...) end

