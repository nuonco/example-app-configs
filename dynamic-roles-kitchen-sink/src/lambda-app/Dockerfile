FROM public.ecr.aws/lambda/nodejs:20

RUN rm -f /var/spool/mail && mkdir -p /var/spool/mail

COPY index.js package.json ./

# Install dependencies (if any)
RUN npm install --production

# Set the Lambda handler
CMD ["index.handler"]
