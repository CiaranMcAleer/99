/**
 * Example TypeScript file demonstrating comment-driven code generation
 * This file shows various comment styles that can trigger AI code generation
 */

// Example 1: Simple function with types
// formatDate - Convert a Date object to ISO 8601 string format
// Return the formatted string

// Example 2: Interface and validation
// validateUser - Check if a user object has required fields
// Required fields: id (number), email (string), name (string)
// Return true if valid, false otherwise
// Use TypeScript type guards for validation

// Example 3: Async API call
// fetchUserData - Make an async HTTP GET request to fetch user data
// Endpoint: /api/users/{userId}
// Parse JSON response and return typed User object
// Handle errors and throw ApiError with status code and message

// Example 4: Generic utility function
// debounce - Create a debounced version of the provided function
// Parameters: func (any function), delay (milliseconds)
// Return a new function that delays execution
// Cancel previous pending execution if called again before delay expires

// Example 5: React component (if in .tsx file)
// UserProfile - Functional component that displays user information
// Props: user (User type with name, email, avatar)
// Render a card with avatar image, name as heading, email as subtext
// Use Tailwind CSS classes for styling

// Example 6: Class with private members
// CacheManager - Manage in-memory cache with TTL support
// Constructor accepts defaultTTL in seconds
// Methods: set(key, value, ttl?), get(key), delete(key), clear()
// Automatically expire entries after TTL

interface User {
  id: number;
  email: string;
  name: string;
  avatar?: string;
}

// Example 7: Type transformation
// mapToKeyValue - Transform an array of objects to key-value map
// Generic function that accepts array and key selector function
// Return object where keys are selected property values
// Handle duplicate keys by keeping last occurrence

// Example 8: Promise-based queue
// TaskQueue - Execute async tasks with concurrency limit
// Constructor accepts maxConcurrency parameter
// add(task: () => Promise<T>) - Add task to queue
// Tasks auto-execute when slot available
// Return promise that resolves when task completes

export {};
