-- Example Lua file demonstrating comment-driven code generation
-- This file shows various comment styles that can trigger AI code generation

-- Example 1: Simple function request
-- calculateSum - Add two numbers and return the result

-- Example 2: More detailed function with parameters
-- validateEmail - Check if a string is a valid email address
-- Parameters: email (string)
-- Returns: boolean (true if valid, false otherwise)
-- Handle edge cases like empty strings and null values

-- Example 3: Database query function
-- FetchCache – Query the events database for records whose `title` or `description` 
-- contain the String <query> and occur within <timeframe>. Return a JSON-serializable 
-- list of event objects with id, title, start_time, end_time.

-- Example 4: Complex logic
-- parseConfiguration - Read a configuration file in JSON format
-- Parse the file and extract the following keys: host, port, ssl_enabled, timeout
-- Return a table with these keys, applying defaults if any are missing
-- Default values: host="localhost", port=8080, ssl_enabled=false, timeout=30

-- Example 5: Inside an existing function
local function processData()
  -- Sort the data array by the 'timestamp' field in descending order
  -- Return the sorted array
end

-- Example 6: Class method style
local MyClass = {}
-- Constructor that initializes a new instance with name and age properties
-- If age is not provided, default to 0

-- Example 7: Error handling
-- safeFileRead - Read a file from the given path
-- Return the file contents as a string
-- If the file doesn't exist or can't be read, return nil and an error message
-- Log any errors using print()

return {}
