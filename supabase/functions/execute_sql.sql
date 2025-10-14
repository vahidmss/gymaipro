-- Create the 'execute_sql' function to run SQL queries
-- Note: This function should only be accessible to admins and service roles
CREATE OR REPLACE FUNCTION execute_sql(query text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Run with the privileges of the function creator
SET search_path = public
AS $$
BEGIN
  EXECUTE query;
END;
$$;

-- Grant execute permissions only to service_role and postgres users
REVOKE ALL ON FUNCTION execute_sql(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION execute_sql(text) TO service_role;
GRANT EXECUTE ON FUNCTION execute_sql(text) TO postgres; 