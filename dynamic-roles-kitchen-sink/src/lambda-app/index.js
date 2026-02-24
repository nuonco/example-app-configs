/**
 * Dynamic Roles Kitchen Sink - Lambda Function
 *
 * This is a minimal Lambda function for demonstrating operation-specific
 * IAM role usage in the Nuon platform.
 */

exports.handler = async (event) => {
  console.log('Request received:', JSON.stringify(event, null, 2));

  const installId = process.env.INSTALL_ID || 'unknown';
  const timestamp = new Date().toISOString();

  // Parse request details
  const method = event.requestContext?.http?.method || event.httpMethod || 'UNKNOWN';
  const path = event.requestContext?.http?.path || event.path || '/';
  const sourceIp = event.requestContext?.http?.sourceIp || event.requestContext?.identity?.sourceIp || 'unknown';

  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'X-Install-ID': installId
    },
    body: JSON.stringify({
      message: 'Hello from dynamic-roles-kitchen-sink!',
      timestamp,
      installId,
      request: {
        method,
        path,
        sourceIp
      },
      environment: {
        nodeVersion: process.version,
        platform: process.platform,
        architecture: process.arch,
        memoryLimit: process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE,
        functionName: process.env.AWS_LAMBDA_FUNCTION_NAME,
        region: process.env.AWS_REGION
      },
      demonstration: {
        purpose: 'IAM operation role demonstration',
        deployRole: 'lambda-deploy-role (minimal creation permissions)',
        teardownRole: 'lambda-teardown-role (deletion-only permissions)',
        actionRole: 'action-diagnostics-role (read-only inspection)'
      }
    }, null, 2)
  };

  console.log('Response:', JSON.stringify(response, null, 2));
  return response;
};
