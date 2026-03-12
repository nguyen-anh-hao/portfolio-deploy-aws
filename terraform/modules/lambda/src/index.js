/**
 * Placeholder Lambda API handler
 *
 * Replace this with your actual backend logic.
 * This function is in a VPC private subnet — ready to connect to RDS/Redis later.
 *
 * Access via: Lambda Function URL (see terraform output lambda_function_url)
 */

exports.handler = async (event) => {
  const method = event.requestContext?.http?.method || event.httpMethod || "UNKNOWN";
  const path = event.requestContext?.http?.path || event.path || "/";

  // Basic health check
  if (path === "/health") {
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "ok", timestamp: new Date().toISOString() }),
    };
  }

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    },
    body: JSON.stringify({
      message: "API is running",
      method,
      path,
      environment: process.env.ENVIRONMENT,
      timestamp: new Date().toISOString(),
    }),
  };
};
