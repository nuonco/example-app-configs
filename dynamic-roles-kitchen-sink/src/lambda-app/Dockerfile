FROM public.ecr.aws/lambda/nodejs:20

# Copy application files
COPY index.js package.json ./

# Install dependencies (if any)
RUN npm install --production

# Set the Lambda handler
CMD ["index.handler"]
